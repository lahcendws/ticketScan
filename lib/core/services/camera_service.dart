import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class CameraService {
  static CameraController? _cameraController;
  static List<CameraDescription>? _cameras;
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Amélioré : Qualité Medium pour une meilleure reconnaissance OCR
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint('Erreur initialisation caméra: $e');
    }
  }

  static CameraController? get cameraController => _cameraController;
  static bool get isInitialized =>
      _cameraController?.value.isInitialized ?? false;

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<String?> takePicture({bool saveAsPng = false}) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      if (Platform.isAndroid) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
      final XFile picture = await _cameraController!.takePicture();
      final String srcPath = picture.path;

      if (!saveAsPng) return srcPath;

      // ---- Convert to PNG -------------------------------------------------
      final String pngPath = await convertToPng(srcPath);
      return pngPath;
    } catch (e) {
      debugPrint('Erreur takePicture: $e');
      return null;
    }
  }

  static Future<String> convertToPng(String srcPath) async {
    final File srcFile = File(srcPath);
    final List<int> jpgBytes = await srcFile.readAsBytes();
    final img.Image? jpgImg = img.decodeImage(Uint8List.fromList(jpgBytes));
    if (jpgImg == null) {
      throw Exception('Failed to decode image for PNG conversion');
    }
    final List<int> pngBytes = img.encodePng(jpgImg);
    final String pngPath = srcPath.replaceFirst(RegExp(r'\.(jpe?g)$'), '.png');
    final File pngFile = File(pngPath)..writeAsBytesSync(pngBytes, flush: true);
    // Optionally delete the original JPEG to save space
    await srcFile.delete();
    return pngFile.path;
  }

  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      return null;
    }
  }

  static Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
