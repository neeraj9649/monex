import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const fontFamily = 'Inter';
  static const fontFallback = [
    'SF Pro Display',
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'Arial',
  ];

  static const moneyFeatures = [
    FontFeature.tabularFigures(),
    FontFeature.enable('tnum'),
  ];

  static TextTheme build(TextTheme base, Color text, Color muted) {
    TextStyle apply(TextStyle? style, double height, FontWeight weight) =>
        (style ?? const TextStyle()).copyWith(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
          color: text,
          height: height,
          fontWeight: weight,
          letterSpacing: 0,
        );

    return base.copyWith(
      displaySmall: apply(base.displaySmall, 1.05, FontWeight.w800),
      headlineLarge: apply(base.headlineLarge, 1.08, FontWeight.w800),
      headlineMedium: apply(base.headlineMedium, 1.12, FontWeight.w800),
      headlineSmall: apply(base.headlineSmall, 1.16, FontWeight.w800),
      titleLarge: apply(base.titleLarge, 1.18, FontWeight.w800),
      titleMedium: apply(base.titleMedium, 1.25, FontWeight.w700),
      titleSmall: apply(base.titleSmall, 1.28, FontWeight.w700),
      bodyLarge: apply(base.bodyLarge, 1.5, FontWeight.w500),
      bodyMedium: apply(base.bodyMedium, 1.45, FontWeight.w500),
      bodySmall: apply(
        base.bodySmall,
        1.4,
        FontWeight.w500,
      ).copyWith(color: muted),
      labelLarge: apply(base.labelLarge, 1.2, FontWeight.w700),
      labelMedium: apply(
        base.labelMedium,
        1.2,
        FontWeight.w700,
      ).copyWith(color: muted),
      labelSmall: apply(
        base.labelSmall,
        1.15,
        FontWeight.w700,
      ).copyWith(color: muted),
    );
  }

  static TextStyle money(TextStyle? base) => (base ?? const TextStyle())
      .copyWith(fontFeatures: moneyFeatures, letterSpacing: 0);
}
