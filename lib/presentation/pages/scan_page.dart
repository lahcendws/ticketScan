import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/subscription_service.dart';
import 'package:ticketscan_new/core/services/hash_service.dart';
import '../../core/services/offline_hash_queue.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/ticket_provider.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/ticket_analysis_dialog.dart';
import 'premium_page.dart';

class ScanPage extends StatefulWidget {
  final String? initialImagePath;

  const ScanPage({super.key, this.initialImagePath});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final List<String> _capturedImages = [];
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _showGuide = true;
  final Map<String, Map<String, dynamic>> _hashProofs = {};
  Timer? _hashQueueTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _capturedImages.add(widget.initialImagePath!);
    }
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initHashQueue();
      _hashQueueTimer = Timer.periodic(const Duration(seconds: 30), (timer) => processHashQueue());
    });
    Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showGuide = false);
    });
  }

  Future<void> _initializeCamera() async {
    await CameraService.initialize();
    if (mounted) setState(() => _isInitialized = CameraService.isInitialized);
  }

  Future<void> _takePhoto() async {
    final path = await CameraService.takePicture(saveAsPng: true);
    if (path != null) {
      setState(() => _capturedImages.add(path));
    }
  }

  Future<void> _pickImage() async {
    final path = await CameraService.pickImageFromGallery();
    if (path != null) {
      final pngPath = await CameraService.convertToPng(path);
      if (mounted) {
        setState(() => _capturedImages.add(pngPath));
      }
    }
  }

  Future<void> _analyzeTicket() async {
    if (_capturedImages.isEmpty) return;

    final sub = Provider.of<SubscriptionService>(context, listen: false);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    if (!sub.isPremium && !sub.canScan(provider.tickets)) {
      _redirectToPremium();
      return;
    }

    await CameraService.cameraController?.pausePreview();
    setState(() => _isProcessing = true);
    try {
      final analysis = await OCRService.extractTextFromImages(_capturedImages);
      setState(() => _isProcessing = false);
      if (!mounted) return;

      // Compute hash and store proof
      final proofs = <String, Map<String, dynamic>>{};
      for (final imgPath in _capturedImages) {
        final file = File(imgPath);
        final hash = await HashService.computeSha256(file);
        try {
          final supabaseRow = await SupabaseService.storeHash(hash);
          proofs[imgPath] = {
            'hash': hash,
            'timestamp': supabaseRow['created_at'],
            'supabaseRowId': supabaseRow['id'],
          };
        } catch (e) {
          await enqueueHash(imgPath, hash);
          proofs[imgPath] = {
            'hash': hash,
            'timestamp': null,
            'supabaseRowId': null,
          };
        }
      }
      setState(() => _hashProofs.addAll(proofs));

      final finalAnalysis = await showDialog<TicketAnalysis>(
        context: context,
        builder: (context) => TicketAnalysisDialog(
          analysis: analysis,
          imagePath: _capturedImages.first,
          // Optionally pass proofs to dialog if needed
        ),
      );

      if (finalAnalysis != null && mounted) {
        await _saveTicket(finalAnalysis);
      } else {
        if (mounted) await CameraService.cameraController?.resumePreview();
      }
    } on NotAReceiptException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        await CameraService.cameraController?.resumePreview();
        _showErrorDialog(e.messageKey);
      }
    } on QuotaExceededException catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        await CameraService.cameraController?.resumePreview();
        _redirectToPremium();
      }
    } on ScanTechnicalException catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        await CameraService.cameraController?.resumePreview();
        _showErrorDialog(e.messageKey);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        await CameraService.cameraController?.resumePreview();
        _showErrorDialog('scan_unexpected_error');
      }
    }
  }

  Future<void> _saveTicket(TicketAnalysis analysis) async {
    setState(() => _isProcessing = true);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    try {
      final List<String> urls = await Future.wait(
        _capturedImages.map(
          (path) => SupabaseService.uploadTicketImage(
            path,
            'ticket_${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}.png',
          ),
        ),
      );
      final List<Map<String, dynamic>> proofList = _capturedImages.map((path) {
        final proof = _hashProofs[path] ?? {};
        return {
          'imagePath': path,
          'hash': proof['hash'],
          'timestamp': proof['timestamp'],
          'supabaseRowId': proof['supabaseRowId'],
        };
      }).toList();
      final ticket = TicketModel(
        storeName: analysis.storeName,
        storeAddress: analysis.storeAddress,
        category: analysis.category,
        date: analysis.date,
        totalAmount: analysis.totalAmount,
        currency: analysis.currency,
        products: analysis.products,
        imageUrls: urls,
        warrantyEndDate: analysis.date.add(
          Duration(days: analysis.warrantyYears * 365),
        ),
        createdAt: DateTime.now(),
        hashProofs: proofList,
      );
      await ticketProvider.addTicket(ticket);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (e.toString().contains('LIMIT_REACHED')) {
          _redirectToPremium();
        } else {
          _showErrorDialog('scan_save_error');
        }
      }
    }
  }

  void _redirectToPremium() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PremiumPage()),
    );
  }

  void _showErrorDialog(String messageKey) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(loc?.get('scan_error_title') ?? 'Scan error'),
          content: Text(loc?.get(messageKey) ?? messageKey),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(loc?.get('ok') ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubscriptionService>(context);
    final provider = Provider.of<TicketProvider>(context);
    final canScan = sub.isPremium || sub.canScan(provider.tickets);

    if (!_isInitialized && _capturedImages.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            Positioned.fill(
              child: CameraPreview(CameraService.cameraController!),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(flex: 2),
                _buildImagePreviewList(),
                const Spacer(),
                _buildBottomControls(canScan),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(child: SizedBox.shrink()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_capturedImages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewList() {
    if (_capturedImages.isEmpty) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, i) => Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            image: DecorationImage(
              image: FileImage(File(_capturedImages[i])),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _capturedImages.removeAt(i)),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool canScan) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlWidth = constraints.maxWidth / 3;
        final scale = (controlWidth / 70).clamp(0.0, 1.0).toDouble();
        final analyzeButton = _capturedImages.isNotEmpty
            ? ElevatedButton(
                onPressed: _isProcessing ? null : _analyzeTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing
                      ? Colors.grey
                      : (canScan ? Colors.green : Colors.orange),
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 12 * scale,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? SizedBox(
                        width: 20 * scale,
                        height: 20 * scale,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        canScan ? Icons.check : Icons.lock,
                        size: 24 * scale,
                      ),
              )
            : const SizedBox();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: controlWidth,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 32 * scale,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: controlWidth,
                  child: GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: controlWidth,
                      height: controlWidth,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3 * scale,
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(6 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: controlWidth,
                  child: FittedBox(fit: BoxFit.scaleDown, child: analyzeButton),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  void dispose() {
    _hashQueueTimer?.cancel();
    super.dispose();
  }
}
