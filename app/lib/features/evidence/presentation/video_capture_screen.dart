import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ids.dart';
import '../data/location_service.dart';
import '../data/media_store.dart';
import '../domain/captured_media.dart';

/// In-app pump video, up to [maxSeconds]. No audio (privacy, and not needed).
/// Pops with a [CapturedMedia] of type 'video'. Call [ensureLocation] first.
class VideoCaptureScreen extends ConsumerStatefulWidget {
  const VideoCaptureScreen({super.key, required this.logId});

  final String logId;
  static const maxSeconds = 60;

  @override
  ConsumerState<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends ConsumerState<VideoCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _torch = false;
  bool _recording = false;
  bool _busy = false;
  int _seconds = 0;
  Timer? _timer;
  DateTime? _startedAt;
  Future<GeoFix?>? _fixFuture;
  late final GpsWarmup _gps = GpsWarmup(ref.read(locationServiceProvider));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gps.start(); // fix ready when recording starts
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _gps.stop();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive && c != null) {
      // Leaving the app mid-recording discards it; the driver records again.
      _timer?.cancel();
      _gps.stop();
      _controller = null;
      c.dispose();
      if (mounted) setState(() => _recording = false);
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _gps.start();
      _init();
    }
  }

  Future<CameraController> _open(CameraDescription cam, {required bool lowFps}) async {
    final c = CameraController(
      cam,
      ResolutionPreset.high, // 720p
      enableAudio: false,
      // Small files for slow uploads: ~1.5 Mbps at 15 fps is ~11 MB a minute.
      fps: lowFps ? 15 : null,
      videoBitrate: 1500000,
    );
    await c.initialize();
    return c;
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      CameraController c;
      try {
        c = await _open(back, lowFps: true);
      } on CameraException {
        // Some phones reject a fixed 15 fps range; fall back to their default.
        c = await _open(back, lowFps: false);
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _error = null;
      });
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'Camera could not start (${e.code}).');
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    final on = !_torch;
    await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    setState(() => _torch = on);
  }

  Future<void> _start() async {
    final c = _controller;
    if (c == null || _recording || _busy) return;
    HapticFeedback.mediumImpact();
    await c.startVideoRecording();
    _startedAt = DateTime.now();
    // GPS at the moment recording starts; failure becomes null (see photo screen).
    _fixFuture = _gps.fixFor(_startedAt!);
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
      if (_seconds >= VideoCaptureScreen.maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    final c = _controller;
    if (c == null || !_recording) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      final file = await c.stopVideoRecording();
      final mediaId = newId();
      final stored = await ref.read(mediaStoreProvider).storeVideo(
            sourcePath: file.path,
            logId: widget.logId,
            mediaId: mediaId,
          );

      var fix = await _fixFuture;
      while (fix == null) {
        if (!mounted) return;
        final retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('No GPS signal yet'),
            content: const Text('Move to open sky and try again. Internet is not needed.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try again')),
            ],
          ),
        );
        if (retry != true) {
          setState(() => _busy = false);
          return;
        }
        fix = await _gps.fixFor(DateTime.now());
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedMedia(
          id: mediaId,
          type: 'video',
          filePath: stored.path,
          sha256: stored.sha256,
          capturedAtDevice: _startedAt!,
          fix: fix,
          durationSec: _seconds.clamp(1, VideoCaptureScreen.maxSeconds),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = _controller;
    final left = VideoCaptureScreen.maxSeconds - _seconds;

    return PopScope(
      canPop: !_recording && !_busy,
      child: Scaffold(
        backgroundColor: t.foreground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _recording || _busy ? null : () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: t.background, size: 28),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Film the pump display while it runs, then stop.',
                        style: TextStyle(color: t.background, fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _error != null
                      ? Text(_error!, style: TextStyle(color: t.background, fontSize: 16))
                      : c == null || !c.value.isInitialized
                          ? CircularProgressIndicator(color: t.background)
                          : AspectRatio(
                              aspectRatio: 1 / c.value.aspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(c),
                                  if (_recording)
                                    Positioned(
                                      top: 12,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: t.destructive,
                                            borderRadius: BorderRadius.circular(t.radiusSm),
                                          ),
                                          child: Text(
                                            '● REC  ${_seconds}s  ($left s left)',
                                            style: TextStyle(
                                              color: t.destructiveForeground,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_busy)
                                    ColoredBox(
                                      color: t.foreground.withValues(alpha: 0.6),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(color: t.background),
                                            const SizedBox(height: 16),
                                            Text('Saving video and getting location...',
                                                style: TextStyle(color: t.background, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: _torch ? 'Torch off' : 'Torch on',
                      iconSize: 32,
                      onPressed: c == null || _busy ? null : _toggleTorch,
                      icon: Icon(_torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                          color: t.background),
                    ),
                    GestureDetector(
                      onTap: c == null || _busy ? null : (_recording ? _stop : _start),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.background,
                          border: Border.all(color: t.destructive, width: 5),
                        ),
                        child: Center(
                          child: Container(
                            width: _recording ? 30 : 56,
                            height: _recording ? 30 : 56,
                            decoration: BoxDecoration(
                              color: t.destructive,
                              shape: _recording ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: _recording ? BorderRadius.circular(6) : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
