import 'package:flutter/material.dart';

class FoxGoDesign {
  static const Color red = Color(0xFFF7272F);
  static const Color deepRed = Color(0xFFE30613);
  static const Color orange = Color(0xFFFF7A00);
  static const Color graphite = Color(0xFF1E2430);
  static const Color textMuted = Color(0xFF6D717A);
  static const Color softBackground = Color(0xFFFAFAFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color softRed = Color(0xFFFFEEF0);

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
      colors: [Color(0xFFFF4B1F), Color(0xFFF7272F), Color(0xFFE30613)],
    );
  }
}
