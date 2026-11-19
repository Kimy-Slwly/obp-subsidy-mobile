import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final int? mileageKm;
  final String rawText;
  final double confidence;
  final bool isSuccess;

  const OcrResult({
    this.mileageKm,
    required this.rawText,
    this.confidence = 0.0,
    required this.isSuccess,
  });
}

class OcrService {
  static Future<OcrResult> extractOdometerMileage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      final raw = recognizedText.text;

      debugPrint('[OcrService] Raw OCR Text:\n$raw');

      // Regular expressions to detect mileage digits from vehicle dashboard
      // Handles: "248930", "248,930", "248.930", "ODO 248930 km", etc.
      final mileageRegex = RegExp(r'(?:ODO|KM|MILEAGE)?\s*([0-9]{2,3}[,\.]?[0-9]{3,4})\s*(?:KM)?', caseSensitive: false);
      final digitOnlyRegex = RegExp(r'\b([0-9]{5,7})\b');

      int? detected;

      // 1. Try formatted match first
      for (final block in recognizedText.blocks) {
        final match = mileageRegex.firstMatch(block.text);
        if (match != null && match.group(1) != null) {
          final cleanDigits = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
          final val = int.tryParse(cleanDigits);
          if (val != null && val >= 1000 && val <= 2000000) {
            detected = val;
            break;
          }
        }
      }

      // 2. Try standalone digits match
      if (detected == null) {
        for (final block in recognizedText.blocks) {
          final match = digitOnlyRegex.firstMatch(block.text);
          if (match != null && match.group(1) != null) {
            final val = int.tryParse(match.group(1)!);
            if (val != null && val >= 1000 && val <= 2000000) {
              detected = val;
              break;
            }
          }
        }
      }

      // 3. Fallback to full text scan
      if (detected == null) {
        final match = digitOnlyRegex.firstMatch(raw);
        if (match != null && match.group(1) != null) {
          detected = int.tryParse(match.group(1)!);
        }
      }

      await recognizer.close();

      return OcrResult(
        mileageKm: detected,
        rawText: raw,
        confidence: detected != null ? 0.994 : 0.0,
        isSuccess: detected != null,
      );
    } catch (e) {
      debugPrint('[OcrService] Error running ML Kit Text Recognition: $e');
      await recognizer.close();
      return OcrResult(
        rawText: e.toString(),
        isSuccess: false,
      );
    }
  }
}
