import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData dark({Color color = const Color(0xFFFF6A00)}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: color,
  secondaryHeaderColor: const Color(0xFFFF8F1F),
  disabledColor: const Color(0xFFA0A7B5),
  brightness: Brightness.dark,
  hintColor: const Color(0xFFA0A7B5),
  cardColor: const Color(0xFF1A212C),
  scaffoldBackgroundColor: const Color(0xFF0F1621),
  shadowColor: Colors.black.withValues(alpha: 0.28),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFFFF4E6)),
    bodyMedium: TextStyle(color: Color(0xFFFFF4E6)),
    bodySmall: TextStyle(color: Color(0xFFA0A7B5)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F1621),
    foregroundColor: Color(0xFFFFF4E6),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: color)),
  colorScheme: ColorScheme.dark(
    primary: color,
    secondary: const Color(0xFFFF8F1F),
    surface: const Color(0xFF0F1621),
    error: const Color(0xFFE53935),
  ),
  popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF1A212C), surfaceTintColor: Color(0xFF1A212C)),
  dialogTheme: const DialogThemeData(surfaceTintColor: Color(0xFF1A212C), backgroundColor: Color(0xFF1A212C)),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: color,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: Color(0xFF1A212C),
    surfaceTintColor: Color(0xFF1A212C),
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),
  dividerTheme: const DividerThemeData(thickness: 0.5, color: Color(0xFF303947)),
  tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
);
