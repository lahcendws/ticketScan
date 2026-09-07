import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../widgets/ticket_card.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/subscription_service.dart';
import 'scan_page.dart';
import 'ticket_detail_page.dart';
import 'premium_page.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).loadTickets();
    });
  }

  Future<void> _exportToCSV(List<TicketModel> tickets) async {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context, listen: false);
    if (!sub.isPremium) {
      _showUpgradeDialog(loc);
      return;
    }
    if (tickets.isEmpty) return;

    try {
      List<List<dynamic>> rows = [];
      rows.add([
        loc?.get('store_name'),
        loc?.get('date'),
        "Total (€)",
        loc?.get('warranty_end_date'),
      ]);
      for (var t in tickets) {
        rows.add([
          t.storeName,
          "${t.date.day}/${t.date.month}/${t.date.year}",
          t.totalAmount.toStringAsFixed(2),
          "${t.warrantyEndDate.day}/${t.warrantyEndDate.month}/${t.warrantyEndDate.year}",
        ]);
      }
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }

  void _showUpgradeDialog(AppLocalizations? loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc?.get('upgrade_premium') ?? 'Premium',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          loc?.get('limit_reached_msg') ?? 'Limite atteinte',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              loc?.get('cancel') ?? 'OK',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              loc?.get('upgrade_premium') ?? 'Upgrade',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context);
    final provider = Provider.of<TicketProvider>(context);

    final canScan = sub.canScan(provider.tickets);

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc?.get('my_tickets') ?? 'Tickets',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white70),
            onPressed: () => _exportToCSV(provider.tickets),
          ),
        ],
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

  Widget _buildContent(TicketProvider provider, AppLocalizations? loc) {
    if (provider.isLoading && provider.tickets.isEmpty)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    if (provider.tickets.isEmpty) return _buildEmptyState(loc);

    return Column(
      children: [
        _buildStatsSection(provider.tickets, loc),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tickets.length,
            itemBuilder: (context, index) {
              final ticket = provider.tickets[index];
              return TicketCard(
                ticket: ticket,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TicketDetailPage(ticket: ticket),
                  ),
                ),
                onDelete: () => provider.deleteTicket(ticket.id!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations? loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            loc?.get('no_tickets') ?? 'No tickets',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(List<TicketModel> tickets, AppLocalizations? loc) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            loc?.get('total') ?? 'Total',
            '${tickets.length}',
            Icons.receipt_outlined,
            Theme.of(context).primaryColor,
          ),
          _buildStatItem(
            loc?.get('warranty') ?? 'Warranty',
            '${tickets.where((t) => t.isWarrantyExpiringSoon()).length}',
            Icons.warning_amber_outlined,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}
