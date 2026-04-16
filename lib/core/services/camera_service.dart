import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class CameraService {
  static CameraController? _cameraController;
  static List<CameraDescription>? _cameras;
  static final ImagePicker _imagePicker = ImagePicker();

  // Initialiser les caméras
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // ResolutionPreset.medium (souvent 720p ou 480p) est idéal pour l'OCR sans saturer la mémoire
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.low,
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

  // Prendre une photo
  static Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Erreur: CameraController non initialisé');
      return null;
    }

    try {
      if (Platform.isAndroid) {
         await _cameraController!.setFlashMode(FlashMode.off);
      }

      final XFile picture = await _cameraController!.takePicture();
      debugPrint('Photo prise avec succès: ${picture.path}');
      return picture.path;
    } catch (e) {
      debugPrint('Erreur takePicture: $e');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      
      // Tenter de réinitialiser la caméra en cas d'erreur
      try {
        await _cameraController?.dispose();
        if (_cameras != null && _cameras!.isNotEmpty) {
          _cameraController = CameraController(
            _cameras!.first,
            ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await _cameraController!.initialize();
          debugPrint('Caméra réinitialisée avec succès');
        }
      } catch (reinitError) {
        debugPrint('Échec de réinitialisation: $reinitError');
      }
      return null;
    }
  }

  // Choisir une image depuis la galerie avec redimensionnement agressif
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Réduit pour éviter WORKER_LIMIT dans Supabase
        maxHeight: 1024,
        imageQuality: 70, // Qualité réduite pour économiser la mémoire
      );
      return image?.path;
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      return null;
    }
  }

  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCameraIndex = _cameras!.indexOf(_cameraController!.description);
    final nextCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![nextCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
  }

  static Future<void> toggleFlash() async {
    if (_cameraController == null) return;
    try {
      if (_cameraController!.value.flashMode == FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint('Erreur flash: $e');
    }
  }

  static FlashMode get flashMode => _cameraController?.value.flashMode ?? FlashMode.off;

  static Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
