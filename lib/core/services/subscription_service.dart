import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'supabase_service.dart';
import '../../data/models/ticket_model.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  
  SubscriptionService.internal();
  SubscriptionService._internal();

  bool _isPremium = false;
  int _scansThisMonth = 0;
  final int _freeLimit = 3;
  
  // Instance gérée par getter pour éviter l'initialisation immédiate lors des tests
  InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ??= InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  int get scansThisMonth => _scansThisMonth;
  int get freeLimit => _freeLimit;

  // RÈGLE STRICTE : Compte le nombre total de tickets
  bool canScan(List<TicketModel> allTickets) {
    if (_isPremium) return true;
    return allTickets.length < _freeLimit;
  }

  Future<void> init({bool isTest = false}) async {
    if (!isTest) {
      await refreshSubscriptionStatus();
      
      final bool available = await _iap.isAvailable();
      if (available) {
        _subscription = _iap.purchaseStream.listen(
          _listenToPurchaseUpdated, 
          onDone: () => _subscription?.cancel(), 
          onError: (e) => debugPrint('Erreur IAP: $e')
        );
      }

      SupabaseService.authStateChanges.listen((event) {
        if (event.session != null) refreshSubscriptionStatus();
        else { _isPremium = false; _scansThisMonth = 0; notifyListeners(); }
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) await _updatePremiumStatusInDatabase(true);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
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

  Future<bool> upgradeToPremium(String planId) async {
    final bool available = await _iap.isAvailable();
    if (!available) return false;

    final Set<String> kIds = <String>{planId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

    if (response.productDetails.isEmpty) return false;

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
