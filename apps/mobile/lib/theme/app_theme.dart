import 'package:flutter/material.dart';

import 'page_transitions.dart';
import 'tokens.g.dart';

/// Brand colours that Material's [ColorScheme] has no slot for.
@immutable
class MmPalette extends ThemeExtension<MmPalette> {
  const MmPalette({
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

  static const light = MmPalette(
    optionA: MmColorsLight.optionA,
    optionB: MmColorsLight.optionB,
    onOption: MmColorsLight.onOption,
    accent: MmColorsLight.accent,
    onAccent: MmColorsLight.onAccent,
    textMuted: MmColorsLight.textMuted,
    surfaceMuted: MmColorsLight.surfaceMuted,
    success: MmColorsLight.success,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [MmColorsLight.gradientStart, MmColorsLight.gradientMid, MmColorsLight.gradientEnd],
    ),
  );

  static const dark = MmPalette(
    optionA: MmColorsDark.optionA,
    optionB: MmColorsDark.optionB,
    onOption: MmColorsDark.onOption,
    accent: MmColorsDark.accent,
    onAccent: MmColorsDark.onAccent,
    textMuted: MmColorsDark.textMuted,
    surfaceMuted: MmColorsDark.surfaceMuted,
    success: MmColorsDark.success,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [MmColorsDark.gradientStart, MmColorsDark.gradientMid, MmColorsDark.gradientEnd],
    ),
  );

  static MmPalette of(BuildContext context) => Theme.of(context).extension<MmPalette>()!;

  @override
  MmPalette copyWith() => this;

  @override
  MmPalette lerp(MmPalette? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData buildTheme(Brightness brightness, {bool reduceMotion = false}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? MmColorsDark.primary : MmColorsLight.primary,
    onPrimary: dark ? MmColorsDark.onPrimary : MmColorsLight.onPrimary,
    secondary: dark ? MmColorsDark.accent : MmColorsLight.accent,
    onSecondary: dark ? MmColorsDark.onAccent : MmColorsLight.onAccent,
    error: dark ? MmColorsDark.danger : MmColorsLight.danger,
    onError: dark ? MmColorsDark.background : MmColorsLight.surface,
    surface: dark ? MmColorsDark.surface : MmColorsLight.surface,
    onSurface: dark ? MmColorsDark.text : MmColorsLight.text,
    onSurfaceVariant: dark ? MmColorsDark.textMuted : MmColorsLight.textMuted,
    surfaceContainerHighest: dark ? MmColorsDark.surfaceMuted : MmColorsLight.surfaceMuted,
    surfaceContainerHigh: dark ? MmColorsDark.surfaceMuted : MmColorsLight.surfaceMuted,
    surfaceContainer: dark ? MmColorsDark.surface : MmColorsLight.surface,
    outline: dark ? MmColorsDark.border : MmColorsLight.border,
    outlineVariant: dark ? MmColorsDark.border : MmColorsLight.border,
  );
  final background = dark ? MmColorsDark.background : MmColorsLight.background;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: MmFont.sans,
    extensions: [dark ? MmPalette.dark : MmPalette.light],
  );

  TextStyle? display(TextStyle? s) => s?.copyWith(fontFamily: MmFont.display, fontWeight: FontWeight.w600);
  final text = base.textTheme.copyWith(
    displayLarge: display(base.textTheme.displayLarge),
    displayMedium: display(base.textTheme.displayMedium),
    displaySmall: display(base.textTheme.displaySmall),
    headlineLarge: display(base.textTheme.headlineLarge),
    headlineMedium: display(base.textTheme.headlineMedium),
    headlineSmall: display(base.textTheme.headlineSmall),
    titleLarge: display(base.textTheme.titleLarge),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: MmFontSize.md),
  );

  const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(MmRadius.pill)));
  const minButton = Size(MmTouch.min, MmTouch.game);

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
        borderRadius: BorderRadius.circular(MmRadius.lg),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: MmSpace.s6),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: MmSpace.s6),
        side: BorderSide(color: scheme.outline, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(MmTouch.min, MmTouch.min), textStyle: text.labelLarge),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(fontSize: MmFontSize.sm),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(minimumSize: const Size(MmTouch.min, MmTouch.min)),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GamePageTransitionsBuilder(still: reduceMotion),
        TargetPlatform.iOS: GamePageTransitionsBuilder(still: reduceMotion),
      },
    ),
  );
}
