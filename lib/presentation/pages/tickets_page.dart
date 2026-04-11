import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/ticket_card.dart';
import '../../data/models/ticket_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import 'scan_page.dart';
import 'ticket_detail_page.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<TicketModel> _currentTickets = [];

  Future<void> _exportToCSV() async {
    final localizations = AppLocalizations.of(context);
    if (_currentTickets.isEmpty) {
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

      for (var t in _currentTickets) {
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('my_tickets') ?? 'Mes Tickets', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: localizations?.get('export_csv') ?? 'Exporter en CSV',
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.getTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(localizations?.get('error') ?? 'Erreur'),
                  const SizedBox(height: 16),
                  Text(localizations?.get('no_tickets') ?? 'Aucun ticket'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    },
                    child: Text(localizations?.get('login') ?? 'Connexion'),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

          _currentTickets = snapshot.data!.map((data) => TicketModel.fromMap(data)).toList();

          return Column(
            children: [
              _buildStatsSection(_currentTickets),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _currentTickets[index];
                    return TicketCard(
                      ticket: ticket,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => TicketDetailPage(ticket: ticket))),
                      onDelete: () => SupabaseService.deleteTicket(ticket.id!),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ScanPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    return Center(
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
      )
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
