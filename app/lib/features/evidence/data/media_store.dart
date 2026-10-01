import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final mediaStoreProvider = Provider<MediaStore>((ref) => MediaStore());

/// Keeps evidence files in the app's private storage (not the gallery).
class MediaStore {
  Future<Directory> _dirFor(String logId) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory('${base.path}/evidence/$logId').create(recursive: true);
  }

  /// Re-encodes a camera JPEG into evidence storage: upright, max ~1920px,
  /// and with ALL EXIF removed (no GPS or device data leaks into the file).
  /// Returns the stored file and its SHA-256.
  Future<({String path, String sha256})> storePhoto({
    required String sourcePath,
    required String logId,
    required String mediaId,
  }) async {
    final dir = await _dirFor(logId);
    final target = '${dir.path}/$mediaId.jpg';
    final out = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target,
      quality: 88, // odometer digits must stay sharp
      minWidth: 1920,
      minHeight: 1920,
      keepExif: false,
    );
    if (out == null) throw const FileSystemException('Could not save the photo');
    // The camera's temporary original still has EXIF; remove it.
    try {
      await File(sourcePath).delete();
    } on FileSystemException {
      // Only a temp file; the OS clears its cache folder eventually anyway.
    }
    return (path: out.path, sha256: await sha256OfFile(out.path));
  }

  /// Streams the file through the hash so large videos (M4) don't fill memory.
  static Future<String> sha256OfFile(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }
}
