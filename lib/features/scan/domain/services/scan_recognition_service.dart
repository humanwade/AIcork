import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/scan_recognition_result.dart';

class ScanRecognitionService {
  Future<ScanRecognitionResult> recognize(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) return const ScanRecognitionResult();

    final inputImage = InputImage.fromFilePath(imagePath);

    // 1) Barcode first
    final barcodeScanner = BarcodeScanner();
    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      final raw = barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (raw.isNotEmpty) {
        return ScanRecognitionResult(barcode: raw.first);
      }
    } finally {
      await barcodeScanner.close();
    }

    // 2) OCR fallback
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final text = await recognizer.processImage(inputImage);
      final candidate = _guessProductName(text.text);
      return ScanRecognitionResult(productName: candidate);
    } finally {
      await recognizer.close();
    }
  }

  String? _guessProductName(String raw) {
    final lines = raw
        .replaceAll('\r', '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length >= 4)
        .where((l) => RegExp(r'[A-Za-z]').hasMatch(l))
        .where((l) => !RegExp(r'^\d+$').hasMatch(l))
        .toList();
    if (lines.isEmpty) return null;

    // Prefer a longer, title-like line
    lines.sort((a, b) => b.length.compareTo(a.length));
    return lines.first.length > 60 ? lines.first.substring(0, 60) : lines.first;
  }
}

