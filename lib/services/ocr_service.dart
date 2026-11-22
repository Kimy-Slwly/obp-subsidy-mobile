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
  /// Robust Odometer OCR extraction with strict resource cleanup
  static Future<OcrResult> extractOdometerMileage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('[OcrService] Image file does not exist: $imagePath');
        return const OcrResult(
          rawText: 'Image file not found',
          isSuccess: false,
        );
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      final raw = recognizedText.text;

      debugPrint('[OcrService] Raw OCR Text:\n$raw');

      // Regular expressions to detect mileage digits from vehicle dashboard
      // Handles: "248930", "248,930", "248.930", "ODO 248930 km", etc.
      final mileageRegex = RegExp(r'(?:ODO|KM|MILEAGE)?\s*([0-9]{2,3}[,\.]?[0-9]{3,4})\s*(?:KM)?', caseSensitive: false);
      final digitOnlyRegex = RegExp(r'\b([0-9]{5,7})\b');

      int? detected;
      String detectionSource = 'none';

      // 1. Try formatted match first (e.g. "ODO 248930 km", "TOTAL 248930")
      for (final block in recognizedText.blocks) {
        final match = mileageRegex.firstMatch(block.text);
        if (match != null && match.group(1) != null) {
          final cleanDigits = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
          final val = int.tryParse(cleanDigits);
          if (val != null && val >= 1000 && val <= 2000000) {
            detected = val;
            detectionSource = 'labeled_context';
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
              detectionSource = 'block_digits';
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
          detectionSource = 'raw_fallback';
        }
      }

      // Dynamic Confidence Calculation based on ML Kit text extraction clarity:
      double dynamicConfidence = 0.0;
      if (detected != null) {
        final digitsStr = detected.toString();
        double score = 0.55; // Base score for detecting valid numeric range

        // Contextual label boost ("ODO", "KM", "TOTAL")
        if (detectionSource == 'labeled_context' ||
            raw.toUpperCase().contains('ODO') ||
            raw.toUpperCase().contains('KM')) {
          score += 0.25;
        }

        // Standard heavy commercial lorry odometer length (5 or 6 digits)
        if (digitsStr.length >= 5 && digitsStr.length <= 6) {
          score += 0.15;
        }

        // Signal-to-noise ratio check
        final int digitCount = raw.replaceAll(RegExp(r'[^0-9]'), '').length;
        final int totalLength = raw.trim().length;
        if (totalLength > 0 && (digitCount / totalLength) >= 0.25) {
          score += 0.04;
        }

        dynamicConfidence = score.clamp(0.40, 0.99);
      }

      return OcrResult(
        mileageKm: detected,
        rawText: raw,
        confidence: dynamicConfidence,
        isSuccess: detected != null,
      );
    } catch (e) {
      debugPrint('[OcrService] Error running ML Kit Text Recognition: $e');
      return OcrResult(
        rawText: e.toString(),
        isSuccess: false,
      );
    } finally {
      // Ensure the native C++ TextRecognizer engine is always closed and memory freed
      try {
        await recognizer.close();
      } catch (e) {
        debugPrint('[OcrService] Error closing recognizer in finally block: $e');
      }
    }
  }
}
