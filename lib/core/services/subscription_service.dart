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
  String? _subscriptionType; // premium_monthly or premium_yearly
  DateTime? _subscriptionExpiresAt;
  final int _freeLimit = 3;
  Timer? _subscriptionRefreshTimer;

  InAppPurchase? _iapInstance;
  InAppPurchase get _iap => _iapInstance ??= InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  String? get subscriptionType => _subscriptionType;
  DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;
  int get freeLimit => _freeLimit;

  /// Returns days remaining until expiry, or null if no active subscription.
  int? get daysRemaining {
    if (_subscriptionExpiresAt == null) return null;
    final now = DateTime.now().toUtc();
    // Subscription is only active if expires_at is strictly in the future
    // (matches the logic in the database refresh_premium function)
    if (!_subscriptionExpiresAt!.isAfter(now)) return 0;
    return _subscriptionExpiresAt!.difference(now).inDays;
  }

  /// True if the subscription has expired (based on expiration date, independent of
  /// the is_premium flag which may be delayed due to sync intervals).
  bool get isSubscriptionExpired {
    if (_subscriptionExpiresAt == null) return false;
    return !_subscriptionExpiresAt!.isAfter(DateTime.now().toUtc());
  }

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
      _startSubscriptionRefreshTimer();

      final bool available = await _iap.isAvailable();
      debugPrint('SubscriptionService: IAP available: $available');

      if (available) {
        _subscription = _iap.purchaseStream.listen(
          _listenToPurchaseUpdated,
          onDone: () {
            debugPrint('SubscriptionService: IAP purchase stream done');
            _subscription?.cancel();
          },
          onError: (e) =>
              debugPrint('SubscriptionService: Erreur IAP Stream: $e'),
        );

        // Get available products for diagnostic purposes
        try {
          final ProductDetailsResponse productResponse = await _iap
              .queryProductDetails(<String>{
                'premium_yearly',
                'premium_monthly',
              });
          debugPrint(
            'SubscriptionService: Available products: ${productResponse.productDetails.length}',
          );
          for (final product in productResponse.productDetails) {
            debugPrint(
              'SubscriptionService: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}',
            );
          }
          if (productResponse.notFoundIDs.isNotEmpty) {
            debugPrint(
              'SubscriptionService: Product IDs not found: ${productResponse.notFoundIDs}',
            );
          }
        } catch (e) {
          debugPrint('SubscriptionService: Error querying product details: $e');
        }
      }

      SupabaseService.authStateChanges.listen((event) {
        if (event.session != null) {
          debugPrint(
            'SubscriptionService: User session changed, refreshing subscription status',
          );
          refreshSubscriptionStatus();
          // Restart timer when user signs in
          _startSubscriptionRefreshTimer();
        } else {
          debugPrint('SubscriptionService: User signed out');
          _isPremium = false;
          _subscriptionType = null;
          _subscriptionExpiresAt = null;
          _stopSubscriptionRefreshTimer();
          notifyListeners();
        }
      });
    }
  }

  void _startSubscriptionRefreshTimer() {
    _stopSubscriptionRefreshTimer(); // Cancel any existing timer
    _subscriptionRefreshTimer = Timer.periodic(
      const Duration(hours: 6),
      (timer) => refreshSubscriptionStatus(),
    );
  }

  void _stopSubscriptionRefreshTimer() {
    _subscriptionRefreshTimer?.cancel();
    _subscriptionRefreshTimer = null;
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
    debugPrint(
      'SubscriptionService: Purchase update received, count: ${purchaseDetailsList.length}',
    );
    for (var purchaseDetails in purchaseDetailsList) {
      debugPrint(
        'SubscriptionService: Processing purchase - ID: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}',
      );

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        debugPrint(
          'SubscriptionService: Verifying purchase - ${purchaseDetails.productID}',
        );
        bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          debugPrint(
            'SubscriptionService: Purchase verified successfully - ${purchaseDetails.productID}',
          );
          await refreshSubscriptionStatus();
        } else {
          debugPrint(
            'SubscriptionService: Purchase verification failed - ${purchaseDetails.productID}',
          );
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint(
          'SubscriptionService: Completing purchase - ${purchaseDetails.productID}',
        );
        await _iap.completePurchase(purchaseDetails);
        debugPrint(
          'SubscriptionService: Purchase completed - ${purchaseDetails.productID}',
        );
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    debugPrint(
      'SubscriptionService: Starting server verification for ${purchaseDetails.productID}',
    );
    try {
      final Map<String, dynamic> body = {
        'productId': purchaseDetails.productID,
      };
      if (Platform.isIOS) {
        body['signedTransaction'] =
            purchaseDetails.verificationData.serverVerificationData;
        body['platform'] = 'ios';
      } else {
        body['receipt'] =
            purchaseDetails.verificationData.serverVerificationData;
        body['platform'] = 'android';
      }
      final response = await Supabase.instance.client.functions.invoke(
        'verify-purchase',
        body: body,
      );
      debugPrint(
        'SubscriptionService: Server verification response status: ${response.status} for ${purchaseDetails.productID}',
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('SubscriptionService: Erreur verification serveur: $e');
      return false;
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint(
        'SubscriptionService: No user ID available for subscription refresh',
      );
      return;
    }

    debugPrint(
      'SubscriptionService: Refreshing subscription status for user: $userId',
    );
    try {
      // Fetch premium status from profiles table
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_premium')
          .eq('id', userId)
          .maybeSingle();

      bool isPremium = false;
      String? subscriptionType;
      DateTime? expiresAt;

      if (response != null) {
        isPremium = response['is_premium'] as bool? ?? false;

        // If premium, also fetch subscription details for type and expiration
        if (isPremium) {
          final subResponse = await Supabase.instance.client
              .from('subscriptions')
              .select('product_id,expires_at')
              .eq('user_id', userId)
              .inFilter('status', ['active', 'grace_period'])
              .order('expires_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (subResponse != null) {
            subscriptionType = subResponse['product_id'] as String?;
            final expiresStr = subResponse['expires_at'] as String?;
            if (expiresStr != null) {
              expiresAt = DateTime.parse(expiresStr).toUtc();
            }
          }
        }
      }

      // Update values and notify if changed
      if (_isPremium != isPremium ||
          _subscriptionType != subscriptionType ||
          _subscriptionExpiresAt != expiresAt) {
        debugPrint(
          'SubscriptionService: Status changed - premium: $_isPremium -> $isPremium, type: $_subscriptionType -> $subscriptionType, expires: $_subscriptionExpiresAt -> $expiresAt',
        );
        _isPremium = isPremium;
        _subscriptionType = subscriptionType;
        _subscriptionExpiresAt = expiresAt;
        notifyListeners();
      } else {
        // Still update the values to ensure we have the latest data
        _isPremium = isPremium;
        _subscriptionType = subscriptionType;
        _subscriptionExpiresAt = expiresAt;
        debugPrint(
          'SubscriptionService: Subscription status unchanged: $_isPremium',
        );
      }
    } catch (e) {
      debugPrint('SubscriptionService: Erreur rafraîchissement profil: $e');
    }
  }

  Future<bool> upgradeToPremium(String planId) async {
    debugPrint(
      'SubscriptionService: Attempting to upgrade to premium with planId: $planId',
    );
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('SubscriptionService: IAP not available for upgrade');
      return false;
    }

    debugPrint(
      'SubscriptionService: Querying product details for planId: $planId',
    );
    final Set<String> kIds = <String>{planId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      kIds,
    );

    if (response.productDetails.isEmpty) {
      debugPrint(
        'SubscriptionService: Product details not found for planId: $planId',
      );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'SubscriptionService: Not found IDs: ${response.notFoundIDs}',
        );
      }
      return false;
    }

    final productDetails = response.productDetails.first;
    debugPrint(
      'SubscriptionService: Found product - ID: ${productDetails.id}, Title: ${productDetails.title}',
    );

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      debugPrint(
        'SubscriptionService: Initiating purchase for ${productDetails.id}',
      );
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint(
        'SubscriptionService: Purchase initiated successfully: $result',
      );
      return result;
    } catch (e) {
      debugPrint('SubscriptionService: Error during purchase: $e');
      return false;
    }
  }
}
