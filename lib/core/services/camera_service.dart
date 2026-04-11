import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
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
        // Utiliser ResolutionPreset.medium pour une meilleure compatibilité avec l'émulateur
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg, // Forcer le format JPEG
        );
        await _cameraController!.initialize();
      }
    } catch (e) {
      debugPrint('Erreur initialisation caméra: $e');
    }
  }

  // Obtenir le contrôleur de caméra
  static CameraController? get cameraController => _cameraController;

  // Vérifier si la caméra est initialisée
  static bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  // Demander les permissions de caméra
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Prendre une photo
  static Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Caméra non prête pour takePicture');
      return null;
    }

    try {
      // S'assurer que le flash est éteint sur l'émulateur pour éviter les crashs
      if (Platform.isAndroid) {
         await _cameraController!.setFlashMode(FlashMode.off);
      }

      final XFile picture = await _cameraController!.takePicture();
      return picture.path;
    } catch (e) {
      debugPrint('Erreur lors de l\'appel natif takePicture: $e');
      return null;
    }
  }

  // Choisir une image depuis la galerie
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Erreur sélection image: $e');
      return null;
    }
  }

  // Basculer entre les caméras
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

  // Activer/Désactiver le flash
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

  // Libérer les ressources
  static Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
