import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ticket_model.dart';
import '../../core/services/app_localizations.dart';

class TicketDetailPage extends StatelessWidget {
  final TicketModel ticket;

  const TicketDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations?.locale.toString() ?? 'fr_FR';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('ticket_details') ?? 'Détails du ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage de la photo du ticket
            _buildImageCard(context),
            const SizedBox(height: 20),
            
            // Carte En-tête avec les infos principales
            _buildInfoCard(context, locale, localizations),
            const SizedBox(height: 24),
            
            // Liste des produits
            Text(
              localizations?.get('products') ?? 'Articles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProductsTable(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ticket.imageUrl.isNotEmpty
            ? Image.network(ticket.imageUrl, fit: BoxFit.contain)
            : const Icon(Icons.receipt, color: Colors.white, size: 64),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String locale, AppLocalizations? localizations) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.store, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.category, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(ticket.category ?? 'Autre', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(localizations?.get('total_amount') ?? 'Montant Total', '${ticket.totalAmount.toStringAsFixed(2)} ${ticket.currency}', isBold: true, context: context),
            const SizedBox(height: 8),
            _buildDetailRow(localizations?.get('warranty_end_date') ?? 'Fin de Garantie', DateFormat('dd/MM/yyyy', locale).format(ticket.warrantyEndDate), context: context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ...ticket.products.map((product) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product['name'] ?? 'Article', style: const TextStyle(fontSize: 15))),
                Text(product['price']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${ticket.totalAmount.toStringAsFixed(2)} ${ticket.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, required BuildContext context}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Theme.of(context).primaryColor : null)),
      ],
    );
  }
}
