import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/captured_media.dart';

/// Saves one captured photo/video row for a trip or fuel log. Call inside the
/// same transaction as the log itself, so a log never exists without its evidence.
Future<void> insertEvidence(
  AppDatabase db, {
  required String logId,
  required String logKind,
  required String phase,
  required CapturedMedia media,
}) {
  return db.into(db.localEvidence).insert(LocalEvidenceCompanion.insert(
        id: media.id,
        logId: logId,
        logKind: logKind,
        phase: phase,
        type: media.type,
        filePath: media.filePath,
        sha256: media.sha256,
        capturedAtDevice: media.capturedAtDevice,
        lat: media.fix.lat,
        lng: media.fix.lng,
        acc: media.fix.accuracyM,
        mock: media.fix.mock,
        durationSec: Value(media.durationSec),
        ocrText: Value(media.ocrText),
      ));
}
