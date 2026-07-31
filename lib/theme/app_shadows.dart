import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: .08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> elevated(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: .12),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
  ];
}
