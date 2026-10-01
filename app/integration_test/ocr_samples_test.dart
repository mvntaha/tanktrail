// On-phone OCR check of the owner's sample photos (docs/samples).
// The samples are copied into the debug app's private files folder (not bundled
// in the APK). Android 12 hides adb-pushed files in Android/data from the app,
// so they go via /data/local/tmp and `run-as`:
//
//   adb push docs/samples/image1.png docs/samples/image2.png docs/samples/pump.png /data/local/tmp/
//   adb shell "run-as com.tanktrail.app mkdir -p files/ocr && run-as com.tanktrail.app cp /data/local/tmp/*.png files/ocr/"
//   flutter test integration_test/ocr_samples_test.dart --no-uninstall
//   adb shell run-as com.tanktrail.app cat files/ocr_report.txt
//
// ALWAYS pass --no-uninstall: the default uninstalls the app and wipes local data.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Expected readings (read by eye from the photos) and the LCD box as
/// fractions of the image (left, top, right, bottom), measured on the samples.
const _samples = <String, ({List<String> expected, List<double> lcd})>{
  'image1.png': (expected: ['113285'], lcd: [0.475, 0.565, 0.575, 0.655]),
  'image2.png': (expected: ['113270'], lcd: [0.525, 0.580, 0.625, 0.665]),
  // Blue pump LCD: rupees, litres, price per litre (15.00 x 326.80 = 4902.00).
  'pump.png': (expected: ['4902.00', '15.00', '326.80'], lcd: [0.42, 0.19, 0.74, 0.58]),
};

img.Image _crop(img.Image src, List<double> box) {
  final x = (box[0] * src.width).round();
  final y = (box[1] * src.height).round();
  return img.copyCrop(src, x: x, y: y, width: ((box[2] - box[0]) * src.width).round(), height: ((box[3] - box[1]) * src.height).round());
}

/// What the app could do before OCR: enlarge, grayscale, stretch contrast.
img.Image _enhance(img.Image crop) {
  var out = img.copyResize(crop, width: crop.width * 4, interpolation: img.Interpolation.cubic);
  out = img.grayscale(out);
  out = img.normalize(out, min: 0, max: 255);
  return img.adjustColor(out, contrast: 1.6);
}

/// Numbers in the text, spaces removed ("113 285" -> "113285", "326. 80" -> "326.80").
List<String> _numbers(String text) => RegExp(r'\d[\d .,]*\d')
    .allMatches(text)
    .map((m) => m.group(0)!.replaceAll(' ', '').replaceAll(',', '.'))
    .toList();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OCR on owner sample photos', (tester) async {
    final base = await getApplicationSupportDirectory(); // = files/
    final dir = Directory('${base.path}/ocr');
    final tmp = await getTemporaryDirectory();
    final recognizer = TextRecognizer();
    final report = StringBuffer('OCR report (${DateTime.now()})\n');

    for (final entry in _samples.entries) {
      final file = File('${dir.path}/${entry.key}');
      if (!file.existsSync()) continue;
      final expected = entry.value.expected;
      final lcd = entry.value.lcd;
      final decoded = img.decodeImage(await file.readAsBytes())!;

      final crop = _crop(decoded, lcd);
      final cropPath = '${tmp.path}/${entry.key}_crop.png';
      final enhPath = '${tmp.path}/${entry.key}_enhanced.png';
      await File(cropPath).writeAsBytes(img.encodePng(crop));
      await File(enhPath).writeAsBytes(img.encodePng(_enhance(crop)));
      // Keep copies next to the samples so they can be pulled and inspected.
      await File(cropPath).copy('${base.path}/out_${entry.key}_crop.png');
      await File(enhPath).copy('${base.path}/out_${entry.key}_enhanced.png');
      final variants = {'full photo': file.path, 'LCD crop': cropPath, 'LCD crop + enhanced': enhPath};

      for (final v in variants.entries) {
        final result = await recognizer.processImage(InputImage.fromFilePath(v.value));
        final text = result.text.replaceAll('\n', ' | ');
        final numbers = _numbers(result.text);
        final found = expected.where(numbers.contains).toList();
        final verdict = '${found.length}/${expected.length} matched';
        report.writeln('${entry.key} [${v.key}] expected=$expected -> $verdict | numbers=$numbers | text="$text"');
      }
    }

    await recognizer.close();
    // ignore: avoid_print
    print(report);
    await File('${base.path}/ocr_report.txt').writeAsString(report.toString());
  });
}
