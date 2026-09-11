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
    final locale = AppLocalizations.of(context)?.locale.toString() ?? 'fr_FR';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Alertes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: tickets.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, color: _primary, size: 52),
                  SizedBox(height: 14),
                  Text(
                    'Aucune alerte à venir',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Vos prochaines échéances apparaîtront ici.',
                    style: TextStyle(color: _muted),
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
                    color: const Color(0xFFFFF7DF),
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
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Garantie jusqu\'au ${DateFormat('dd/MM/yyyy', locale).format(ticket.warrantyEndDate)}',
                              style: const TextStyle(color: _muted),
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
