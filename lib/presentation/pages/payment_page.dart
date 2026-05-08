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
    Provider.of<SubscriptionService>(context, listen: false).removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    final subService = Provider.of<SubscriptionService>(context, listen: false);
    if (subService.isPremium && mounted) {
      // Si l'utilisateur est passé Premium, on ferme tout et on retourne à l'accueil
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Félicitations ! Vous êtes maintenant Premium 🚀'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.get('upgrade_premium') ?? 'Passer au Premium'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.security_rounded,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            Text(
              loc?.get('premium_plan') ?? 'Abonnement Premium',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan == 'yearly' 
                              ? (loc?.get('yearly') ?? 'Annuel') 
                              : (loc?.get('monthly') ?? 'Mensuel'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc?.get('premium_unlock_msg') ?? 'Accès illimité à toutes les fonctions',
                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.price,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Le paiement sera traité de manière sécurisée par Google Play. Vous pouvez annuler à tout moment dans vos paramètres Google Play.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processNativePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Payer via Google Play',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _processNativePayment() async {
    setState(() => _isProcessing = true);

    try {
      final subService = Provider.of<SubscriptionService>(context, listen: false);
      final productId = widget.plan == 'yearly' ? 'premium_yearly' : 'premium_monthly';
      
      final success = await subService.upgradeToPremium(productId);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le service Google Play n\'est pas disponible pour le moment.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
