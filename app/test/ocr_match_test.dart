import 'package:flutter_test/flutter_test.dart';
import 'package:tanktrail/features/evidence/domain/ocr_match.dart';

void main() {
  group('ocrNumbers (real outputs from docs/ocr-test.md)', () {
    test('maps look-alikes inside numeric words only', () {
      expect(ocrNumbers('11328S'), ['113285']);
      expect(ocrNumbers('32680 | LTRES'), ['32680']);
      expect(ocrNumbers('RUPEES\nLITRES'), isEmpty);
      expect(ocrNumbers('DL2E'), isEmpty);
    });
    test('joins digit groups split by spaces or dots', () {
      expect(ocrNumbers('113 285'), ['113285']);
      expect(ocrNumbers('326. 80'), ['32680']);
    });
  });

  group('compareOcr', () {
    test('odometer: lenient match', () {
      expect(compareOcr('11328S', 113285, decimals: false), OcrVerdict.match);
      expect(compareOcr('1632 70', 113270, decimals: false), OcrVerdict.mismatch);
      expect(compareOcr('25', 113285, decimals: false), OcrVerdict.unreadable);
      expect(compareOcr(null, 113285, decimals: false), OcrVerdict.unreadable);
    });
    test('pump: decimal point dropped by OCR still matches', () {
      expect(compareOcr('32680 | LTRES', 326.8, decimals: true), OcrVerdict.match);
      expect(compareOcr('4902.00', 4902, decimals: true), OcrVerdict.match);
      expect(compareOcr('490200', 4902, decimals: true), OcrVerdict.match);
      expect(compareOcr('4902', 4902, decimals: true), OcrVerdict.match); // trailing zeros not shown
      expect(compareOcr('4802.00', 4902, decimals: true), OcrVerdict.mismatch);
    });
  });
}
