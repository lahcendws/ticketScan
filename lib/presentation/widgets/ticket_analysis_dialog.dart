import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/ocr_service.dart';

class TicketAnalysisDialog extends StatefulWidget {
  final TicketAnalysis analysis;
  final String imagePath;

  const TicketAnalysisDialog({
    super.key,
    required this.analysis,
    required this.imagePath,
  });

  @override
  State<TicketAnalysisDialog> createState() => _TicketAnalysisDialogState();
}

class _TicketAnalysisDialogState extends State<TicketAnalysisDialog> {
  late TextEditingController _storeController;
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _warrantyController;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _storeController = TextEditingController(text: widget.analysis.storeName);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.analysis.date),
    );
    _amountController = TextEditingController(
      text: widget.analysis.totalAmount.toStringAsFixed(2),
    );
    _warrantyController = TextEditingController(text: widget.analysis.warrantyYears.toString());
  }

  @override
  void dispose() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  void _close(dynamic result) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.of(context).pop(result);
  }

  void _onSave() {
    try {
      final dateStr = _dateController.text.trim();
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) throw Exception('Format de date invalide');

      final DateTime finalDate = DateTime(
        int.parse(dateParts[2].trim()),
        int.parse(dateParts[1].trim()),
        int.parse(dateParts[0].trim()),
      );

      String amountStr = _amountController.text.replaceAll(' ', '').replaceAll(',', '.').replaceAll('€', '').trim();
      final double finalAmount = double.tryParse(amountStr) ?? 0.0;
      final int finalWarranty = int.tryParse(_warrantyController.text.trim()) ?? 2;

      final updatedAnalysis = TicketAnalysis(
        storeName: _storeController.text.trim(),
        category: widget.analysis.category,
        date: finalDate,
        totalAmount: finalAmount,
        currency: widget.analysis.currency,
        products: widget.analysis.products,
        extractedText: widget.analysis.extractedText,
        warrantyYears: finalWarranty,
      );

      _close(updatedAnalysis);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 24),
                    _buildFormField(controller: _storeController, label: 'Nom du magasin', icon: Icons.store),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _dateController, label: 'Date (JJ/MM/AAAA)', icon: Icons.calendar_today, keyboardType: TextInputType.datetime),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _amountController, label: 'Montant total (€)', icon: Icons.euro, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _warrantyController, label: 'Garantie (années)', icon: Icons.security, keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    _buildDetectedProducts(),
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(child: Text('Vérification', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => _close(null), icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                Text('Erreur image', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDetectedProducts() {
    if (widget.analysis.products.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Produits détectés:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widget.analysis.products.take(5).map((p) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• ${p['name']}', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis))).toList()),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(onPressed: () => _close(null), child: const Text('Annuler'))),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: ElevatedButton(onPressed: _onSave, child: const Text('Enregistrer'))),
        ],
      ),
    );
  }
}
