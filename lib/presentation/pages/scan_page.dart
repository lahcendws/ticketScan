import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/app_localizations.dart';
import '../../data/models/ticket_model.dart';
import '../widgets/ticket_analysis_dialog.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<String> _capturedImages = [];
  bool _isProcessing = false;
  // Déclaration de la variable manquante
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Initialisation sécurisée
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

    // Pause la caméra pour éviter les conflits pendant le dialogue
    await CameraService.cameraController?.pausePreview();
    setState(() => _isProcessing = true);

    final analysis = await OCRService.extractTextFromImage(_capturedImages.first);

    setState(() => _isProcessing = false);

    final finalAnalysis = await showDialog<TicketAnalysis>(
      context: context,
      builder: (context) => TicketAnalysisDialog(
          analysis: analysis,
          imagePath: _capturedImages.first
      ),
    );

    if (finalAnalysis != null && mounted) {
      await _saveTicket(finalAnalysis);
    }
  }

  Future<void> _saveTicket(TicketAnalysis analysis) async {
    setState(() => _isProcessing = true);

    final List<String> urls = await Future.wait(
        _capturedImages.map((path) =>
            SupabaseService.uploadTicketImage(path, 'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg')
        )
    );

    final ticket = TicketModel(
      storeName: analysis.storeName,
      date: analysis.date,
      totalAmount: analysis.totalAmount,
      products: analysis.products,
      imageUrls: urls,
      warrantyEndDate: analysis.date.add(Duration(days: analysis.warrantyYears * 365)),
      createdAt: DateTime.now(),
    );

    await SupabaseService.addTicket(ticket.toMap());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Condition explicite pour éviter l'écran blanc pendant l'init
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Scanner (${_capturedImages.length})')),
      body: Column(
        children: [
          // AJOUT : La prévisualisation de la caméra
          SizedBox(
            height: 300,
            child: CameraPreview(CameraService.cameraController!),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _capturedImages.length,
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_capturedImages[i]), fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(heroTag: 'btn_gallery',onPressed: _takePhoto, child: const Icon(Icons.camera_alt)),
                if (_capturedImages.isNotEmpty)
                  FloatingActionButton(
                      heroTag: 'btn_check',
                      onPressed: _isProcessing ? null : _analyzeTicket,
                      backgroundColor: Colors.green,
                      child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check)
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}