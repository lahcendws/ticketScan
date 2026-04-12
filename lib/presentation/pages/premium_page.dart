import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/app_localizations.dart';
import 'payment_page.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('upgrade_premium') ?? 'Premium'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Text(
              localizations?.get('premium_plan') ?? 'TicketScan Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Débloquez toute la puissance de TicketScan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(context, Icons.check_circle, localizations?.get('unlimited_scans') ?? 'Scans illimités'),
            _buildFeatureRow(context, Icons.check_circle, localizations?.get('cloud_sync') ?? 'Synchronisation Cloud'),
            _buildFeatureRow(context, Icons.check_circle, localizations?.get('auto_categorization') ?? 'Catégorisation auto'),
            _buildFeatureRow(context, Icons.check_circle, localizations?.get('premium_support') ?? 'Support Prioritaire'),
            const SizedBox(height: 48),
            
            // Option Mensuelle
            _buildPlanCard(
              context,
              title: localizations?.get('monthly') ?? 'Mensuel',
              price: '4,99 €',
              subtitle: '/ mois',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentPage(plan: 'monthly', price: '4,99 €'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Option Annuelle
            _buildPlanCard(
              context,
              title: localizations?.get('yearly') ?? 'Annuel',
              price: '29,99 €',
              subtitle: '/ an',
              isBestValue: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentPage(plan: 'yearly', price: '29,99 €'),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations?.get('cancel') ?? 'Plus tard',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isBestValue 
              ? Theme.of(context).primaryColor.withOpacity(0.05) 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBestValue ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBestValue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        localizations?.get('best_value') ?? 'Meilleure Offre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
