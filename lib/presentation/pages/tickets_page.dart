import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/subscription_service.dart';
import 'scan_page.dart';
import 'ticket_list_page.dart';
import 'premium_page.dart';
import 'alerts_page.dart';
import 'profile_page.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  static const _primary = Color(0xFF147DFF);
  static const _navy = Color(0xFF102A56);
  static const _muted = Color(0xFF5A7194);
  static const _pageBackground = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context);
    final provider = Provider.of<TicketProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16213E) : Colors.white;
    final primaryText = isDark ? const Color(0xFFECF0F1) : _navy;

    final canScan = sub.canScan(provider.tickets);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : _pageBackground,
      drawer: Drawer(
        backgroundColor: surface,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Text(
                  loc?.get('app_name') ?? 'TicketScan',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: _primary),
                title: Text(loc?.get('home') ?? 'Accueil'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.confirmation_number_outlined,
                  color: _primary,
                ),
                title: Text(loc?.get('my_tickets') ?? 'Mes tickets'),
                onTap: () => _openDrawerPage(const TicketListPage()),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none, color: _primary),
                title: Text(loc?.get('alerts') ?? 'Alertes'),
                onTap: () => _openDrawerPage(const AlertsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: _primary),
                title: Text(loc?.get('account') ?? 'Compte'),
                onTap: () => _openDrawerPage(const ProfilePage()),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: primaryText),
            tooltip: loc?.get('menu') ?? 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: _primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: 'Ticket'),
                  TextSpan(
                    text: 'Scan',
                    style: TextStyle(color: _primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!sub.isPremium && !canScan)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc?.get('limit_reached_msg') ??
                          'Limite de 3 tickets atteinte.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.orange,
                    size: 20,
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey.shade800,
              onRefresh: () => provider.loadTickets(),
              child: _buildContent(provider, loc),
            ),
          ),
        ],
      ),
    );
  }

  void _openDrawerPage(Widget page) {
    Navigator.pop(context);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildContent(TicketProvider provider, AppLocalizations? loc) {
    if (provider.isLoading && provider.tickets.isEmpty)
      return const Center(child: CircularProgressIndicator(color: _primary));

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildWelcomeHeader(loc),
        _buildScanActions(),
        _buildSecurityCard(),
        _buildStatsSection(provider.tickets, loc),
        if (!context.read<SubscriptionService>().isPremium)
          _buildPremiumCard(loc),
        if (provider.tickets.isEmpty) _buildEmptyState(loc),
      ],
    );
  }

  Widget _buildWelcomeHeader(AppLocalizations? loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? const Color(0xFFECF0F1) : _navy;
    final bodyColor = isDark ? const Color(0xFFBDC3C7) : _muted;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.get('welcome_title') ?? 'Bienvenue !',
            style: TextStyle(
              color: headingColor,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            loc?.get('welcome_subtitle') ??
                'Gardez vos tickets et garanties\nau même endroit.',
            style: TextStyle(
              color: bodyColor,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanActions() {
    final loc = AppLocalizations.of(context);

    Future<void> pickImage() async {
      final imagePath = await CameraService.pickImageFromGallery();
      if (!mounted || imagePath == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanPage(initialImagePath: imagePath),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                loc?.get('scan_ticket_action') ?? 'Scanner un ticket',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ScanPage())),
              icon: const Icon(Icons.image_outlined),
              label: Text(
                loc?.get('choose_image_action') ?? 'Choisir une image',
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFEAF3FF),
                foregroundColor: _primary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? const Color(0xFFECF0F1) : _navy;
    final bodyColor = isDark ? const Color(0xFFBDC3C7) : _muted;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFD1E5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc?.get('security_title') ?? 'Vos tickets en toute sécurité',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  loc?.get('security_description') ??
                      'Prenez en photo vos reçus, notre IA extrait les informations et vous aide à gérer vos garanties.',
                  style: TextStyle(color: bodyColor, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(AppLocalizations? loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? const Color(0xFFECF0F1) : _navy;
    final bodyColor = isDark ? const Color(0xFFBDC3C7) : _muted;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2350) : const Color(0xFFF0ECFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PremiumPage())),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFE0D5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFF6A35F2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc?.get('upgrade_premium') ?? 'Passer à Premium',
                    style: TextStyle(
                      color: headingColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    loc?.get('premium_description') ??
                        'Tickets illimités, export PDF/CSV, extension de garantie et alertes.',
                    style: TextStyle(color: bodyColor, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6A35F2)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      heightFactor: 1.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: const Color(0xFF9DB4D1),
          ),
          const SizedBox(height: 16),
          Text(
            loc?.get('no_tickets') ?? 'No tickets',
            style: TextStyle(
              color: isDark ? const Color(0xFFBDC3C7) : _muted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(List<TicketModel> tickets, AppLocalizations? loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? const Color(0xFFECF0F1) : _navy;
    final expiringCount = tickets
        .where((ticket) => ticket.isWarrantyExpiringSoon())
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc?.get('my_tickets') ?? 'Mes tickets',
                style: TextStyle(
                  color: headingColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TicketListPage()),
                ),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: Text(loc?.get('see_all') ?? 'Voir tout'),
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  loc?.get('tickets_free') ?? 'Tickets\ngratuit',
                  '${tickets.length}',
                  'gratuit',
                  Icons.confirmation_number_outlined,
                  _primary,
                  const Color(0xFFEAF3FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  loc?.get('products_under_warranty') ??
                      'Produits\nsous garantie',
                  '${tickets.where((ticket) => ticket.products.any((product) => product['hasWarranty'] == true)).length}',
                  'sous garantie',
                  Icons.shield_outlined,
                  const Color(0xFF00B87A),
                  const Color(0xFFE8FBF3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  loc?.get('alerts_upcoming') ?? 'Alerte(s)\nà venir',
                  '$expiringCount',
                  'à venir',
                  Icons.notifications_none,
                  const Color(0xFFFFA400),
                  const Color(0xFFFFF7DF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  'Premium',
                  'Plus de',
                  loc?.get('premium_features') ?? 'Plus de\nfonctionnalités',
                  Icons.workspace_premium_outlined,
                  const Color(0xFF6A35F2),
                  const Color(0xFFF0ECFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 9),
          Text(
            title == 'Premium' ? value : value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: title == 'Premium' ? color : _navy,
              fontSize: title == 'Premium' ? 15 : 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}
