import 'package:flutter/material.dart';

import 'page_transitions.dart';
import 'tokens.g.dart';

/// Brand colours that Material's [ColorScheme] has no slot for.
@immutable
class GfPalette extends ThemeExtension<GfPalette> {
  const GfPalette({
    required this.optionA,
    required this.optionB,
    required this.onOption,
    required this.accent,
    required this.onAccent,
    required this.textMuted,
    required this.surfaceMuted,
    required this.success,
    required this.gradient,
  });

  final Color optionA;
  final Color optionB;
  final Color onOption;
  final Color accent;
  final Color onAccent;
  final Color textMuted;
  final Color surfaceMuted;
  final Color success;
  final Gradient gradient;

  static const light = GfPalette(
    optionA: GfColorsLight.optionA,
    optionB: GfColorsLight.optionB,
    onOption: GfColorsLight.onOption,
    accent: GfColorsLight.accent,
    onAccent: GfColorsLight.onAccent,
    textMuted: GfColorsLight.textMuted,
    surfaceMuted: GfColorsLight.surfaceMuted,
    success: GfColorsLight.success,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [GfColorsLight.gradientStart, GfColorsLight.gradientMid, GfColorsLight.gradientEnd],
    ),
  );

  static const dark = GfPalette(
    optionA: GfColorsDark.optionA,
    optionB: GfColorsDark.optionB,
    onOption: GfColorsDark.onOption,
    accent: GfColorsDark.accent,
    onAccent: GfColorsDark.onAccent,
    textMuted: GfColorsDark.textMuted,
    surfaceMuted: GfColorsDark.surfaceMuted,
    success: GfColorsDark.success,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [GfColorsDark.gradientStart, GfColorsDark.gradientMid, GfColorsDark.gradientEnd],
    ),
  );

  static GfPalette of(BuildContext context) => Theme.of(context).extension<GfPalette>()!;

  @override
  GfPalette copyWith() => this;

  @override
  GfPalette lerp(GfPalette? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData buildTheme(Brightness brightness, {bool reduceMotion = false}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? GfColorsDark.primary : GfColorsLight.primary,
    onPrimary: dark ? GfColorsDark.onPrimary : GfColorsLight.onPrimary,
    secondary: dark ? GfColorsDark.accent : GfColorsLight.accent,
    onSecondary: dark ? GfColorsDark.onAccent : GfColorsLight.onAccent,
    error: dark ? GfColorsDark.danger : GfColorsLight.danger,
    onError: dark ? GfColorsDark.background : GfColorsLight.surface,
    surface: dark ? GfColorsDark.surface : GfColorsLight.surface,
    onSurface: dark ? GfColorsDark.text : GfColorsLight.text,
    onSurfaceVariant: dark ? GfColorsDark.textMuted : GfColorsLight.textMuted,
    surfaceContainerHighest: dark ? GfColorsDark.surfaceMuted : GfColorsLight.surfaceMuted,
    surfaceContainerHigh: dark ? GfColorsDark.surfaceMuted : GfColorsLight.surfaceMuted,
    surfaceContainer: dark ? GfColorsDark.surface : GfColorsLight.surface,
    outline: dark ? GfColorsDark.border : GfColorsLight.border,
    outlineVariant: dark ? GfColorsDark.border : GfColorsLight.border,
  );
  final background = dark ? GfColorsDark.background : GfColorsLight.background;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: GfFont.sans,
    extensions: [dark ? GfPalette.dark : GfPalette.light],
  );

  TextStyle? display(TextStyle? s) => s?.copyWith(fontFamily: GfFont.display, fontWeight: FontWeight.w600);
  final text = base.textTheme.copyWith(
    displayLarge: display(base.textTheme.displayLarge),
    displayMedium: display(base.textTheme.displayMedium),
    displaySmall: display(base.textTheme.displaySmall),
    headlineLarge: display(base.textTheme.headlineLarge),
    headlineMedium: display(base.textTheme.headlineMedium),
    headlineSmall: display(base.textTheme.headlineSmall),
    titleLarge: display(base.textTheme.titleLarge),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: GfFontSize.md),
  );

  const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(GfRadius.pill)));
  const minButton = Size(GfTouch.min, GfTouch.game);

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GfRadius.lg),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: GfSpace.s6),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: GfSpace.s6),
        side: BorderSide(color: scheme.outline, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(GfTouch.min, GfTouch.min), textStyle: text.labelLarge),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(fontSize: GfFontSize.sm),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(minimumSize: const Size(GfTouch.min, GfTouch.min)),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GamePageTransitionsBuilder(still: reduceMotion),
        TargetPlatform.iOS: GamePageTransitionsBuilder(still: reduceMotion),
      },
    ),
  );
}
