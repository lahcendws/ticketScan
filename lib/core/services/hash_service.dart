// lib/core/services/hash_service.dart
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Fonction de haut niveau exécutable dans un isolate.
String _sha256Compute(String filePath) {
  final List<int> inputBytes = File(filePath).readAsBytesSync();
  final Digest digest = sha256.convert(inputBytes);
  return digest.toString();
}

class HashService {
  /// Calcule le SHA‑256 du fichier fourni, en arrière‑plan.
  // TODO: Fix isolate compute issue - for now, compute directly (blocks UI but works for testing)
  static Future<String> computeSha256(File file) async {
    final String hash = _sha256Compute(file.path);
    return Future.value(hash);
  }
}
