import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
  static bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      if (Platform.isAndroid) {
         await _cameraController!.setFlashMode(FlashMode.off);
      }
      final XFile picture = await _cameraController!.takePicture();
      return picture.path;
    } catch (e) {
      debugPrint('Erreur takePicture: $e');
      return null;
    }
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
