import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/ticket_share_service.dart';
import 'premium_page.dart';

class TicketDetailPage extends StatefulWidget {
  final TicketModel ticket;
  final bool initialEditMode;

  const TicketDetailPage({
    super.key,
    required this.ticket,
    this.initialEditMode = false,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  int _activeImageIndex = 0;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isGeneratingPDF = false;

  late TextEditingController _storeController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  final List<TextEditingController> _productNameControllers = [];
  final List<TextEditingController> _productPriceControllers = [];
  final List<bool> _productWarrantyStates = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
    _initControllers();
  }

  void _initControllers() {
    _storeController = TextEditingController(text: widget.ticket.storeName);
    _amountController = TextEditingController(
      text: widget.ticket.totalAmount.toStringAsFixed(2),
    );
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.ticket.date),
    );

    _productNameControllers.clear();
    _productPriceControllers.clear();
    _productWarrantyStates.clear();
    for (var product in widget.ticket.products) {
      _productNameControllers.add(
        TextEditingController(text: product['name']?.toString() ?? ''),
      );
      _productPriceControllers.add(
        TextEditingController(text: product['price']?.toString() ?? '0.00'),
      );
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

  Future<void> _handlePDFExport() async {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );
    if (!subscriptionService.isPremium) {
      _showUpgradeDialog(
        "L'export PDF professionnel est réservé aux membres Premium.",
      );
      return;
    }
    setState(() => _isGeneratingPDF = true);
    try {
      await PDFService.generateAndPreviewTicketPDF(context, widget.ticket);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingPDF = false);
    }
  }

  Future<void> _handleShare() async {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );
    if (!subscriptionService.isPremium) {
      _showUpgradeDialog(
        'Le partage des tickets est réservé aux membres Premium.',
      );
      return;
    }

    final localizations = AppLocalizations.of(context);
    try {
      await TicketShareService.shareTicket(
        widget.ticket,
        locale: localizations?.locale.toString() ?? 'fr_FR',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de partage : $error')));
    }
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Fonction Premium',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Plus tard',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Passer Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    final ticketId = widget.ticket.id;
    if (ticketId == null) return;
    setState(() => _isSaving = true);
    try {
      final dateParts = _dateController.text.split('/');
      final newDate = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );

      final originalDuration = widget.ticket.warrantyEndDate.difference(
        widget.ticket.date,
      );
      final newWarrantyEndDate = newDate.add(originalDuration);

      final List<Map<String, dynamic>> newProducts = [];
      for (int i = 0; i < _productNameControllers.length; i++) {
        newProducts.add({
          'name': _productNameControllers[i].text,
          'price': _productPriceControllers[i].text,
          'hasWarranty': _productWarrantyStates[i],
        });
      }

      if (!newProducts.any((product) => product['hasWarranty'] == true)) {
        setState(() => _isSaving = false);
        await _showNoWarrantyEditWarning();
        return;
      }

      final updatedData = {
        'store_name': _storeController.text,
        'total_amount': double.parse(
          _amountController.text.replaceAll(',', '.'),
        ),
        'date': newDate.toIso8601String(),
        'warranty_end_date': newWarrantyEndDate.toIso8601String(),
        'products': newProducts,
      };

      await Provider.of<TicketProvider>(
        context,
        listen: false,
      ).updateTicket(ticketId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ticket mis à jour')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showNoWarrantyEditWarning() async {
    final loc = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          loc?.get('no_warranty_title') ?? 'Aucun produit sous garantie',
        ),
        content: Text(
          loc?.get('no_warranty_edit_msg') ??
              'Ce ticket ne peut pas être modifié sans produit sous garantie. La modification ne sera pas enregistrée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc?.get('edit_warranty') ?? 'Modifier la garantie'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                SupabaseService.getPublicUrl(path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = localizations?.locale.toString() ?? 'fr_FR';
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing
              ? localizations?.get('edit_ticket') ?? 'Edit Ticket'
              : localizations?.get('ticket_details') ?? 'Ticket Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!_isEditing) ...[
            _isGeneratingPDF
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.white70,
                    ),
                    onPressed: _handlePDFExport,
                    tooltip: 'Aperçu PDF',
                  ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white70),
              onPressed: _handleShare,
              tooltip: localizations?.get('share') ?? 'Partager',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else ...[
            _isSaving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _saveChanges,
                  ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white70),
              onPressed: _handleShare,
              tooltip: localizations?.get('share') ?? 'Partager',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                _initControllers();
                setState(() => _isEditing = false);
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainImageCard(),
            const SizedBox(height: 12),
            _buildImageThumbnails(primary),
            const SizedBox(height: 20),
            _isEditing
                ? _buildEditForm(localizations, primary)
                : _buildInfoCard(locale, localizations, primary),
            const SizedBox(height: 24),
            Text(
              localizations?.get('products') ?? 'Articles',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildProductsSection(localizations, primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(AppLocalizations? localizations, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildEditField(
              localizations?.get('store_name') ?? 'Store Name',
              _storeController,
              Icons.store_outlined,
              primary,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              localizations?.get('date') ?? 'Date (DD/MM/YYYY)',
              _dateController,
              Icons.calendar_today_outlined,
              primary,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              '${localizations?.get('total_amount') ?? 'Total Amount'} (${widget.ticket.currency})',
              _amountController,
              Icons.attach_money_outlined,
              primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color primary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade600),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade800,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainImageCard() {
    if (widget.ticket.imageUrls.isEmpty) return const SizedBox();
    final path = widget.ticket.imageUrls[_activeImageIndex];
    return GestureDetector(
      onTap: () => _showFullScreenImage(path),
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            SupabaseService.getPublicUrl(path),
            fit: BoxFit.contain,
            loadingBuilder: (c, child, p) => p == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
            errorBuilder: (c, o, s) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnails(Color primary) {
    if (widget.ticket.imageUrls.length <= 1) return const SizedBox();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.ticket.imageUrls.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => setState(() => _activeImageIndex = index),
          child: Container(
            width: 50,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _activeImageIndex == index ? primary : Colors.grey,
                width: 2,
              ),
              image: DecorationImage(
                image: NetworkImage(
                  SupabaseService.getPublicUrl(widget.ticket.imageUrls[index]),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String locale,
    AppLocalizations? localizations,
    Color primary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primary.withOpacity(0.1),
                  child: Icon(Icons.store, color: primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ticket.storeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.ticket.category ?? 'Other',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey.shade700),
            _buildInfoRow(
              localizations?.get('total_amount') ?? 'Total',
              '${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}',
              primary: primary,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              localizations?.get('warranty_end_date') ?? 'Warranty End',
              DateFormat(
                'dd/MM/yyyy',
                locale,
              ).format(widget.ticket.warrantyEndDate),
              primary: primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    required Color primary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? primary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(AppLocalizations? localizations, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ...List.generate(_productNameControllers.length, (index) {
            final bool isGuaranteed = _productWarrantyStates[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_isEditing)
                    IconButton(
                      icon: Icon(
                        isGuaranteed
                            ? Icons.verified_user
                            : Icons.verified_user_outlined,
                      ),
                      color: isGuaranteed ? Colors.green : Colors.grey,
                      onPressed: () => setState(
                        () => _productWarrantyStates[index] = !isGuaranteed,
                      ),
                    )
                  else if (isGuaranteed)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.verified_user,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  Expanded(
                    child: _isEditing
                        ? Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _productNameControllers[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        localizations?.get('product_name') ??
                                        'Product Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: _productPriceControllers[index],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        '${localizations?.get('price') ?? 'Price'} (${widget.ticket.currency})',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primary,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _productNameControllers[index].text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${_productPriceControllers[index].text} ${widget.ticket.currency}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          }),
          if (!_isEditing) ...[
            Divider(height: 1, color: Colors.grey.shade700),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations?.get('total') ?? 'Total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
