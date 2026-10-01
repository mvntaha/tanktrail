import 'package:material_ui/material_ui.dart';

/// Design tokens mirroring the owner's shadcn-style CSS variables
/// (source of truth: docs/design-tokens.css).
///
/// All colors, radii and shadows in the app come from here. Widgets read them
/// with `context.tokens`. A future theme change = replace this one file.
/// Only [AppTokens.light] is wired up; [AppTokens.dark] exists but is unused.
/// CSS px = Flutter logical px; 1rem = 16px.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
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
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
    required this.shadow2xs,
    required this.shadowXs,
    required this.shadowSm,
    required this.shadow,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowXl,
    required this.shadow2xl,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
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

  /// --chart-1 .. --chart-5.
  final List<Color> chart;

  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  final List<BoxShadow> shadow2xs;
  final List<BoxShadow> shadowXs;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowXl;
  final List<BoxShadow> shadow2xl;

  // --radius: 1.5rem, and the @theme inline steps. Same in light and dark.
  double get radius => 24; // --radius / --radius-lg
  double get radiusSm => 20; // calc(--radius - 4px)
  double get radiusMd => 22; // calc(--radius - 2px)
  double get radiusLg => 24;
  double get radiusXl => 28; // calc(--radius + 4px)

  /// --spacing: 0.25rem. Tailwind's p-4 = 4 * spacing = 16.
  double get spacing => 4;

  /// One CSS box-shadow layer. CSS blur uses sigma = blur / 2, while Flutter
  /// uses sigma = blurRadius * 0.57735 + 0.5, so blurRadius = (blur/2 - 0.5) / 0.57735.
  static BoxShadow _layer(Color color, double y, double blur, [double spread = 0]) {
    return BoxShadow(
      color: color,
      offset: Offset(0, y),
      blurRadius: blur <= 1 ? 0 : (blur / 2 - 0.5) / 0.57735,
      spreadRadius: spread,
    );
  }

  /// Builds the --shadow-2xs .. --shadow-2xl scale. Every level shares the base
  /// layer (0 y blur); sm..xl add a second tight layer, as in the CSS.
  static Map<String, List<BoxShadow>> _scale({
    required Color Function(double opacity) color,
    required double y,
    required double blur,
    required double softOpacity,
    required double opacity,
    required double strongOpacity,
  }) {
    BoxShadow base(double o) => _layer(color(o), y, blur);
    return {
      '2xs': [base(softOpacity)],
      'xs': [base(softOpacity)],
      'sm': [base(opacity), _layer(color(opacity), 1, 2, -1)],
      '': [base(opacity), _layer(color(opacity), 1, 2, -1)],
      'md': [base(opacity), _layer(color(opacity), 2, 4, -1)],
      'lg': [base(opacity), _layer(color(opacity), 4, 6, -1)],
      'xl': [base(opacity), _layer(color(opacity), 8, 10, -1)],
      '2xl': [base(strongOpacity)],
    };
  }

  // --shadow-color #4e5661 = hsl(214.7368 10.8571% 34.3137%).
  static final _lightShadows = _scale(
    color: (o) => const Color(0xFF4E5661).withValues(alpha: o),
    y: 2,
    blur: 28,
    softOpacity: 0.05,
    opacity: 0.10,
    strongOpacity: 0.25,
  );

  // CSS alpha 1.13 in --shadow-2xl is clamped to 1 by browsers; same here.
  static final _darkShadows = _scale(
    color: (o) => const Color(0xFF000000).withValues(alpha: o.clamp(0, 1)),
    y: 4,
    blur: 40,
    softOpacity: 0.23,
    opacity: 0.45,
    strongOpacity: 1.13,
  );

  static final AppTokens light = AppTokens(
    background: const Color(0xFFF4F5F7),
    foreground: const Color(0xFF0C121A),
    card: const Color(0xFFFFFFFF),
    cardForeground: const Color(0xFF0C121A),
    popover: const Color(0xFFFFFFFF),
    popoverForeground: const Color(0xFF0C121A),
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
    sidebar: const Color(0xFFECEFF1),
    sidebarForeground: const Color(0xFF0C121A),
    sidebarPrimary: const Color(0xFF297CEF),
    sidebarPrimaryForeground: const Color(0xFFFFFFFF),
    sidebarAccent: const Color(0xFFD9E6F9),
    sidebarAccentForeground: const Color(0xFF002C78),
    sidebarBorder: const Color(0xFFDBDEE2),
    sidebarRing: const Color(0xFF297CEF),
    shadow2xs: _lightShadows['2xs']!,
    shadowXs: _lightShadows['xs']!,
    shadowSm: _lightShadows['sm']!,
    shadow: _lightShadows['']!,
    shadowMd: _lightShadows['md']!,
    shadowLg: _lightShadows['lg']!,
    shadowXl: _lightShadows['xl']!,
    shadow2xl: _lightShadows['2xl']!,
  );

  /// Defined for later; not wired into the app yet.
  static final AppTokens dark = AppTokens(
    background: const Color(0xFF090B0F),
    foreground: const Color(0xFFF0F2F4),
    card: const Color(0xFF13161B),
    cardForeground: const Color(0xFFF0F2F4),
    popover: const Color(0xFF1A1D22),
    popoverForeground: const Color(0xFFF0F2F4),
    primary: const Color(0xFF3A8CFF),
    primaryForeground: const Color(0xFF040609),
    secondary: const Color(0xFF1C2024),
    secondaryForeground: const Color(0xFFD9DFE5),
    muted: const Color(0xFF181B1F),
    mutedForeground: const Color(0xFF8F9AA4),
    accent: const Color(0xFF152946),
    accentForeground: const Color(0xFFA5D0FF),
    destructive: const Color(0xFFFF515A),
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
    sidebar: const Color(0xFF0F1216),
    sidebarForeground: const Color(0xFFF0F2F4),
    sidebarPrimary: const Color(0xFF3A8CFF),
    sidebarPrimaryForeground: const Color(0xFF040609),
    sidebarAccent: const Color(0xFF152946),
    sidebarAccentForeground: const Color(0xFFA5D0FF),
    sidebarBorder: const Color(0xFF212429),
    sidebarRing: const Color(0xFF3A8CFF),
    shadow2xs: _darkShadows['2xs']!,
    shadowXs: _darkShadows['xs']!,
    shadowSm: _darkShadows['sm']!,
    shadow: _darkShadows['']!,
    shadowMd: _darkShadows['md']!,
    shadowLg: _darkShadows['lg']!,
    shadowXl: _darkShadows['xl']!,
    shadow2xl: _darkShadows['2xl']!,
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
