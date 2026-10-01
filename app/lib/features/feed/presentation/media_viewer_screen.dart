import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/feed_entry.dart';

/// Small square preview used in the feed. Phone copy if we still have it,
/// otherwise a cached Cloudinary thumbnail (works offline once seen).
class FeedThumb extends StatelessWidget {
  const FeedThumb({super.key, required this.media, this.size = 76});

  final FeedMedia media;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final local = media.localPath;
    final placeholder = Container(
      color: t.muted,
      alignment: Alignment.center,
      child: Icon(media.isVideo ? Icons.videocam_rounded : Icons.photo_rounded, color: t.mutedForeground),
    );

    Widget image;
    if (local != null && !media.isVideo && File(local).existsSync()) {
      image = Image.file(File(local), fit: BoxFit.cover, cacheWidth: 240);
    } else if (media.thumbUrl != null) {
      image = CachedNetworkImage(
        imageUrl: media.thumbUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusSm / 1.5),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (media.isVideo)
              Container(
                color: t.foreground.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, color: t.background, size: 30),
                    if (media.durationSec != null)
                      Text('${media.durationSec}s', style: TextStyle(color: t.background, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen viewer: swipe between photos (pinch to zoom) and videos.
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({super.key, required this.media, this.initial = 0});

  final List<FeedMedia> media;
  final int initial;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  static const _labels = {'odometer': 'Odometer', 'pump': 'Pump display', 'video': 'Pump video'};

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.foreground,
      appBar: AppBar(
        backgroundColor: t.foreground,
        foregroundColor: t.background,
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: t.background),
        title: Text('${_labels[widget.media[_index].type] ?? ''}  ${_index + 1}/${widget.media.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.media.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final m = widget.media[i];
          return m.isVideo ? _VideoPage(media: m) : _PhotoPage(media: m);
        },
      ),
    );
  }
}

class _PhotoPage extends StatelessWidget {
  const _PhotoPage({required this.media});

  final FeedMedia media;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final local = media.localPath;
    final Widget image = local != null && File(local).existsSync()
        ? Image.file(File(local), fit: BoxFit.contain)
        : media.url != null
            ? CachedNetworkImage(
                imageUrl: media.url!,
                fit: BoxFit.contain,
                placeholder: (_, _) => Center(child: CircularProgressIndicator(color: t.background)),
                errorWidget: (_, _, _) =>
                    Center(child: Text('Photo not available offline', style: TextStyle(color: t.background))),
              )
            : Center(child: Text('Photo not available', style: TextStyle(color: t.background)));
    return InteractiveViewer(maxScale: 6, child: Center(child: image));
  }
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.media});

  final FeedMedia media;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    final local = widget.media.localPath;
    final c = local != null && File(local).existsSync()
        ? VideoPlayerController.file(File(local))
        : widget.media.url != null
            ? VideoPlayerController.networkUrl(Uri.parse(widget.media.url!))
            : null;
    if (c == null) {
      _error = 'Video not available';
      return;
    }
    _c = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
      c.play();
    }).catchError((Object _) {
      if (mounted) setState(() => _error = 'Video needs internet to play');
    });
    c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = _c;
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: t.background)));
    if (c == null || !c.value.isInitialized) return Center(child: CircularProgressIndicator(color: t.background));
    return GestureDetector(
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))),
          if (!c.value.isPlaying) Icon(Icons.play_circle_fill_rounded, size: 72, color: t.background),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: VideoProgressColors(playedColor: t.primary, bufferedColor: t.muted, backgroundColor: t.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
