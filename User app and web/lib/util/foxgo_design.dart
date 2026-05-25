import 'package:flutter/material.dart';

class FoxGoColors {
  static const Color orange = Color(0xFFFF6A00);
  static const Color orangeSoft = Color(0xFFFF8F1F);
  static const Color yellow = Color(0xFFFFC107);
  static const Color red = Color(0xFFFF3B30);

  static const Color lightBackground = Color(0xFFFFF6F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF2F3F5);
  static const Color lightBorder = Color(0xFFDDE1E6);
  static const Color lightText = Color(0xFF1A1C1E);
  static const Color lightMuted = Color(0xFF6F7277);

  static const Color darkBackground = Color(0xFF0F1621);
  static const Color darkSurface = Color(0xFF1A212C);
  static const Color darkSurfaceAlt = Color(0xFF242C38);
  static const Color darkBorder = Color(0xFF3A4452);
  static const Color darkText = Color(0xFFF5F7FA);
  static const Color darkMuted = Color(0xFFA0A7B5);

  static const Color success = Color(0xFF119A4A);
}

class FoxGoPalette {
  final bool dark;
  const FoxGoPalette(this.dark);

  Color get background => dark ? FoxGoColors.darkBackground : FoxGoColors.lightBackground;
  Color get surface => dark ? FoxGoColors.darkSurface : FoxGoColors.lightSurface;
  Color get surfaceAlt => dark ? FoxGoColors.darkSurfaceAlt : FoxGoColors.lightSurfaceAlt;
  Color get border => dark ? FoxGoColors.darkBorder : FoxGoColors.lightBorder;
  Color get text => dark ? FoxGoColors.darkText : FoxGoColors.lightText;
  Color get muted => dark ? FoxGoColors.darkMuted : FoxGoColors.lightMuted;
  Color get shadow => dark ? const Color(0x66000000) : const Color(0x14000000);

  LinearGradient get brandGradient => const LinearGradient(
    colors: [FoxGoColors.orange, FoxGoColors.red],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

BoxDecoration foxGoCardDecoration(FoxGoPalette palette, {double radius = 18}) {
  return BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: palette.border.withValues(alpha: palette.dark ? 0.55 : 0.75)),
    boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 16, offset: const Offset(0, 7))],
  );
}
