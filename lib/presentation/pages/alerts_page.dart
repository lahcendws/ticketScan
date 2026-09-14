import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/ticket_provider.dart';
import '../../core/services/app_localizations.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  static const _navy = Color(0xFF102A56);
  static const _muted = Color(0xFF5A7194);
  static const _primary = Color(0xFF147DFF);

  @override
  Widget build(BuildContext context) {
    final tickets = context
        .watch<TicketProvider>()
        .tickets
        .where((ticket) => ticket.isWarrantyExpiringSoon())
        .toList();
    final loc = AppLocalizations.of(context);
    final locale = loc?.locale.toString() ?? 'fr_FR';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF8FBFF);
    final surface = isDark ? const Color(0xFF16213E) : Colors.white;
    final heading = isDark ? const Color(0xFFECF0F1) : _navy;
    final muted = isDark ? const Color(0xFFBDC3C7) : _muted;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: heading,
        elevation: 0,
        title: Text(
          loc?.get('alerts_title') ?? 'Alertes',
          style: TextStyle(fontWeight: FontWeight.w800, color: heading),
        ),
      ),
      body: tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, color: _primary, size: 52),
                  SizedBox(height: 14),
                  Text(
                    loc?.get('no_alerts_title') ?? 'Aucune alerte à venir',
                    style: TextStyle(
                      color: heading,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    loc?.get('no_alerts_description') ??
                        'Vos prochaines échéances apparaîtront ici.',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3020)
                        : const Color(0xFFFFF7DF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFFFA400),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.storeName,
                              style: TextStyle(
                                color: heading,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${loc?.get('warranty_until') ?? 'Garantie jusqu\'au'} ${DateFormat('dd/MM/yyyy', locale).format(ticket.warrantyEndDate)}',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
