import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ticket_model.dart';
import '../../core/services/app_localizations.dart';

class TicketDetailPage extends StatefulWidget {
  final TicketModel ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  int _activeImageIndex = 0;

  void _showFullScreenImage(String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations?.locale.toString() ?? 'fr_FR';

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.get('ticket_details') ?? 'Détails')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainImageCard(),
            const SizedBox(height: 12),
            _buildImageThumbnails(),
            const SizedBox(height: 20),
            _buildInfoCard(context, locale, localizations),
            const SizedBox(height: 24),
            Text(localizations?.get('products') ?? 'Articles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildProductsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageCard() {
    if (widget.ticket.imageUrls.isEmpty) return const SizedBox();
    final url = widget.ticket.imageUrls[_activeImageIndex];

    return GestureDetector(
      onTap: () => _showFullScreenImage(url),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (c, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64)),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnails() {
    if (widget.ticket.imageUrls.length <= 1) return const SizedBox();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.ticket.imageUrls.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() => _activeImageIndex = index),
          child: Container(
            width: 60,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _activeImageIndex == index ? Theme.of(context).primaryColor : Colors.grey, width: 2),
              image: DecorationImage(image: NetworkImage(widget.ticket.imageUrls[index]), fit: BoxFit.cover),
            ),
          ),
        ),
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
                CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), child: Icon(Icons.store, color: Theme.of(context).primaryColor)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ticket.storeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(widget.ticket.category ?? 'Autre', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(localizations?.get('total_amount') ?? 'Total', '${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}', isBold: true),
            const SizedBox(height: 8),
            _buildDetailRow(localizations?.get('warranty_end_date') ?? 'Garantie', DateFormat('dd/MM/yyyy', locale).format(widget.ticket.warrantyEndDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable() {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ...widget.ticket.products.map((product) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product['name']?.toString() ?? 'Article', style: const TextStyle(fontSize: 15))),
                Text('${product['price']?.toString() ?? "0.00"} ${widget.ticket.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                Text('${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Theme.of(context).primaryColor : null)),
      ],
    );
  }
}
