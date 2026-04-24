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
    final localizations = AppLocalizations.of(context);
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    if (!subscriptionService.isPremium) { _showUpgradeForExportDialog(); return; }
    if (tickets.isEmpty) return;

    try {
      List<List<dynamic>> rows = [];
      rows.add([localizations?.get('store_name'), localizations?.get('date'), "Total (€)", localizations?.get('warranty_end_date')]);
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

  void _showUpgradeForExportDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium'),
        content: Text(loc?.get('upgrade_premium') ?? 'Upgrade required'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc?.get('cancel') ?? 'OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('my_tickets') ?? 'Tickets', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: () => _exportToCSV(ticketProvider.tickets))],
      ),
      body: Column(
        children: [
          if (!subscriptionService.isPremium) _buildUsageLimitIndicator(subscriptionService, localizations),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProvider.loadTickets(),
              child: _buildContent(ticketProvider, localizations),
            ),
          ),
        ],
      ),
      // BOUTON "+" SUPPRIMÉ POUR ÉVITER LA CONFUSION
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

  Widget _buildUsageLimitIndicator(SubscriptionService sub, AppLocalizations? loc) {
    final progress = sub.scansThisMonth / sub.freeLimit;
    final color = progress > 0.8 ? Colors.red : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc?.get('scans_count')}: ${sub.scansThisMonth}/${sub.freeLimit}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
            child: Text(loc?.get('unlimited') ?? 'ILLIMITÉ'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(loc?.get('no_tickets') ?? 'No tickets', style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
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
