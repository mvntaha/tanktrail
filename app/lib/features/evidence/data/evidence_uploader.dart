import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A stored evidence file waiting to be uploaded.
class PendingUpload {
  const PendingUpload({required this.mediaId, required this.logId, required this.type, required this.filePath});

  final String mediaId;
  final String logId;

  /// 'odometer' | 'pump' | 'video'
  final String type;

  /// Absolute path inside the app's documents folder (`evidence/<logId>/<file>`).
  final String filePath;

  bool get isVideo => type == 'video';
}

/// The outcome of one upload.
class UploadResult {
  const UploadResult.ok(this.mediaId, {required this.url, required this.publicId}) : error = null;
  const UploadResult.failed(this.mediaId, this.error)
      : url = null,
        publicId = null;

  final String mediaId;
  final String? url;
  final String? publicId;
  final String? error;
  bool get ok => error == null;
}

/// Uploads evidence somewhere and reports results. The rest of the app only
/// knows this interface, so Cloudinary could be swapped out later.
abstract class EvidenceUploader {
  /// Must be called once at app start, before [enqueue]. Reconnects to uploads
  /// that kept running (or finished) while the app was closed.
  Future<void> start();

  /// Starts uploads. Throws if signing fails (e.g. no internet); the caller
  /// retries later. Returns immediately; results arrive on [results].
  Future<void> enqueue(List<PendingUpload> items);

  /// True if the uploader still knows about this file's upload task.
  Future<bool> isActive(String mediaId);

  Stream<UploadResult> get results;
}

/// Cloudinary via signed uploads. The Worker (worker/) checks the Firebase
/// token and returns signed form fields; files go up with background_downloader,
/// which keeps uploading when the app is in the background and retries.
class CloudinaryUploader implements EvidenceUploader {
  CloudinaryUploader({required this.signerUrl, FirebaseAuth? auth, http.Client? client})
      : _auth = auth ?? FirebaseAuth.instance,
        _http = client ?? http.Client();

  final String signerUrl;
  final FirebaseAuth _auth;
  final http.Client _http;
  final _results = StreamController<UploadResult>.broadcast();
  static const _group = 'evidence';

  @override
  Stream<UploadResult> get results => _results.stream;

  @override
  Future<void> start() async {
    FileDownloader().updates.listen((update) {
      if (update is! TaskStatusUpdate || update.task.group != _group) return;
      final mediaId = update.task.taskId;
      switch (update.status) {
        case TaskStatus.complete:
          _results.add(_parseSuccess(mediaId, update.task.metaData, update.responseBody));
        case TaskStatus.failed || TaskStatus.notFound || TaskStatus.canceled:
          final body = update.responseBody ?? '';
          _results.add(UploadResult.failed(
            mediaId,
            '${update.status.name} ${update.responseStatusCode ?? ''} '
            '${update.exception?.description ?? ''} ${body.length > 200 ? body.substring(0, 200) : body}'
                .trim(),
          ));
        default:
          break; // enqueued / running / waitingToRetry: nothing to record
      }
    });
    // Tracks tasks in the downloader's own database and delivers results of
    // uploads that finished while the app was closed.
    await FileDownloader().start();
  }

  @override
  Future<bool> isActive(String mediaId) async =>
      (await FileDownloader().taskForId(mediaId)) != null;

  @override
  Future<void> enqueue(List<PendingUpload> items) async {
    for (var i = 0; i < items.length; i += 10) {
      final batch = items.sublist(i, i + 10 > items.length ? items.length : i + 10);
      final signed = await _sign(batch);
      for (final item in batch) {
        final s = signed[item.mediaId]!;
        final fields = (s['fields'] as Map).cast<String, String>();
        final rel = _relativeToDocuments(item.filePath);
        await FileDownloader().enqueue(UploadTask(
          taskId: item.mediaId,
          url: s['uploadUrl'] as String,
          baseDirectory: BaseDirectory.applicationDocuments,
          directory: rel.dir,
          filename: rel.file,
          fields: fields,
          group: _group,
          retries: 3,
          // Remember where it went, to build the URL even without a response body.
          metaData: jsonEncode({'publicId': fields['public_id'], 'uploadUrl': s['uploadUrl']}),
        ));
      }
    }
  }

  /// Asks the Worker for signed upload fields (needs internet).
  Future<Map<String, Map<String, dynamic>>> _sign(List<PendingUpload> batch) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final token = await user.getIdToken();
    final response = await _http
        .post(
          Uri.parse(signerUrl),
          headers: {'authorization': 'Bearer $token', 'content-type': 'application/json'},
          body: jsonEncode({
            'items': [
              for (final b in batch) {'logId': b.logId, 'mediaId': b.mediaId, 'kind': b.isVideo ? 'video' : 'image'},
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException('Signer said ${response.statusCode}: ${response.body}');
    }
    final items = (jsonDecode(response.body)['items'] as List).cast<Map<String, dynamic>>();
    return {for (final it in items) it['mediaId'] as String: it};
  }

  static ({String dir, String file}) _relativeToDocuments(String absolute) {
    final normalized = absolute.replaceAll('\\', '/');
    final i = normalized.indexOf('/evidence/');
    if (i < 0) throw ArgumentError('Not an evidence file: $absolute');
    final rel = normalized.substring(i + 1); // evidence/<logId>/<file>
    final cut = rel.lastIndexOf('/');
    return (dir: rel.substring(0, cut), file: rel.substring(cut + 1));
  }

  /// Cloudinary answers with JSON incl. secure_url. If the app was closed and
  /// the body was lost, the URL follows from the signed public_id.
  @visibleForTesting
  static UploadResult parseSuccess(String mediaId, String metaData, String? body) =>
      _parseSuccess(mediaId, metaData, body);

  static UploadResult _parseSuccess(String mediaId, String metaData, String? body) {
    final meta = jsonDecode(metaData) as Map<String, dynamic>;
    final publicId = meta['publicId'] as String;
    try {
      final json = jsonDecode(body ?? '') as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url != null) return UploadResult.ok(mediaId, url: url, publicId: (json['public_id'] as String?) ?? publicId);
    } catch (_) {
      // fall through to the derived URL
    }
    // https://api.cloudinary.com/v1_1/<cloud>/<image|video>/upload -> delivery URL
    final upload = Uri.parse(meta['uploadUrl'] as String);
    final cloud = upload.pathSegments[1];
    final kind = upload.pathSegments[2];
    return UploadResult.ok(
      mediaId,
      url: 'https://res.cloudinary.com/$cloud/$kind/upload/$publicId',
      publicId: publicId,
    );
  }
}
