import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/ticket_card.dart';
import '../../data/models/ticket_model.dart';
// import '../../core/services/firebase_service.dart';
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
    if (_currentTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.get('no_tickets') + ' à exporter')));
      return;
    }

    try {
      // 1. Préparer les données
      List<List<dynamic>> rows = [];
      rows.add([AppLocalizations.of(context)!.get('store_name'), AppLocalizations.of(context)!.get('date'), "Montant Total (€)", AppLocalizations.of(context)!.get('warranty_end_date')]); // Header

      for (var t in _currentTickets) {
        rows.add([
          t.storeName,
          "${t.date.day}/${t.date.month}/${t.date.year}",
          t.totalAmount.toStringAsFixed(2),
          "${t.warrantyEndDate.day}/${t.warrantyEndDate.month}/${t.warrantyEndDate.year}"
        ]);
      }

      // 2. Convertir en CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // 3. Enregistrer temporairement
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/mes_tickets_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // 4. Partager
      await Share.shareXFiles([XFile(path)], text: 'Voici mon export de tickets de caisse.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter en CSV',
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
                  Text(AppLocalizations.of(context)!.get('error')),
                  const SizedBox(height: 16),
                  if (snapshot.error.toString().contains('User not authenticated'))
                    Text(AppLocalizations.of(context)!.get('no_tickets') + ' ' + AppLocalizations.of(context)!.get('tickets').toLowerCase()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    },
                    child: Text(AppLocalizations.of(context)!.get('login')),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.get('no_tickets'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ScanPage())
            ),
            icon: const Icon(Icons.camera_alt),
            label: Text(AppLocalizations.of(context)!.get('scan_ticket'))
          )
        ]
      )
    );
  }

  Widget _buildStatsSection(List<TicketModel> tickets) {
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
            AppLocalizations.of(context)!.get('total'),
            '${tickets.length}',
            Icons.receipt_long,
            Theme.of(context).primaryColor
          ),
          _buildStatItem(
            AppLocalizations.of(context)!.get('warranty_expiring'),
            '${tickets.where((t) => t.isWarrantyExpiringSoon()).length}',
            Icons.warning_amber,
            Colors.orange
          ),
          _buildStatItem(
            AppLocalizations.of(context)!.get('warranty_expired'),
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
