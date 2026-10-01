/// A GPS reading taken at a log moment.
class GeoFix {
  const GeoFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.mock,
    required this.at,
  });

  final double lat;
  final double lng;

  /// Estimated error radius in meters (smaller is better).
  final double accuracyM;

  /// True when Android reports the location came from a mock-location app.
  final bool mock;
  final DateTime at;
}

/// A photo (or, from M4, a video) captured in the app and saved on the phone.
class CapturedMedia {
  const CapturedMedia({
    required this.id,
    required this.type,
    required this.filePath,
    required this.sha256,
    required this.capturedAtDevice,
    required this.fix,
    this.durationSec,
    this.ocrText,
  });

  final String id;

  /// 'odometer', 'pump' or 'video'.
  final String type;

  /// Stored copy with EXIF removed. [sha256] is of exactly this file.
  final String filePath;
  final String sha256;
  final DateTime capturedAtDevice;
  final GeoFix fix;
  final int? durationSec;

  /// Raw OCR text from the framed area (photos only). Admin-only soft hint.
  final String? ocrText;
}
