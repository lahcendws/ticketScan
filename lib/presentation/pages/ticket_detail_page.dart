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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Partage
            },
          ),
        ],
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
            _buildProductsList(context, localizations),
            const SizedBox(height: 24),

            // Texte brut extrait (OCR)
            if (ticket.extractedText.isNotEmpty) ...[
              ExpansionTile(
                title: const Text('Voir le texte brut du ticket'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      ticket.extractedText.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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

  Widget _buildImageCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black87, // Ajout du fond ici au lieu de Image.network
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty
            ? Image.network(
                ticket.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(context),
              )
            : _buildImagePlaceholder(context),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text('Photo non disponible', style: TextStyle(color: Colors.grey)),
        ],
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
                      Text(DateFormat('dd MMMM yyyy', locale).format(ticket.date), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(
              localizations?.get('total_amount') ?? 'Montant Total', 
              '${ticket.totalAmount.toStringAsFixed(2)} €', 
              isBold: true,
              context: context,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              localizations?.get('warranty_end_date') ?? 'Fin de Garantie', 
              DateFormat('dd/MM/yyyy', locale).format(ticket.warrantyEndDate),
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, required BuildContext context}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Theme.of(context).primaryColor : null,
          )
        ),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context, AppLocalizations? localizations) {
    if (ticket.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(localizations?.get('no_tickets') ?? 'Aucun article détecté'),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ticket.products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 20, color: Theme.of(context).primaryColor.withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(child: Text(ticket.products[index], style: const TextStyle(fontSize: 15))),
            ],
          ),
        );
      },
    );
  }
}
