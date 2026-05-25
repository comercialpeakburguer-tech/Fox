import 'package:flutter/material.dart';

class FoxGoDesign {
  static const Color orange = Color(0xFFFF6A00);
  static const Color orangeSoft = Color(0xFFFF8F1F);
  static const Color yellow = Color(0xFFFFC107);
  static const Color red = Color(0xFFFF3B30);
  static const Color deepRed = Color(0xFFE53935);
  static const Color graphite = Color(0xFF1A1C1E);
  static const Color textMuted = Color(0xFF737985);
  static const Color softBackground = Color(0xFFFFF6F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color softRed = Color(0xFFFFEDE2);
  static const Color softOrange = Color(0xFFFFF2E6);

  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 30;

  static List<BoxShadow> premiumShadow({double opacity = 0.075, double blur = 20, Offset offset = const Offset(0, 8)}) {
    return [BoxShadow(color: Colors.black.withValues(alpha: opacity), blurRadius: blur, spreadRadius: 0, offset: offset)];
  }

  static LinearGradient redGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF8F1F), Color(0xFFFF6A00), Color(0xFFFF3B30)],
    );
  }

  static LinearGradient orangeGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFC107), Color(0xFFFF8F1F), Color(0xFFFF6A00)],
    );
  }
}
