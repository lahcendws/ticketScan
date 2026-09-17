import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import 'premium_page.dart';

class ProfilPremiumPage extends StatelessWidget {
  const ProfilPremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context);
    final user = SupabaseService.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heading = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: heading,
        elevation: 0,
        title: Text(
          loc?.get('premium_title') ?? 'Profil Premium',
          style: TextStyle(fontWeight: FontWeight.w800, color: heading),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(context, sub, loc, user?.email ?? 'Utilisateur'),
            const SizedBox(height: 32),
            Text(
              loc?.get('premium_features_list_title') ??
                  'Vos avantages Premium',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildFeaturesGrid(context, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    SubscriptionService sub,
    AppLocalizations? loc,
    String email,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A35F2),
            const Color(0xFF147DFF).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sub.isPremium
                  ? (loc?.get('premium_badge') ?? 'PREMIUM')
                  : (loc?.get('free') ?? 'GRATUIT'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub.isPremium
                ? (loc?.get('premium_active_status') ??
                      'Votre abonnement est actif')
                : (loc?.get('premium_banner_msg') ??
                      'Passez à la version Premium'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumPage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.white,
                foregroundColor: const Color(0xFF6A35F2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(29),
                ),
              ),
              child: Text(
                sub.isPremium
                    ? (loc?.get('manage_subscription') ??
                          'Gérer mon abonnement')
                    : (loc?.get('premium_banner_msg') ??
                          'Passez à la version Premium'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, AppLocalizations? loc) {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'color': const Color(0xFF147DFF),
        'label': loc?.get('feat_unlimited_tickets') ?? 'Tickets illimités',
      },
      {
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFFE5484D),
        'label': loc?.get('feat_export') ?? 'Export PDF/CSV',
      },
      {
        'icon': Icons.notifications_active,
        'color': const Color(0xFFF5A524),
        'label': loc?.get('feat_reminders') ?? 'Rappels de garantie',
      },
      {
        'icon': Icons.verified_user,
        'color': const Color(0xFF30A46C),
        'label': loc?.get('feat_warranty') ?? 'Extension de garantie',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(f['icon'] as IconData, color: f['color'] as Color, size: 28),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  f['label'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
