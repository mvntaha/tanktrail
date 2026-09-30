import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Builds the Material 3 theme from [AppTokens]. No colors are defined here;
/// everything maps from the tokens.
ThemeData buildAppTheme(AppTokens t) {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: t.primary,
    onPrimary: t.primaryForeground,
    secondary: t.secondary,
    onSecondary: t.secondaryForeground,
    tertiary: t.accent,
    onTertiary: t.accentForeground,
    error: t.destructive,
    onError: t.destructiveForeground,
    surface: t.card,
    onSurface: t.cardForeground,
    onSurfaceVariant: t.mutedForeground,
    surfaceContainerHighest: t.muted,
    outline: t.border,
    outlineVariant: t.input,
  );

  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius));
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radiusMd),
    borderSide: BorderSide(color: t.input),
  );

  // Big touch targets and text: drivers use this one-handed, often in bright sun.
  const buttonSize = Size.fromHeight(56);
  const buttonText = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: t.background,
    extensions: [t],
    appBarTheme: AppBarTheme(
      backgroundColor: t.background,
      foregroundColor: t.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: t.foreground,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonSize,
        shape: pill,
        textStyle: buttonText,
        backgroundColor: t.primary,
        foregroundColor: t.primaryForeground,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonSize,
        shape: pill,
        textStyle: buttonText,
        foregroundColor: t.foreground,
        side: BorderSide(color: t.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.primary, textStyle: buttonText),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: t.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: field,
      enabledBorder: field,
      focusedBorder: field.copyWith(borderSide: BorderSide(color: t.ring, width: 2)),
      errorBorder: field.copyWith(borderSide: BorderSide(color: t.destructive)),
      focusedErrorBorder: field.copyWith(borderSide: BorderSide(color: t.destructive, width: 2)),
      labelStyle: TextStyle(color: t.mutedForeground),
    ),
    cardTheme: CardThemeData(
      color: t.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radius),
        side: BorderSide(color: t.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.popover,
      surfaceTintColor: t.popover,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusXl)),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: t.popoverForeground,
      ),
      contentTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: t.popoverForeground),
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.foreground,
      contentTextStyle: TextStyle(fontFamily: 'Inter', color: t.background, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radiusSm)),
    ),
  );
}
