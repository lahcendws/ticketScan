import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/app_localizations.dart';

class PaymentPage extends StatefulWidget {
  final String plan;
  final String price;

  const PaymentPage({super.key, required this.plan, required this.price});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color _primaryColor = Color(0xFF4F73FB);
  static const Color _darkTextColor = Color(0xFF1A1C1E);
  static const Color _lightBlue = Color(0xFFF5F7FF);

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de statut Premium pour fermer la page en cas de succès
    final subService = Provider.of<SubscriptionService>(context, listen: false);
    subService.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    // Très important : retirer l'écouteur pour éviter les fuites mémoire
    Provider.of<SubscriptionService>(
      context,
      listen: false,
    ).removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  bool get _isYearly => widget.plan == 'yearly';

  void _onSubscriptionChanged() {
    final subService = Provider.of<SubscriptionService>(context, listen: false);
    if (subService.isPremium && mounted) {
      // Si l'utilisateur est passé Premium, on ferme tout et on retourne à l'accueil
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.get('premium_activated') ??
                'Félicitations ! Vous êtes maintenant Premium 🚀',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isYearly = _isYearly;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          loc?.get('upgrade_premium') ?? 'Passer au Premium',
          style: const TextStyle(
            color: _darkTextColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                isYearly
                    ? (loc?.get('premium_yearly_detail') ?? 'Abonnement annuel')
                    : (loc?.get('premium_monthly_detail') ??
                          'Abonnement mensuel'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _darkTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc?.get('premium_unlock_msg') ??
                    'Accès illimité à toutes les fonctions',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_motion_rounded,
                            color: _primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isYearly
                                    ? (loc?.get('yearly') ?? 'Annuel')
                                    : (loc?.get('monthly') ?? 'Mensuel'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _darkTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc?.get('manage_unlimited') ??
                                    'Gérez tous vos tickets sans limite',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.price,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isYearly)
                    Positioned(
                      top: -12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          loc?.get('best_value_badge') ?? 'Meilleure valeur',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                Platform.isAndroid
                    ? loc?.get('payment_secure_note') ??
                        'Le paiement sera traité de manière sécurisée par Google Play. Vous pouvez annuler à tout moment dans vos paramètres Google Play.'
                    : loc?.get('payment_secure_note_ios') ??
                        'Le paiement sera traité de manière sécurisée par l\'App Store. Vous pouvez annuler à tout moment dans vos réglages.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processNativePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          Platform.isAndroid
                              ? (loc?.get('pay_google_play') ?? 'Payer via Google Play')
                              : (loc?.get('pay_app_store') ?? 'Payer via l\'App Store'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processNativePayment() async {
    setState(() => _isProcessing = true);

    try {
      final subService = Provider.of<SubscriptionService>(
        context,
        listen: false,
      );
      final productId = _isYearly ? 'premium_yearly' : 'premium_monthly';

      final success = await subService.upgradeToPremium(productId);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.get('play_play_unavailable') ??
                  'Le service Google Play n\'est pas disponible pour le moment.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
