import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import 'dart:convert';

class TicketDetailPage extends StatefulWidget {
  final TicketModel ticket;
  const TicketDetailPage({super.key, required this.ticket});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  int _activeImageIndex = 0;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _storeController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  final List<TextEditingController> _productNameControllers = [];
  final List<TextEditingController> _productPriceControllers = [];
  final List<bool> _productWarrantyStates = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _storeController = TextEditingController(text: widget.ticket.storeName);
    _amountController = TextEditingController(text: widget.ticket.totalAmount.toStringAsFixed(2));
    _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.ticket.date));
    
    _productNameControllers.clear();
    _productPriceControllers.clear();
    _productWarrantyStates.clear();
    for (var product in widget.ticket.products) {
      _productNameControllers.add(TextEditingController(text: product['name']?.toString() ?? ''));
      _productPriceControllers.add(TextEditingController(text: product['price']?.toString() ?? '0.00'));
      _productWarrantyStates.add(product['hasWarranty'] == true);
    }
  }

  @override
  void dispose() {
    _storeController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    for (var c in _productNameControllers) c.dispose();
    for (var c in _productPriceControllers) c.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final ticketId = widget.ticket.id;
    if (ticketId == null) return;
    setState(() => _isSaving = true);
    try {
      final dateParts = _dateController.text.split('/');
      final newDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      final List<Map<String, dynamic>> newProducts = [];
      for (int i = 0; i < _productNameControllers.length; i++) {
        newProducts.add({
          'name': _productNameControllers[i].text,
          'price': _productPriceControllers[i].text,
          'hasWarranty': _productWarrantyStates[i],
        });
      }
      final updatedData = {
        'store_name': _storeController.text,
        'total_amount': double.parse(_amountController.text.replaceAll(',', '.')),
        'date': newDate.toIso8601String(),
        'products': newProducts,
      };
      await Provider.of<TicketProvider>(context, listen: false).updateTicket(ticketId, updatedData);
      if (mounted) {
        setState(() { _isEditing = false; _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket mis à jour')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showFullScreenImage(String path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.network(SupabaseService.getPublicUrl(path), fit: BoxFit.contain))),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations?.locale.toString() ?? 'fr_FR';
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('ticket_details') ?? 'Détails'),
        actions: [
          if (!_isEditing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
          else _isSaving ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))) : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveChanges),
          if (_isEditing) IconButton(icon: const Icon(Icons.close), onPressed: () { _initControllers(); setState(() => _isEditing = false); }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainImageCard(),
            const SizedBox(height: 12),
            _buildImageThumbnails(),
            const SizedBox(height: 20),
            _isEditing ? _buildEditForm() : _buildInfoCard(context, locale, localizations),
            const SizedBox(height: 24),
            Text(localizations?.get('products') ?? 'Articles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _storeController, decoration: const InputDecoration(labelText: 'Magasin', prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 12),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date (JJ/MM/AAAA)', prefixIcon: Icon(Icons.calendar_today))),
            const SizedBox(height: 12),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant Total', prefixIcon: Icon(Icons.euro))),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageCard() {
    if (widget.ticket.imageUrls.isEmpty) return const SizedBox();
    final path = widget.ticket.imageUrls[_activeImageIndex];
    return GestureDetector(
      onTap: () => _showFullScreenImage(path),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            SupabaseService.getPublicUrl(path),
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
              image: DecorationImage(image: NetworkImage(SupabaseService.getPublicUrl(widget.ticket.imageUrls[index])), fit: BoxFit.cover),
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

  Widget _buildProductsSection() {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ...List.generate(_productNameControllers.length, (index) {
            final bool isGuaranteed = _productWarrantyStates[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_isEditing) IconButton(icon: Icon(isGuaranteed ? Icons.verified_user : Icons.verified_user_outlined), color: isGuaranteed ? Colors.green : Colors.grey, onPressed: () => setState(() => _productWarrantyStates[index] = !isGuaranteed))
                  else if (isGuaranteed) const Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.verified_user, color: Colors.green, size: 18)),
                  Expanded(
                    child: _isEditing ? Row(children: [Expanded(flex: 3, child: TextField(controller: _productNameControllers[index], decoration: const InputDecoration(hintText: 'Produit', isDense: true))), const SizedBox(width: 8), Expanded(flex: 1, child: TextField(controller: _productPriceControllers[index], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Prix', isDense: true)))])
                    : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(_productNameControllers[index].text, style: const TextStyle(fontSize: 15))), Text('${_productPriceControllers[index].text} ${widget.ticket.currency}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
            );
          }),
          if (!_isEditing) ...[
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
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 15)), Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Theme.of(context).primaryColor : null))]);
  }
}
