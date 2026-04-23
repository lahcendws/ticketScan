import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'supabase_service.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isPremium = false;
  int _scansThisMonth = 0;
  final int _freeLimit = 10;
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool get isPremium => _isPremium;
  int get scansThisMonth => _scansThisMonth;
  int get freeLimit => _freeLimit;
  bool get canScan => _isPremium || _scansThisMonth < _freeLimit;

  Future<void> init() async {
    await refreshSubscriptionStatus();

    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () => _subscription.cancel(), onError: (e) => debugPrint('Erreur IAP: $e'));

    SupabaseService.authStateChanges.listen((event) {
      if (event.session != null) refreshSubscriptionStatus();
      else { _isPremium = false; _scansThisMonth = 0; notifyListeners(); }
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // VÉRIFICATION RÉELLE AVEC LA EDGE FUNCTION
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _updatePremiumStatusInDatabase(true);
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-purchase',
        body: {
          'receipt': purchaseDetails.verificationData.serverVerificationData,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'productId': purchaseDetails.productID,
        },
      );

      return response.status == 200;
    } catch (e) {
      debugPrint('Erreur verification serveur: $e');
      return false;
    }
  }

  Future<void> _updatePremiumStatusInDatabase(bool isPremium) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client.from('profiles').update({'is_premium': isPremium}).eq('id', userId);
    _isPremium = isPremium;
    notifyListeners();
  }

  Future<void> refreshSubscriptionStatus() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client.from('profiles').select('is_premium, scans_this_month').eq('id', userId).maybeSingle();
      if (response != null) {
        _isPremium = response['is_premium'] ?? false;
        _scansThisMonth = response['scans_this_month'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing status: $e');
    }
  }

  Future<void> incrementScanCount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    _scansThisMonth++;
    await Supabase.instance.client.from('profiles').update({'scans_this_month': _scansThisMonth}).eq('id', userId);
    notifyListeners();
  }

  Future<bool> upgradeToPremium(String planId) async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return false;

    final Set<String> kIds = <String>{planId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

    if (response.productDetails.isEmpty) return false;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
