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
    if (!sub.isPremium) { _showUpgradeDialog(loc); return; }
    if (tickets.isEmpty) return;

    try {
      List<List<dynamic>> rows = [];
      rows.add([loc?.get('store_name'), loc?.get('date'), "Total (€)", loc?.get('warranty_end_date')]);
      for (var t in tickets) {
        rows.add([t.storeName, "${t.date.day}/${t.date.month}/${t.date.year}", t.totalAmount.toStringAsFixed(2), "${t.warrantyEndDate.day}/${t.warrantyEndDate.month}/${t.warrantyEndDate.year}"]);
      }
      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv";
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
        title: Text(loc?.get('upgrade_premium') ?? 'Premium'),
        content: Text(loc?.get('limit_reached_msg') ?? 'Limite atteinte'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc?.get('cancel') ?? 'OK')),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())); }, child: Text(loc?.get('upgrade_premium') ?? 'Upgrade')),
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
      appBar: AppBar(
        title: Text(loc?.get('my_tickets') ?? 'Tickets', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: () => _exportToCSV(provider.tickets))],
      ),
      body: Column(
        children: [
          if (!sub.isPremium && !canScan)
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: Colors.orange.withOpacity(0.15),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc?.get('limit_reached_msg') ?? 'Limite de 3 tickets atteinte.',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTickets(),
              child: _buildContent(provider, loc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TicketProvider provider, AppLocalizations? loc) {
    if (provider.isLoading && provider.tickets.isEmpty) return const Center(child: CircularProgressIndicator());
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
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => TicketDetailPage(ticket: ticket))),
                onDelete: () => provider.deleteTicket(ticket.id!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations? loc) {
    return Center(child: Text(loc?.get('no_tickets') ?? 'No tickets'));
  }

  Widget _buildStatsSection(List<TicketModel> tickets, AppLocalizations? loc) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(loc?.get('total') ?? 'Total', '${tickets.length}', Icons.receipt, Colors.blue),
          _buildStatItem(loc?.get('warranty') ?? 'Warranty', '${tickets.where((t) => t.isWarrantyExpiringSoon()).length}', Icons.warning, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 20), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)), Text(label, style: const TextStyle(fontSize: 10))]);
  }
}
