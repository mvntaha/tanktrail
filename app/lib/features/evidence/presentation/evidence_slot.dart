import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/format.dart';
import '../domain/captured_media.dart';

/// One required piece of evidence: an empty "take it" button, or a preview of
/// what was captured with a Retake button.
class EvidenceSlot extends StatelessWidget {
  const EvidenceSlot({
    super.key,
    required this.label,
    required this.icon,
    required this.media,
    required this.onCapture,
    this.height = 140,
  });

  final String label;
  final IconData icon;
  final CapturedMedia? media;
  final VoidCallback? onCapture;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final m = media;
    final radius = BorderRadius.circular(t.radius);

    if (m == null) {
      return Material(
        color: t.accent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onCapture,
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: t.accentForeground),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.accentForeground)),
              ],
            ),
          ),
        ),
      );
    }

    final isVideo = m.type == 'video';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: isVideo
              ? Container(
                  height: height * 0.7,
                  color: t.muted,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_rounded, size: 36, color: t.mutedForeground),
                      const SizedBox(width: 10),
                      Text('Video ${m.durationSec ?? 0}s',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.foreground)),
                    ],
                  ),
                )
              : AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(File(m.filePath), fit: BoxFit.cover, cacheWidth: 1080),
                ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: t.chart[1]),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Saved with location ${formatTime(m.capturedAtDevice)}',
                  style: TextStyle(fontSize: 14, color: t.mutedForeground)),
            ),
            TextButton.icon(onPressed: onCapture, icon: const Icon(Icons.refresh_rounded), label: const Text('Retake')),
          ],
        ),
      ],
    );
  }
}
