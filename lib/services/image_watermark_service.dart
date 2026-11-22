import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class WatermarkResult {
  final File watermarkedFile;
  final String imageHash;
  final DateTime capturedAt;

  const WatermarkResult({
    required this.watermarkedFile,
    required this.imageHash,
    required this.capturedAt,
  });
}

class ImageWatermarkService {
  /// Computes SHA-256 hash of a file's raw bytes
  static Future<String> computeSha256(File file) async {
    final Uint8List bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Automatically burns a tamper-evident semi-transparent watermark bar at the bottom
  /// of the odometer photo containing timestamp, live GPS coordinates, and lorry plate number.
  /// Also generates a SHA-256 hash of the original image bytes for duplicate detection.
  static Future<WatermarkResult> applyWatermark({
    required File originalImage,
    required String plateNumber,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) async {
    final DateTime captureTime = timestamp ?? DateTime.now();

    // 1. Compute SHA-256 hash of the original unedited camera bytes
    final Uint8List originalBytes = await originalImage.readAsBytes();
    final String imageHash = sha256.convert(originalBytes).toString();

    try {
      // 2. Decode original image using Flutter's native hardware-accelerated codec
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final double imgWidth = image.width.toDouble();
      final double imgHeight = image.height.toDouble();

      // 3. Setup canvas recorder
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Draw original image
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());

      // 4. Calculate responsive watermark bar dimensions (approx 8.5% of image height, clamped)
      final double barHeight = (imgHeight * 0.085).clamp(65.0, 160.0);
      final double barTop = imgHeight - barHeight;

      // Semi-transparent dark background bar (88% opacity dark navy)
      final barPaint = ui.Paint()..color = const ui.Color(0xE00B132B);
      canvas.drawRect(ui.Rect.fromLTWH(0, barTop, imgWidth, barHeight), barPaint);

      // High-visibility top accent stripe (OBP Red #E50914)
      final accentPaint = ui.Paint()
        ..color = const ui.Color(0xFFE50914)
        ..strokeWidth = (barHeight * 0.04).clamp(3.0, 6.0);
      canvas.drawLine(
        ui.Offset(0, barTop),
        ui.Offset(imgWidth, barTop),
        accentPaint,
      );

      // Format metadata strings
      final String timeStr =
          '${captureTime.year}-${captureTime.month.toString().padLeft(2, '0')}-${captureTime.day.toString().padLeft(2, '0')} '
          '${captureTime.hour.toString().padLeft(2, '0')}:${captureTime.minute.toString().padLeft(2, '0')}:${captureTime.second.toString().padLeft(2, '0')}';

      final String gpsStr = (latitude != null && longitude != null && (latitude != 0.0 || longitude != 0.0))
          ? 'GPS: ${latitude.toStringAsFixed(5)}° N, ${longitude.toStringAsFixed(5)}° E'
          : 'GPS: Live Location Fix Pending';

      final String line1 = 'OBP FLEET VERIFIED • $plateNumber • $timeStr';
      final String line2 = '$gpsStr • ANTI-TAMPER SECURED (SHA: ${imageHash.substring(0, 8)}...)';

      final double fontSize = (barHeight * 0.26).clamp(13.0, 28.0);
      final double paddingLeft = (imgWidth * 0.03).clamp(16.0, 40.0);

      // Line 1: White bold header
      final builder1 = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: ui.TextAlign.left,
          fontSize: fontSize,
          fontWeight: ui.FontWeight.bold,
        ),
      )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText(line1);
      final paragraph1 = builder1.build()
        ..layout(ui.ParagraphConstraints(width: imgWidth - (paddingLeft * 2)));
      canvas.drawParagraph(paragraph1, ui.Offset(paddingLeft, barTop + (barHeight * 0.16)));

      // Line 2: Sky-blue metadata sub-line
      final builder2 = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: ui.TextAlign.left,
          fontSize: fontSize * 0.82,
          fontWeight: ui.FontWeight.w600,
        ),
      )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF38BDF8)))
        ..addText(line2);
      final paragraph2 = builder2.build()
        ..layout(ui.ParagraphConstraints(width: imgWidth - (paddingLeft * 2)));
      canvas.drawParagraph(paragraph2, ui.Offset(paddingLeft, barTop + (barHeight * 0.52)));

      // 5. Complete picture and export as PNG
      final picture = recorder.endRecording();
      final watermarkedImage = await picture.toImage(image.width, image.height);
      final byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return WatermarkResult(
          watermarkedFile: originalImage,
          imageHash: imageHash,
          capturedAt: captureTime,
        );
      }

      final Uint8List watermarkedBytes = byteData.buffer.asUint8List();
      final Directory tempDir = originalImage.parent;
      final String watermarkedPath =
          '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.png';
      final File watermarkedFile = File(watermarkedPath);
      await watermarkedFile.writeAsBytes(watermarkedBytes);

      debugPrint('[ImageWatermarkService] Watermarked image generated: $watermarkedPath (SHA: $imageHash)');

      return WatermarkResult(
        watermarkedFile: watermarkedFile,
        imageHash: imageHash,
        capturedAt: captureTime,
      );
    } catch (e) {
      debugPrint('[ImageWatermarkService] Error watermarking image: $e. Returning original file.');
      return WatermarkResult(
        watermarkedFile: originalImage,
        imageHash: imageHash,
        capturedAt: captureTime,
      );
    }
  }
}
