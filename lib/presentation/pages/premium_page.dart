import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/subscription_service.dart';
import 'payment_page.dart';
import 'privacy_policy_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String _selectedPlan = 'yearly';
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de statut pour rediriger en cas de restauration réussie
    final subService = Provider.of<SubscriptionService>(context, listen: false);
    subService.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    Provider.of<SubscriptionService>(context, listen: false).removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    final subService = Provider.of<SubscriptionService>(context, listen: false);
    if (subService.isPremium && mounted) {
      // Si l'utilisateur est passé Premium (via restauration par exemple), on retourne à l'accueil
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonnement activé ! Merci de votre confiance 🚀'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isRestoring ? null : _handleRestore,
            child: _isRestoring 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc?.get('restore') ?? 'Restaurer', style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    loc?.get('limit_reached_msg') ?? 'Désolé, votre essai est expiré.',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C1E),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc?.get('limit_reached_sub') ??
                        'Votre accès est limité. Abonnez-vous dès maintenant pour bénéficier d\'un accès complet.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_motion_rounded, 
                          size: 100, 
                          color: Color(0xFF4F73FB)
                        ),
                        Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Text(
                              loc?.get('live_env') ?? 'Environnement en direct',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildDot(false), _buildDot(true), _buildDot(false), _buildDot(false)],
                  ),
                  const SizedBox(height: 40),

                  _buildPlanOption(
                    id: 'yearly',
                    title: loc?.get('premium_yearly_detail') ?? 'Abonnement annuel',
                    price: '29,99 €',
                    monthlyPrice: '2,50 € / Mois',
                    isBestValue: true,
                    loc: loc,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanOption(
                    id: 'monthly',
                    title: loc?.get('premium_monthly_detail') ?? 'Abonnement mensuel',
                    price: '2,99 €',
                    monthlyPrice: '2,99 € / Mois',
                    isBestValue: false,
                    loc: loc,
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      final price = _selectedPlan == 'yearly' ? '29,99 €' : '2,99 €';
                      Navigator.push(context, MaterialPageRoute(builder: (c) => PaymentPage(plan: _selectedPlan, price: price)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F73FB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
                      elevation: 0,
                    ),
                    child: Text(
                      '${loc?.get('subscribe') ?? 'Souscrire'} →',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const PrivacyPolicyPage())),
                      child: Text(loc?.get('privacy_policy') ?? 'Politique de confidentialité', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: Colors.grey.shade300))),
                    GestureDetector(
                      onTap: () {},
                      child: Text(loc?.get('terms_of_service') ?? 'Conditions d\'utilisation', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);
    final sub = Provider.of<SubscriptionService>(context, listen: false);
    await sub.restorePurchases();
    
    // Un petit délai pour laisser le temps à la Edge Function de répondre si un achat est trouvé
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _isRestoring = false);
      // Si après 3s l'utilisateur n'est toujours pas premium (et donc pas redirigé par le listener)
      if (!sub.isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun abonnement actif trouvé.'))
        );
      }
    }
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 6, height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1A1C1E) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildPlanOption({required String id, required String title, required String price, required String monthlyPrice, bool isBestValue = false, AppLocalizations? loc}) {
    final isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? const Color(0xFF4F73FB) : Colors.grey.shade200, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(loc?.get('manage_unlimited') ?? 'Gérez tous vos tickets sans limite', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(monthlyPrice, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              top: -12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F73FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(loc?.get('best_value_badge') ?? 'Meilleure valeur', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
