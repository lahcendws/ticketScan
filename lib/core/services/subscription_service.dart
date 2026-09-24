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
    if (isTest) {
      debugPrint('SubscriptionService: Initializing in TEST mode');
      // Enable debug logging for in_app_purchase in test mode
      // await _iap.enableDebugLogging();  // Debugging enabled via platform tools in test mode
      // For StoreKit testing in sandbox/TestFlight, we rely on the build configuration
    } else {
      debugPrint('SubscriptionService: Initializing in PRODUCTION mode');
    }

    if (!isTest) {
      await refreshSubscriptionStatus();

      final bool available = await _iap.isAvailable();
      debugPrint('SubscriptionService: IAP available: $available');

      if (available) {
        _subscription = _iap.purchaseStream.listen(
          _listenToPurchaseUpdated,
          onDone: () {
            debugPrint('SubscriptionService: IAP purchase stream done');
            _subscription?.cancel();
          },
          onError: (e) => debugPrint('SubscriptionService: Erreur IAP Stream: $e'),
        );

        // Get available products for diagnostic purposes
        try {
          final ProductDetailsResponse productResponse = await _iap.queryProductDetails(<String>{'premium_yearly', 'premium_monthly'});
          debugPrint('SubscriptionService: Available products: ${productResponse.productDetails.length}');
          for (final product in productResponse.productDetails) {
            debugPrint('SubscriptionService: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}');
          }
          if (productResponse.notFoundIDs.isNotEmpty) {
            debugPrint('SubscriptionService: Product IDs not found: ${productResponse.notFoundIDs}');
          }
        } catch (e) {
          debugPrint('SubscriptionService: Error querying product details: $e');
        }
      }

      SupabaseService.authStateChanges.listen((event) {
        if (event.session != null) {
          debugPrint('SubscriptionService: User session changed, refreshing subscription status');
          refreshSubscriptionStatus();
        } else {
          debugPrint('SubscriptionService: User signed out');
          _isPremium = false;
          notifyListeners();
        }
      });
    }
  }

  Future<void> restorePurchases() async {
    debugPrint('SubscriptionService: Attempting to restore purchases');
    try {
      await _iap.restorePurchases();
      debugPrint('SubscriptionService: Purchase restore initiated');
    } catch (e) {
      debugPrint('SubscriptionService: Erreur lors de la restauration: $e');
    }
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    debugPrint('SubscriptionService: Purchase update received, count: ${purchaseDetailsList.length}');
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint('SubscriptionService: Processing purchase - ID: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint('SubscriptionService: Verifying purchase - ${purchaseDetails.productID}');
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          debugPrint('SubscriptionService: Purchase verified successfully - ${purchaseDetails.productID}');
          await refreshSubscriptionStatus();
        } else {
          debugPrint('SubscriptionService: Purchase verification failed - ${purchaseDetails.productID}');
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('SubscriptionService: Completing purchase - ${purchaseDetails.productID}');
        await _iap.completePurchase(purchaseDetails);
        debugPrint('SubscriptionService: Purchase completed - ${purchaseDetails.productID}');
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('SubscriptionService: Starting server verification for ${purchaseDetails.productID}');
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-purchase',
        body: {
          'receipt': purchaseDetails.verificationData.serverVerificationData,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'productId': purchaseDetails.productID,
        },
      );
      debugPrint('SubscriptionService: Server verification response status: ${response.status} for ${purchaseDetails.productID}');
      return response.status == 200;
    } catch (e) {
      debugPrint('SubscriptionService: Erreur verification serveur: $e');
      return false;
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('SubscriptionService: No user ID available for subscription refresh');
      return;
    }

    debugPrint('SubscriptionService: Refreshing subscription status for user: $userId');
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_premium')
          .eq('id', userId)
          .maybeSingle();
      if (response != null) {
        final isPremium = response['is_premium'] ?? false;
        if (_isPremium != isPremium) {
          debugPrint('SubscriptionService: Subscription status changed from $_isPremium to $isPremium');
          _isPremium = isPremium;
          notifyListeners();
        } else {
          debugPrint('SubscriptionService: Subscription status unchanged: $_isPremium');
        }
      } else {
        debugPrint('SubscriptionService: No profile found for user: $userId');
      }
    } catch (e) {
      debugPrint('SubscriptionService: Erreur rafraîchissement profil: $e');
    }
  }

  Future<bool> upgradeToPremium(String planId) async {
    debugPrint('SubscriptionService: Attempting to upgrade to premium with planId: $planId');
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('SubscriptionService: IAP not available for upgrade');
      return false;
    }

    debugPrint('SubscriptionService: Querying product details for planId: $planId');
    final Set<String> kIds = <String>{planId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );

    if (response.productDetails.isEmpty) {
      debugPrint('SubscriptionService: Product details not found for planId: $planId');
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('SubscriptionService: Not found IDs: ${response.notFoundIDs}');
      }
      return false;
    }

    final productDetails = response.productDetails.first;
    debugPrint('SubscriptionService: Found product - ID: ${productDetails.id}, Title: ${productDetails.title}');

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      debugPrint('SubscriptionService: Initiating purchase for ${productDetails.id}');
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('SubscriptionService: Purchase initiated successfully: $result');
      return result;
    } catch (e) {
      debugPrint('SubscriptionService: Error during purchase: $e');
      return false;
    }
  }
}
