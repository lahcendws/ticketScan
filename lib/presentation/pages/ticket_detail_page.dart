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
    for (var c in _productNameControllers) {
      c.dispose();
    }
    for (var c in _productPriceControllers) {
      c.dispose();
    }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);
    final mutedText = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Fonction Premium', style: TextStyle(color: textColor)),
        content: Text(message, style: TextStyle(color: mutedText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard', style: TextStyle(color: mutedText)),
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

    if (!_productWarrantyStates.any((hasWarranty) => hasWarranty)) {
      await _showNoWarrantyEditWarning();
      return;
    }

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
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Provider.of<TicketProvider>(
                context,
                listen: false,
              ).deleteTicket(widget.ticket.id!);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    loc?.get('ticket_deleted') ?? 'Ticket supprimé',
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
            child: Text(
              loc?.get('delete_invalid_ticket') ?? 'Supprimer le ticket',
              style: const TextStyle(color: Colors.red),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textOnSurface = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);
    final mutedColor = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: textOnSurface,
        elevation: 0,
        title: Text(
          _isEditing
              ? '${localizations?.get('edit_ticket') ?? 'Modifier le ticket'} · ${widget.ticket.storeName}'
              : '${localizations?.get('ticket_details') ?? 'Détails du ticket'} · ${widget.ticket.storeName}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textOnSurface,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
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
                    icon: Icon(Icons.picture_as_pdf, color: mutedColor),
                    onPressed: _handlePDFExport,
                    tooltip: 'Aperçu PDF',
                  ),
            IconButton(
              icon: Icon(Icons.share, color: mutedColor),
              onPressed: _handleShare,
              tooltip: localizations?.get('share') ?? 'Partager',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: mutedColor),
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
                    icon: Icon(Icons.check, color: primary),
                    onPressed: _saveChanges,
                    tooltip: 'Enregistrer les modifications',
                  ),
            IconButton(
              icon: Icon(Icons.share, color: mutedColor),
              onPressed: _handleShare,
              tooltip: localizations?.get('share') ?? 'Partager',
            ),
            IconButton(
              icon: Icon(Icons.close, color: mutedColor),
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
                ? _buildEditForm(
                    localizations,
                    primary,
                    isDark,
                    surfaceColor,
                    textOnSurface,
                  )
                : _buildInfoCard(
                    locale,
                    localizations,
                    primary,
                    isDark,
                    surfaceColor,
                    textOnSurface,
                  ),
            const SizedBox(height: 24),
            Text(
              localizations?.get('products') ?? 'Articles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textOnSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildProductsSection(
              localizations,
              primary,
              isDark,
              surfaceColor,
              textOnSurface,
              mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(
    AppLocalizations? localizations,
    Color primary,
    bool isDark,
    Color surfaceColor,
    Color textOnSurface,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
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
              textOnSurface,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              localizations?.get('date') ?? 'Date (DD/MM/YYYY)',
              _dateController,
              Icons.calendar_today_outlined,
              primary,
              textOnSurface,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              '${localizations?.get('total_amount') ?? 'Total Amount'} (${widget.ticket.currency})',
              _amountController,
              Icons.attach_money_outlined,
              primary,
              textOnSurface,
              isDark,
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
    Color textOnSurface,
    bool isDark,
  ) {
    final mutedColor = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);
    final fillColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF8FBFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: mutedColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: mutedColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: TextStyle(color: textOnSurface, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            filled: true,
            fillColor: fillColor,
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
    bool isDark,
    Color surfaceColor,
    Color textOnSurface,
  ) {
    final mutedColor = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
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
                  backgroundColor: primary.withValues(alpha: 0.1),
                  child: Icon(Icons.store, color: primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ticket.storeName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textOnSurface,
                        ),
                      ),
                      Text(
                        widget.ticket.category ?? 'Other',
                        style: TextStyle(color: mutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: mutedColor.withValues(alpha: 0.2)),
            _buildInfoRow(
              localizations?.get('total_amount') ?? 'Total',
              '${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}',
              primary: primary,
              isBold: true,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              localizations?.get('warranty_end_date') ?? 'Warranty End',
              DateFormat(
                'dd/MM/yyyy',
                locale,
              ).format(widget.ticket.warrantyEndDate),
              primary: primary,
              isDark: isDark,
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
    required bool isDark,
  }) {
    final mutedColor = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);
    final textOnSurface = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: mutedColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? primary : textOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(
    AppLocalizations? localizations,
    Color primary,
    bool isDark,
    Color surfaceColor,
    Color textOnSurface,
    Color mutedColor,
  ) {
    final fillColor = isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF8FBFF);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
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
                                  style: TextStyle(
                                    color: textOnSurface,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        localizations?.get('product_name') ??
                                        'Product Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: mutedColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: mutedColor.withValues(
                                          alpha: 0.3,
                                        ),
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
                                    fillColor: fillColor,
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
                                  style: TextStyle(
                                    color: textOnSurface,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        '${localizations?.get('price') ?? 'Price'} (${widget.ticket.currency})',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: mutedColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: mutedColor.withValues(
                                          alpha: 0.3,
                                        ),
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
                                    fillColor: fillColor,
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
                                  style: TextStyle(
                                    color: textOnSurface,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${_productPriceControllers[index].text} ${widget.ticket.currency}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textOnSurface,
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
            Divider(height: 1, color: mutedColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations?.get('total') ?? 'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textOnSurface,
                    ),
                  ),
                  Text(
                    '${widget.ticket.totalAmount.toStringAsFixed(2)} ${widget.ticket.currency}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textOnSurface,
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
