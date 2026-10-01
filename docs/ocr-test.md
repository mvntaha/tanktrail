# OCR test on owner samples (Milestone 4 start)

Date: 2026-10-01. Phone: Sparx Neo 7 Ultra (Android 12). Engine: google_mlkit_text_recognition 0.17.1
(Latin script, on-device). Test: `app/integration_test/ocr_samples_test.dart` (run with `--no-uninstall`).

| Sample | Truth | Full photo | LCD crop | Crop + 4x upscale, grayscale, contrast |
|---|---|---|---|---|
| image1.png (dashboard) | 113285 | no number | `25` | `11328S` (only the last 5 misread as S) |
| image2.png (dashboard) | 113270 | `1632 70` (one digit wrong) | `DL2E` | nothing |
| pump.png (blue LCD) | 4902.00 / 15.00 / 326.80 | `32680` (326.80 without the dot) | `B892E` | nothing |

**Exact matches: 0 of 5 values.** Near misses: 3.

Why: the samples are small, compressed photos. The odometer LCD is ~100 px wide (low-contrast segments),
the pump photo is 303x328 px and motion-blurred. In-app capture frames the display inside a guide box, so the
LCD will be ~8x larger in pixels; that should help, but it is NOT measured yet.

Conclusion: OCR cannot be relied on. Typed values stay the source of truth; OCR can at most be a soft admin hint,
compared leniently (S->5, O->0, I/l->1, B->8, decimal point ignored), and only after measuring it on real
in-app captures.
