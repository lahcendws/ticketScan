import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/app_localizations.dart';
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
  
  // Liste de contrôleurs et états pour les produits
  final List<TextEditingController> _productNameControllers = [];
  final List<TextEditingController> _productPriceControllers = [];
  final List<bool> _productWarrantyStates = [];

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

    // Initialiser les contrôleurs et les états de garantie
    for (var product in widget.analysis.products) {
      _productNameControllers.add(TextEditingController(text: product['name']?.toString() ?? ''));
      _productPriceControllers.add(TextEditingController(text: product['price']?.toString() ?? '0.00'));
      _productWarrantyStates.add(product['hasWarranty'] == true);
    }
  }

  @override
  void dispose() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _warrantyController.dispose();
    for (var c in _productNameControllers) c.dispose();
    for (var c in _productPriceControllers) c.dispose();
    super.dispose();
  }

  void _close(dynamic result) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _onSave() async {
    try {
      final dateStr = _dateController.text.trim();
      final dateParts = dateStr.split('/');
      if (dateParts.length != 3) throw Exception(AppLocalizations.of(context)?.get('invalid_date_format') ?? 'Format de date invalide');

      final DateTime finalDate = DateTime(
        int.parse(dateParts[2].trim()),
        int.parse(dateParts[1].trim()),
        int.parse(dateParts[0].trim()),
      );

      String amountStr = _amountController.text.replaceAll(' ', '').replaceAll(',', '.').replaceAll('€', '').trim();
      final double finalAmount = double.tryParse(amountStr) ?? 0.0;
      final int finalWarranty = int.tryParse(_warrantyController.text.trim()) ?? 2;

      // Récupérer les produits modifiés avec leur état de garantie
      final List<Map<String, dynamic>> updatedProducts = [];
      for (int i = 0; i < _productNameControllers.length; i++) {
        updatedProducts.add({
          'name': _productNameControllers[i].text.trim(),
          'price': _productPriceControllers[i].text.trim(),
          'hasWarranty': _productWarrantyStates[i],
        });
      }

      final updatedAnalysis = TicketAnalysis(
        storeName: _storeController.text.trim(),
        category: widget.analysis.category,
        date: finalDate,
        totalAmount: finalAmount,
        currency: widget.analysis.currency,
        products: updatedProducts,
        extractedText: widget.analysis.extractedText,
        warrantyYears: finalWarranty,
      );

      // Un ticket sans produit sous garantie n'est d'aucune utilité pour le
      // suivi des garanties : on ne l'enregistre pas tant que l'utilisateur
      // n'a pas coché une garantie sur au moins un produit.
      if (!_hasWarrantyProduct) {
        await _warnNoWarranty();
        return;
      }

      _close(updatedAnalysis);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)?.get('error_prefix') ?? 'Erreur : '}${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _hasWarrantyProduct => _productWarrantyStates.any((w) => w);

  Future<void> _warnNoWarranty() async {
    final loc = AppLocalizations.of(context);
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc?.get('no_warranty_title') ?? 'Aucun produit sous garantie'),
        content: Text(
          loc?.get('no_warranty_msg') ??
              'Ce ticket ne présente aucun produit sous garantie. Il ne sera pas enregistré : sans produit garanti, il est inutile pour le suivi des garanties. Activez la garantie sur au moins un produit pour le conserver, ou abandonnez ce scan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _close(null);
            },
            child: Text(loc?.get('abandon_scan') ?? 'Abandonner le scan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              loc?.get('edit_warranty') ?? 'Modifier la garantie',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F73FB)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
                    _buildFormField(controller: _storeController, label: loc?.get('store_name') ?? 'Magasin', icon: Icons.store),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _dateController, label: loc?.get('date_label') ?? 'Date (JJ/MM/AAAA)', icon: Icons.calendar_today, keyboardType: TextInputType.datetime),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _amountController, label: loc?.get('total_amount') ?? 'Montant total', icon: Icons.euro, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildFormField(controller: _warrantyController, label: loc?.get('warranty_years_label') ?? 'Garantie (années)', icon: Icons.security, keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    Text(loc?.get('edit_products_warranty') ?? 'Modifier les produits & Garantie :', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (!_hasWarrantyProduct) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc?.get('no_warranty_banner') ??
                                    'Aucun produit garanti — le ticket ne sera pas enregistré',
                                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildEditableProductsList(),
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
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.get('verification_title') ?? 'Vérification',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
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
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                Text(
                  AppLocalizations.of(context)?.get('error_image') ?? 'Erreur image',
                  style: const TextStyle(fontSize: 10),
                ),
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

  Widget _buildEditableProductsList() {
    if (_productNameControllers.isEmpty) {
      return Text(AppLocalizations.of(context)?.get('no_products_detected') ?? 'Aucun produit détecté');
    }
    
    return Column(
      children: List.generate(_productNameControllers.length, (index) {
        final bool isGuaranteed = _productWarrantyStates[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // BOUTON GARANTIE RESTAURÉ
              IconButton(
                icon: Icon(isGuaranteed ? Icons.verified_user : Icons.verified_user_outlined),
                color: isGuaranteed ? Colors.green : Colors.grey,
                onPressed: () => setState(() => _productWarrantyStates[index] = !isGuaranteed),
                tooltip: AppLocalizations.of(context)?.get('warranty') ?? 'Garantie',
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _productNameControllers[index],
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.get('product_hint') ?? 'Produit',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _productPriceControllers[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.get('price_hint') ?? 'Prix',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => _close(null),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
              ),
              child: Text(
                loc?.get('cancel') ?? 'Annuler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(29)),
              ),
              child: Text(
                loc?.get('save') ?? 'Enregistrer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
