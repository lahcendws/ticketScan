import 'dart:async';
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
  
  // In-App Purchase
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;

  bool get isPremium => _isPremium;
  int get scansThisMonth => _scansThisMonth;
  int get freeLimit => _freeLimit;
  int get remainingScans => _freeLimit - _scansThisMonth;
  bool get canScan => _isPremium || _scansThisMonth < _freeLimit;

  Future<void> init() async {
    await refreshSubscriptionStatus();
    
    // Initialisation IAP
    _isAvailable = await _inAppPurchase.isAvailable();
    
    // Écouter les mises à jour des achats
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('Erreur achat: $error');
    });

    // Écouter les changements d'auth
    SupabaseService.authStateChanges.listen((event) {
      if (event.session != null) {
        refreshSubscriptionStatus();
      } else {
        _isPremium = false;
        _scansThisMonth = 0;
        notifyListeners();
      }
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Afficher un loader si nécessaire
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Erreur achat: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // TODO: ICI - Envoyer le reçu (purchaseDetails.verificationData.serverVerificationData)
          // à une Supabase Edge Function pour vérification côté serveur.
          
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
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Pour le moment, on simule la validation serveur
    // En production, appelez une Supabase Edge Function ici
    return true;
  }

  Future<void> _updatePremiumStatusInDatabase(bool isPremium) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'is_premium': isPremium,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
      
      _isPremium = isPremium;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur mise à jour base de données premium: $e');
    }
  }

  Future<void> refreshSubscriptionStatus() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_premium, scans_this_month')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _isPremium = response['is_premium'] ?? false;
        _scansThisMonth = response['scans_this_month'] ?? 0;
      } else {
        await _createInitialProfile(user.id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la récupération du statut d\'abonnement: $e');
    }
  }

  Future<void> _createInitialProfile(String userId) async {
    try {
      await Supabase.instance.client.from('profiles').insert({
        'id': userId,
        'is_premium': false,
        'scans_this_month': 0,
      });
      _isPremium = false;
      _scansThisMonth = 0;
    } catch (e) {
      debugPrint('Erreur création profil initial: $e');
    }
  }

  Future<void> incrementScanCount() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      _scansThisMonth++;
      await Supabase.instance.client
          .from('profiles')
          .update({'scans_this_month': _scansThisMonth})
          .eq('id', user.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'incrémentation du compteur de scans: $e');
    }
  }

  // Cette méthode sera modifiée pour lancer le flux Google Play
  Future<bool> upgradeToPremium(String plan) async {
    // simulation pour le moment
    debugPrint('Démarrage achat pour le plan: $plan');
    
    // Code futur pour Google Play:
    // final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({planId});
    // final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    // _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    
    // Simulation
    await Future.delayed(const Duration(seconds: 2));
    await _updatePremiumStatusInDatabase(true);
    return true;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
