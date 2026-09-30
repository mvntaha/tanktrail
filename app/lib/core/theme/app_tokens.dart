import 'package:material_ui/material_ui.dart';

/// Design tokens mirroring the owner's shadcn-style CSS variables.
///
/// All colors, radii and shadows in the app come from here. Widgets read them
/// with `context.tokens`. A future theme change = replace this one file.
/// Only [AppTokens.light] is wired up; [AppTokens.dark] exists but is unused.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart,
    required this.radiusSm,
    required this.radiusMd,
    required this.radius,
    required this.radiusXl,
    required this.shadow,
    required this.shadowSm,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color popover;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;

  /// chart-1 .. chart-5.
  final List<Color> chart;

  final double radiusSm;
  final double radiusMd;
  final double radius;
  final double radiusXl;

  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowSm;

  // CSS blur -> Flutter blurRadius: CSS sigma = blur / 2, while Flutter uses
  // sigma = blurRadius * 0.57735 + 0.5. So blurRadius = (blur / 2 - 0.5) / 0.57735.
  static double _cssBlur(double blur) => (blur / 2 - 0.5) / 0.57735;

  // hsl(214.7 10.9% 34.3%) = #4E5661, at 10% alpha.
  static const Color _lightShadowColor = Color(0x1A4E5661);

  static final AppTokens light = AppTokens(
    background: const Color(0xFFF4F5F7),
    foreground: const Color(0xFF0C121A),
    card: const Color(0xFFFFFFFF),
    popover: const Color(0xFFFFFFFF),
    primary: const Color(0xFF297CEF),
    primaryForeground: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFE9EBEE),
    secondaryForeground: const Color(0xFF222933),
    muted: const Color(0xFFECEFF1),
    mutedForeground: const Color(0xFF565E69),
    accent: const Color(0xFFD9E6F9),
    accentForeground: const Color(0xFF002C78),
    destructive: const Color(0xFFEE343B),
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFFDBDEE2),
    input: const Color(0xFFE2E5E8),
    ring: const Color(0xFF297CEF),
    chart: const [
      Color(0xFF297CEF),
      Color(0xFF00A381),
      Color(0xFF864AD2),
      Color(0xFFF3680F),
      Color(0xFFEC2773),
    ],
    radiusSm: 20,
    radiusMd: 22,
    radius: 24,
    radiusXl: 28,
    shadow: [
      BoxShadow(color: _lightShadowColor, offset: const Offset(0, 2), blurRadius: _cssBlur(28)),
    ],
    shadowSm: [
      BoxShadow(color: _lightShadowColor, offset: const Offset(0, 2), blurRadius: _cssBlur(28)),
      BoxShadow(
        color: _lightShadowColor,
        offset: const Offset(0, 1),
        blurRadius: _cssBlur(2),
        spreadRadius: -1,
      ),
    ],
  );

  /// Defined for later; not wired into the app yet.
  static final AppTokens dark = AppTokens(
    background: const Color(0xFF090B0F),
    foreground: const Color(0xFFF0F2F4),
    card: const Color(0xFF13161B),
    popover: const Color(0xFF1A1D22),
    primary: const Color(0xFF3A8CFF),
    primaryForeground: const Color(0xFF040609),
    secondary: const Color(0xFF1C2024),
    secondaryForeground: const Color(0xFFD9DFE5),
    muted: const Color(0xFF181B1F),
    mutedForeground: const Color(0xFF8F9AA4),
    accent: const Color(0xFF152946),
    accentForeground: const Color(0xFFA5D0FF),
    destructive: const Color(0xFFFF515A),
    // Not given in the dark palette; reuses the light value until the owner decides.
    destructiveForeground: const Color(0xFFFFFFFF),
    border: const Color(0xFF26292E),
    input: const Color(0xFF26292E),
    ring: const Color(0xFF3A8CFF),
    chart: const [
      Color(0xFF3A8CFF),
      Color(0xFF00B793),
      Color(0xFF9B61EA),
      Color(0xFFFF7527),
      Color(0xFFFB3A7F),
    ],
    radiusSm: 20,
    radiusMd: 22,
    radius: 24,
    radiusXl: 28,
    shadow: [
      BoxShadow(color: const Color(0x73000000), offset: const Offset(0, 4), blurRadius: _cssBlur(40)),
    ],
    shadowSm: [
      BoxShadow(color: const Color(0x73000000), offset: const Offset(0, 4), blurRadius: _cssBlur(40)),
    ],
  );

  @override
  AppTokens copyWith() => this;

  // Theme switching is not animated; snap to the target tokens.
  @override
  AppTokens lerp(covariant AppTokens? other, double t) => t < 0.5 || other == null ? this : other;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
