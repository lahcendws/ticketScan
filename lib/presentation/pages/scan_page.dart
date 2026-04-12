import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/app_localizations.dart';
import '../../data/models/ticket_model.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/ticket_analysis_dialog.dart';
import 'premium_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await CameraService.initialize();
      final hasPermission = await CameraService.requestCameraPermission();
      if (hasPermission) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Erreur caméra: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    if (!subscriptionService.canScan) {
      _showLimitReachedDialog();
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (!hasInternet) {
      _showOfflineDialog(imagePath);
      return;
    }

    try {
      setState(() => _isProcessing = true);
      final analysis = await OCRService.extractTextFromImage(imagePath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final finalAnalysis = await showDialog<TicketAnalysis>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TicketAnalysisDialog(
          analysis: analysis,
          imagePath: imagePath,
        ),
      );
      
      if (finalAnalysis != null) {
        await _saveTicket(finalAnalysis, imagePath);
      }
    } catch (e) {
      debugPrint('Erreur analyse: $e');
      _showErrorSnackBar(localizations?.get('generic_error') ?? 'L\'analyse a échoué.');
      setState(() => _isProcessing = false);
    }
  }

  void _showLimitReachedDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.get('limit_reached') ?? 'Limite atteinte'),
        content: Text(localizations?.get('limit_reached_msg') ?? 'Vous avez atteint votre limite de scans.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations?.get('cancel') ?? 'Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
            },
            child: Text(localizations?.get('upgrade_premium') ?? 'Passer Premium'),
          ),
        ],
      ),
    );
  }

  void _showOfflineDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pas de connexion'),
        content: const Text('L\'analyse IA nécessite une connexion. Voulez-vous sauvegarder la photo pour plus tard ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showErrorSnackBar('Photo gardée en mémoire locale.');
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTicket(TicketAnalysis analysis, String imagePath) async {
    setState(() => _isProcessing = true);
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);

    try {
      debugPrint('Début de l\'upload de l\'image...');
      final fileName = 'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String imageUrl = '';

      try {
        imageUrl = await SupabaseService.uploadTicketImage(imagePath, fileName);
        debugPrint('Image uploadée avec succès: $imageUrl');
      } catch (e) {
        debugPrint('Échec de l\'upload image: $e');
        _showErrorSnackBar('L\'image n\'a pas pu être sauvegardée sur le cloud.');
      }

      final warrantyDate = analysis.date.add(Duration(days: analysis.warrantyYears * 365));
      final ticket = TicketModel(
        storeName: analysis.storeName,
        date: analysis.date,
        totalAmount: analysis.totalAmount,
        products: analysis.products,
        imageUrl: imageUrl,
        warrantyEndDate: warrantyDate,
        extractedText: analysis.extractedText,
        createdAt: DateTime.now(),
      );
      
      final ticketData = await SupabaseService.addTicket(ticket.toMap());

      // Incrémenter le compteur de scans
      await subscriptionService.incrementScanCount();

      await NotificationService.scheduleWarrantyNotification(
        id: ticketData['id'].hashCode,
        productName: analysis.products.isNotEmpty ? analysis.products.first : 'Articles',
        storeName: analysis.storeName,
        warrantyEndDate: warrantyDate,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Erreur sauvegarde ticket: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.get('scan_ticket') ?? 'Scanner un ticket')),
      body: _isInitialized
        ? Stack(children: [
            CameraPreviewWidget(controller: CameraService.cameraController!),
            if (_isProcessing) Container(color: Colors.black54, child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 16), Text('Traitement en cours...', style: TextStyle(color: Colors.white))]))),
            Positioned(bottom: 30, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FloatingActionButton(heroTag: 'gallery', onPressed: () async {
                final path = await CameraService.pickImageFromGallery();
                if (path != null) _processImage(path);
              }, child: const Icon(Icons.photo_library)),
              FloatingActionButton(heroTag: 'camera', onPressed: () async {
                final path = await CameraService.takePicture();
                if (path != null) _processImage(path);
              }, child: const Icon(Icons.camera_alt, size: 32)),
            ]))
          ])
        : const Center(child: CircularProgressIndicator()),
    );
  }
}
