import 'package:flutter/material.dart';

class DuckPalette {
  static const Color page = Color(0xFFFFFDF8);
  static const Color pageSoft = Color(0xFFFFFDF6);
  static const Color shell = Color(0xFFFCFBF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFF1ECE6);
  static const Color line = Color(0xFFE9E1D6);
  static const Color overlay = Color(0x66000000);
  static const Color textMain = Color(0xFF40352A);
  static const Color textMuted = Color(0xFFA3978A);
  static const Color duckYellow = Color(0xFFFFC93C);
  static const Color duckYellowSoft = Color(0xFFFFF4CC);
  static const Color duckYellowSofter = Color(0xFFFFF5D6);
  static const Color blueSoft = Color(0xFFE5F1FF);
  static const Color blueText = Color(0xFF5B87D6);
  static const Color mintSoft = Color(0xFFE5F7EA);
  static const Color mintText = Color(0xFF58A16C);
  static const Color coralSoft = Color(0xFFFFE6EA);
  static const Color coralText = Color(0xFFE47786);
  static const Color orangeSoft = Color(0xFFFFF7ED);
  static const Color orangeText = Color(0xFFCC7A00);
  static const Color aquaSoft = Color(0xFFECFEFF);
  static const Color aquaText = Color(0xFF0F7A8A);
  static const Color greenSoft = Color(0xFFF0FDF4);
  static const Color greenText = Color(0xFF4E8D5D);

  static List<BoxShadow> softShadow([double opacity = 0.08]) {
    return [
      BoxShadow(
        color: const Color(0xFF2E2011).withValues(alpha: opacity),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> floatingShadow([double opacity = 0.16]) {
    return [
      BoxShadow(
        color: duckYellow.withValues(alpha: opacity),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }
}
