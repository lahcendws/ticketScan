import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ticket_model.dart';

class TicketDetailPage extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte En-tête
            _buildInfoCard(context),
            const SizedBox(height: 24),
            
            // Liste des produits
            Text(
              'Articles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProductsList(context),
            const SizedBox(height: 24),

            // Texte brut extrait (OCR)
            if (ticket.extractedText.isNotEmpty) ...[
              const ExpansionTile(
                title: Text('Voir le texte brut du ticket'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Texte extrait par l\'OCR...',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  )
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.store, color: Theme.of(context).primaryColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(ticket.date), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Montant Total', '${ticket.totalAmount.toStringAsFixed(2)} €', isBold: true),
            const SizedBox(height: 8),
            _buildDetailRow('Fin de Garantie', DateFormat('dd/MM/yyyy').format(ticket.warrantyEndDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context) {
    if (ticket.products.isEmpty) {
      return const Center(child: Text('Aucun article détecté'));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ticket.products.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(child: Text(ticket.products[index], style: const TextStyle(fontSize: 15))),
            ],
          ),
        );
      },
    );
  }
}
