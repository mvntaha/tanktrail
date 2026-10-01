import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final s = OcrService();
  ref.onDispose(s.close);
  return s;
});

/// On-device OCR (no internet needed). Result is a soft admin hint only;
/// it never blocks a log and drivers never see it.
class OcrService {
  final _recognizer = TextRecognizer();

  /// Reads the framed area of [photoPath]. [box] is the framing guide as
  /// fractions (left, top, right, bottom). Tries the plain crop and an
  /// enlarged high-contrast version (which did better in docs/ocr-test.md).
  /// Returns the raw text of both passes, or null if nothing was read.
  Future<String?> read(String photoPath, List<double> box) async {
    try {
      final tmp = (await getTemporaryDirectory()).path;
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final cropPath = '$tmp/ocr_${stamp}_crop.png';
      final enhPath = '$tmp/ocr_${stamp}_enh.png';
      // Image work off the UI thread so the screen doesn't stutter.
      await Isolate.run(() => _prepare(photoPath, box, cropPath, enhPath));

      final texts = <String>[];
      for (final p in [cropPath, enhPath]) {
        final t = (await _recognizer.processImage(InputImage.fromFilePath(p))).text.trim();
        if (t.isNotEmpty) texts.add(t);
        File(p).delete().ignore();
      }
      return texts.isEmpty ? null : texts.join('\n');
    } catch (e) {
      debugPrint('OCR skipped: $e');
      return null;
    }
  }

  Future<void> close() => _recognizer.close();
}

void _prepare(String src, List<double> box, String cropPath, String enhPath) {
  final image = img.decodeImage(File(src).readAsBytesSync())!;
  // Widen the guide box by 10% each side: framing is never exact.
  final l = ((box[0] - 0.1 * (box[2] - box[0])).clamp(0.0, 1.0) * image.width).round();
  final t = ((box[1] - 0.1 * (box[3] - box[1])).clamp(0.0, 1.0) * image.height).round();
  final r = ((box[2] + 0.1 * (box[2] - box[0])).clamp(0.0, 1.0) * image.width).round();
  final b = ((box[3] + 0.1 * (box[3] - box[1])).clamp(0.0, 1.0) * image.height).round();
  final crop = img.copyCrop(image, x: l, y: t, width: r - l, height: b - t);
  File(cropPath).writeAsBytesSync(img.encodePng(crop));

  // Enlarge small crops to ~1600px wide, then grayscale + contrast stretch.
  final scale = (1600 / crop.width).clamp(1.0, 4.0);
  var enh = img.copyResize(crop, width: (crop.width * scale).round(), interpolation: img.Interpolation.cubic);
  enh = img.normalize(img.grayscale(enh), min: 0, max: 255);
  enh = img.adjustColor(enh, contrast: 1.6);
  File(enhPath).writeAsBytesSync(img.encodePng(enh));
}
