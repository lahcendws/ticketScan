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
    // Charger les tickets au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).loadTickets();
    });
  }

  Future<void> _exportToCSV(List<TicketModel> tickets) async {
    final localizations = AppLocalizations.of(context);
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);

    if (!subscriptionService.isPremium) {
      _showUpgradeForExportDialog();
      return;
    }

    if (tickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((localizations?.get('no_tickets') ?? 'Aucun ticket') + ' à exporter')));
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      rows.add([
        localizations?.get('store_name') ?? 'Magasin',
        localizations?.get('date') ?? 'Date',
        "${localizations?.get('total_amount') ?? 'Montant total'} (€)",
        localizations?.get('warranty_end_date') ?? 'Fin de garantie'
      ]);

      for (var t in tickets) {
        rows.add([
          t.storeName,
          "${t.date.day}/${t.date.month}/${t.date.year}",
          t.totalAmount.toStringAsFixed(2),
          "${t.warrantyEndDate.day}/${t.warrantyEndDate.month}/${t.warrantyEndDate.year}"
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/mes_tickets_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Export tickets.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e')));
    }
  }

  void _showUpgradeForExportDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Premium'),
        content: const Text('L\'export CSV est une fonctionnalité Premium. Passez au Premium pour débloquer cette option.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations?.get('cancel') ?? 'Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
            },
            child: Text(localizations?.get('upgrade_premium') ?? 'Passer Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    
    final tickets = ticketProvider.tickets;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('my_tickets') ?? 'Mes Tickets', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: localizations?.get('export_csv') ?? 'Exporter en CSV',
            onPressed: () => _exportToCSV(tickets),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!subscriptionService.isPremium) _buildUsageLimitIndicator(subscriptionService),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ticketProvider.loadTickets(),
              child: _buildContent(ticketProvider, localizations),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ScanPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(TicketProvider provider, AppLocalizations? localizations) {
    if (provider.isLoading && provider.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.tickets.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsSection(provider.tickets),
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

  Widget _buildUsageLimitIndicator(SubscriptionService subscriptionService) {
    final progress = subscriptionService.scansThisMonth / subscriptionService.freeLimit;
    final color = progress > 0.8 ? Colors.red : (progress > 0.5 ? Colors.orange : Colors.green);

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
                  'Scans ce mois: ${subscriptionService.scansThisMonth}/${subscriptionService.freeLimit}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
            child: const Text('ILLIMITÉ'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations?.get('no_tickets') ?? 'Aucun ticket',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanPage())
              ),
              icon: const Icon(Icons.camera_alt),
              label: Text(localizations?.get('scan_ticket') ?? 'Scanner un ticket')
            )
          ]
        ),
      ),
    );
  }

  Widget _buildStatsSection(List<TicketModel> tickets) {
    final localizations = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            localizations?.get('total') ?? 'Total',
            '${tickets.length}',
            Icons.receipt_long,
            Theme.of(context).primaryColor
          ),
          _buildStatItem(
            localizations?.get('warranty_expiring') ?? 'Garantie expire bientôt',
            '${tickets.where((t) => t.isWarrantyExpiringSoon()).length}',
            Icons.warning_amber,
            Colors.orange
          ),
          _buildStatItem(
            localizations?.get('warranty_expired') ?? 'Garantie expirée',
            '${tickets.where((t) => t.isWarrantyExpired()).length}',
            Icons.error_outline,
            Colors.red
          )
        ]
      )
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)), Text(label, style: const TextStyle(fontSize: 10))]);
  }
}
