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

/// In-app camera for one evidence photo (no gallery picker, by design).
/// Pops with a [CapturedMedia] once the photo is stored, hashed and has a GPS fix.
/// Call [ensureLocation] before opening it.
class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({
    super.key,
    required this.logId,
    required this.type,
    required this.hint,
  });

  final String logId;

  /// 'odometer' or 'pump'.
  final String type;

  /// Reminder shown over the preview, e.g. "Show ODO (total km), not TRIP".
  final String hint;

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _torch = false;
  bool _busy = false;
  String _busyText = '';
  Offset? _focusAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // The camera must be released when the app goes to the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive && c != null) {
      _controller = null;
      c.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.veryHigh, // ~1080p: enough to read the LCD digits
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      await c.setFlashMode(_torch ? FlashMode.torch : FlashMode.off);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _error = null;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'CameraAccessDenied'
            ? 'Camera permission is needed. Allow it in app settings.'
            : 'Camera could not start (${e.code}).');
      }
    }
  }

  Future<void> _focus(TapDownDetails d, BoxConstraints box) async {
    final c = _controller;
    if (c == null) return;
    final point = Offset(d.localPosition.dx / box.maxWidth, d.localPosition.dy / box.maxHeight);
    setState(() => _focusAt = d.localPosition);
    try {
      await c.setFocusPoint(point);
      await c.setExposurePoint(point);
    } on CameraException {
      // Some phones don't support focus points; autofocus still works.
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _focusAt = null);
    });
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    final on = !_torch;
    await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    setState(() => _torch = on);
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _busyText = 'Saving photo and getting location...';
    });

    final capturedAt = DateTime.now();
    final location = ref.read(locationServiceProvider);
    // Start GPS right away so it runs while the photo is processed. Failure
    // becomes null (not an exception) so an early GPS error can't go unhandled.
    Future<GeoFix?> startFix() => location.currentFix().then<GeoFix?>((f) => f, onError: (_) => null);
    var fixFuture = startFix();

    try {
      final shot = await c.takePicture();
      final mediaId = newId();
      final stored = await ref.read(mediaStoreProvider).storePhoto(
            sourcePath: shot.path,
            logId: widget.logId,
            mediaId: mediaId,
          );

      var fix = await fixFuture;
      while (fix == null) {
        if (!mounted) return;
        final retry = await _askRetryGps();
        if (retry != true) {
          setState(() => _busy = false);
          return;
        }
        fix = await startFix();
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedMedia(
          id: mediaId,
          type: widget.type,
          filePath: stored.path,
          sha256: stored.sha256,
          capturedAtDevice: capturedAt,
          fix: fix,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo failed: $e')));
    }
  }

  Future<bool?> _askRetryGps() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No GPS signal yet'),
        content: const Text('Move to open sky (away from roofs) and try again. Internet is not needed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Try again')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = _controller;
    // The camera view is dark on purpose; foreground/background tokens are
    // used inverted so text stays readable over it.
    return Scaffold(
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
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: t.background, size: 28),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.hint,
                      style: TextStyle(color: t.background, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: t.background, fontSize: 16)),
                      )
                    : c == null || !c.value.isInitialized
                        ? CircularProgressIndicator(color: t.background)
                        : AspectRatio(
                            // Preview size is reported in landscape; the app is portrait.
                            aspectRatio: 1 / c.value.aspectRatio,
                            child: LayoutBuilder(
                              builder: (context, box) => GestureDetector(
                                onTapDown: (d) => _focus(d, box),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(c),
                                    _FramingGuide(color: t.background),
                                    if (_focusAt != null)
                                      Positioned(
                                        left: _focusAt!.dx - 32,
                                        top: _focusAt!.dy - 32,
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: t.background, width: 2),
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
                                              Text(_busyText, style: TextStyle(color: t.background, fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
                    icon: Icon(_torch ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded, color: t.background),
                  ),
                  // Big shutter for one-handed use.
                  GestureDetector(
                    onTap: c == null || _busy ? null : _capture,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.background,
                        border: Border.all(color: t.primary, width: 5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balances the torch button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide box in the middle: where the odometer/pump display should sit.
class _FramingGuide extends StatelessWidget {
  const _FramingGuide({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.25,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2.5),
              borderRadius: BorderRadius.circular(t.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}
