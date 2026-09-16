import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_localizations.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/ticket_provider.dart';
import '../widgets/ticket_card.dart';
import 'scan_page.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  static const _primary = Color(0xFF147DFF);
  static const _navy = Color(0xFF102A56);
  static const _muted = Color(0xFF5A7194);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final provider = context.watch<TicketProvider>();
    final subscription = context.watch<SubscriptionService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF8FBFF);
    final appBarBackgroundColor = isDark
        ? const Color(0xFF16213E)
        : Colors.white;
    final appBarForegroundColor = isDark ? const Color(0xFFECF0F1) : _navy;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16213E)
                    : const Color(0xFFE7F1FF),
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
                  color: appBarForegroundColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  const TextSpan(text: 'Ticket'),
                  TextSpan(
                    text: 'Scan',
                    style: const TextStyle(color: _primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: provider.loadTickets,
        child: _buildBody(provider, subscription, localizations),
      ),
    );
  }

  Widget _buildBody(
    TicketProvider provider,
    SubscriptionService subscription,
    AppLocalizations? localizations,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotaCardColor = isDark
        ? const Color(0xFF16213E)
        : const Color(0xFFE7F1FF);
    final headingColor = isDark ? const Color(0xFFECF0F1) : _navy;
    final bodyColor = isDark ? const Color(0xFFBDC3C7) : _muted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: quotaCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                localizations?.get('registered_tickets') ??
                    'Tickets enregistrés',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.tickets.length.toString(),
                style: TextStyle(
                  color: headingColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subscription.isPremium
                    ? (localizations?.get('premium_ticket_access') ??
                          'Tickets illimités')
                    : (localizations?.get('free_offer_limit') ??
                          'Offre gratuite : 3 tickets max'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanPage())),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(
              localizations?.get('scan_ticket_action') ?? 'Scanner un ticket',
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
        const SizedBox(height: 26),
        Text(
          localizations?.get('my_tickets') ?? 'Mes tickets',
          style: TextStyle(
            color: headingColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.isLoading && provider.tickets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _primary)),
          )
        else if (provider.tickets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 52,
                  color: Color(0xFF9DB4D1),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations?.get('no_tickets') ?? 'Aucun ticket enregistré',
                  style: const TextStyle(color: _muted, fontSize: 16),
                ),
              ],
            ),
          )
        else ...[
          for (final ticket in provider.tickets) ...[
            TicketCard(
              ticket: ticket,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TicketDetailPage(ticket: ticket),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
