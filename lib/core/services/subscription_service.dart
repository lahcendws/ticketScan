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
  final int _freeLimit = 3;
  
  InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ??= InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  int get freeLimit => _freeLimit;

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
          onError: (e) => debugPrint('Erreur IAP Stream: $e')
        );
      }

      SupabaseService.authStateChanges.listen((event) {
        if (event.session != null) refreshSubscriptionStatus();
        else { _isPremium = false; notifyListeners(); }
      });
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Erreur lors de la restauration: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await refreshSubscriptionStatus();
        }
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

  Future<void> refreshSubscriptionStatus() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client.from('profiles').select('is_premium').eq('id', userId).maybeSingle();
      if (response != null) {
        _isPremium = response['is_premium'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur rafraîchissement profil: $e');
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
