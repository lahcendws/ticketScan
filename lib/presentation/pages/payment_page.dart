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
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('subscription') ?? 'Paiement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan == 'yearly' ? 'Abonnement Annuel' : 'Abonnement Mensuel',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text('Accès illimité à toutes les fonctions'),
                      ],
                    ),
                    Text(
                      widget.price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Informations de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Numéro de carte
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Numéro de carte',
                  hintText: '0000 0000 0000 0000',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.length < 16) ? 'Numéro invalide' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  // Expiration
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) => (value == null || !value.contains('/')) ? 'Invalide' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CVC
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'CVC',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 3) ? 'Invalide' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nom sur la carte',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Payer ${widget.price}'),
                ),
              ),
              
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Paiement sécurisé par SSL', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final success = await subscriptionService.upgradeToPremium(widget.plan);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du paiement. Veuillez réessayer.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paiement réussi !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vous avez maintenant accès à toutes les fonctionnalités Premium.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pop(); // Fermer la page de paiement
                Navigator.of(context).pop(); // Fermer la page Premium
              },
              child: const Text('Commencer à utiliser'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
