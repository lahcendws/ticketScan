import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../widgets/ticket_analysis_dialog.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<String> _capturedImages = [];
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await CameraService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = CameraService.isInitialized;
      });
    }
  }

  Future<void> _takePhoto() async {
    final path = await CameraService.takePicture();
    if (path != null) {
      setState(() => _capturedImages.add(path));
    }
  }

  Future<void> _analyzeTicket() async {
    if (_capturedImages.isEmpty) return;
    await CameraService.cameraController?.pausePreview();
    setState(() => _isProcessing = true);
    try {
      final analysis = await OCRService.extractTextFromImage(_capturedImages.first);
      setState(() => _isProcessing = false);
      if (!mounted) return;
      final finalAnalysis = await showDialog<TicketAnalysis>(
        context: context,
        builder: (context) => TicketAnalysisDialog(
          analysis: analysis,
          imagePath: _capturedImages.first,
        ),
      );
      if (finalAnalysis != null && mounted) {
        await _saveTicket(finalAnalysis);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveTicket(TicketAnalysis analysis) async {
    setState(() => _isProcessing = true);
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    try {
      final List<String> urls = await Future.wait(
        _capturedImages.map((path) =>
          SupabaseService.uploadTicketImage(path, 'ticket_${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}.jpg')
        )
      );

      final ticket = TicketModel(
        storeName: analysis.storeName,
        storeAddress: analysis.storeAddress,
        category: analysis.category,
        date: analysis.date,
        totalAmount: analysis.totalAmount,
        currency: analysis.currency,
        products: analysis.products,
        imageUrls: urls,
        warrantyEndDate: analysis.date.add(Duration(days: analysis.warrantyYears * 365)),
        createdAt: DateTime.now(),
      );

      // IMPORTANT : Utiliser le provider pour une mise à jour immédiate de l'UI
      await ticketProvider.addTicket(ticket);
      await subscriptionService.incrementScanCount();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sauvegarde: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(CameraService.cameraController!),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildImagePreviewList(),
                _buildBottomControls(),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Traitement...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_capturedImages.length} photo(s)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildImagePreviewList() {
    if (_capturedImages.isEmpty) return const SizedBox();
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _capturedImages.length,
        itemBuilder: (context, i) => Container(
          width: 60,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(
              image: FileImage(File(_capturedImages[i])),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => setState(() => _capturedImages.removeAt(i)),
              child: Container(
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 60),
          GestureDetector(
            onTap: _takePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: _capturedImages.isNotEmpty 
              ? FloatingActionButton(
                  heroTag: 'btn_check',
                  onPressed: _isProcessing ? null : _analyzeTicket,
                  backgroundColor: Colors.green,
                  mini: true,
                  child: const Icon(Icons.check, size: 30),
                )
              : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
