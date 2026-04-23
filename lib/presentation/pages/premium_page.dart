import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import 'payment_page.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.get('upgrade_premium') ?? 'Premium'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              loc?.get('premium_plan') ?? 'TicketScan Premium',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              loc?.get('premium_unlock_msg') ?? 'Unlock the full power',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildFeatureRow(context, Icons.check_circle, loc?.get('unlimited_scans') ?? 'Unlimited scans'),
            _buildFeatureRow(context, Icons.check_circle, loc?.get('cloud_sync') ?? 'Cloud Sync'),
            _buildFeatureRow(context, Icons.check_circle, loc?.get('auto_categorization') ?? 'AI Categorization'),
            _buildFeatureRow(context, Icons.check_circle, loc?.get('premium_support') ?? 'Priority Support'),
            const SizedBox(height: 48),
            
            _buildPlanCard(
              context,
              title: loc?.get('monthly') ?? 'Monthly',
              price: '2,99 €',
              subtitle: loc?.get('per_month') ?? '/ mois',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => PaymentPage(plan: 'monthly', price: '2,99 €')));
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildPlanCard(
              context,
              title: loc?.get('yearly') ?? 'Yearly',
              price: '29,99 €',
              subtitle: loc?.get('per_year') ?? '/ an',
              isBestValue: true,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => PaymentPage(plan: 'yearly', price: '29,99 €')));
              },
            ),
            
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc?.get('later') ?? 'Later', style: const TextStyle(color: Colors.grey)),
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
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, {required String title, required String price, required String subtitle, required VoidCallback onTap, bool isBestValue = false}) {
    final loc = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isBestValue ? Theme.of(context).primaryColor.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isBestValue ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBestValue) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(8)), child: Text(loc?.get('best_value') ?? 'Best Value', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey))]),
          ],
        ),
      ),
    );
  }
}
