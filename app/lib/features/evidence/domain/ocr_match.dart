/// Lenient comparison of a typed value with OCR text. Used only as a soft,
/// admin-side hint (see docs/ocr-test.md: OCR misses a lot on these displays).
enum OcrVerdict {
  /// OCR read the same number.
  match,

  /// OCR read a number, but not this one. Worth a look; not proof of anything.
  mismatch,

  /// OCR found no usable number. Says nothing about the log.
  unreadable,
}

// Typical 7-segment / LCD misreads.
const _lookalikes = {
  'O': '0', 'D': '0', 'Q': '0', 'U': '0',
  'I': '1', 'L': '1', '|': '1', '!': '1', 'T': '1',
  'Z': '2', 'S': '5', 'G': '6', 'B': '8', 'E': '8',
};

/// Digit runs (3+ digits) in OCR text. Look-alike letters are mapped only inside
/// words that are already mostly digits ("11328S" -> "113285"), so labels like
/// "RUPEES" never turn into numbers. Spaces, dots and commas inside a number
/// are dropped: "113 285" -> "113285", "326. 80" -> "32680".
List<String> ocrNumbers(String ocrText) {
  final runs = <String>[];
  for (final line in ocrText.toUpperCase().split(RegExp(r'[\n|]'))) {
    final words = line.trim().split(RegExp(r'\s+')).map((w) {
      final digits = w.replaceAll(RegExp(r'[^0-9]'), '').length;
      final numeric = digits >= 2 && digits * 2 >= w.length;
      return numeric ? w.split('').map((c) => _lookalikes[c] ?? c).join() : w;
    });
    for (final m in RegExp(r'\d(?:[\d.,]|\s(?=\d))*\d').allMatches(words.join(' '))) {
      final digits = m.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length >= 3) runs.add(digits);
    }
  }
  return runs;
}

/// Digits of a typed value as a display would show it: integers as-is,
/// decimals with exactly 2 places ("326.8" -> "32680", "15" with decimals -> "1500").
String typedDigits(num value, {required bool decimals}) {
  final s = decimals ? value.toStringAsFixed(2) : value.round().toString();
  return s.replaceAll(RegExp(r'[^\d]'), '');
}

OcrVerdict compareOcr(String? ocrText, num typed, {required bool decimals}) {
  if (ocrText == null) return OcrVerdict.unreadable;
  final numbers = ocrNumbers(ocrText);
  if (numbers.isEmpty) return OcrVerdict.unreadable;
  final want = typedDigits(typed, decimals: decimals);
  // Pumps often drop the decimal point and sometimes trailing zeros.
  final wantShort = decimals ? want.replaceFirst(RegExp(r'0+$'), '') : want;
  final hit = numbers.any((n) => n == want || (decimals && n == wantShort));
  return hit ? OcrVerdict.match : OcrVerdict.mismatch;
}
