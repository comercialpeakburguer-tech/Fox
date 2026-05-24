import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ThemeController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  ThemeController({required this.sharedPreferences}) {
    _loadCurrentTheme();
  }

  bool _darkTheme = false;
  Color? _lightColor;
  Color? _darkColor;

  bool get darkTheme => _darkTheme;
  Color? get darkColor => _darkColor;
  Color? get lightColor => _lightColor;

  String _lightMap = '[]';
  String get lightMap => _lightMap;

  String _darkMap = '[]';
  String get darkMap => _darkMap;

  String _lightMapTaxi = '[]';
  String get lightMapTaxi => _lightMapTaxi;

  void toggleTheme() {
    setTheme(!_darkTheme);
  }

  void setTheme(bool isDark) {
    _darkTheme = isDark;
    sharedPreferences.setBool(AppConstants.theme, _darkTheme);
    Get.changeThemeMode(_darkTheme ? ThemeMode.dark : ThemeMode.light);
    _setSystemOverlayStyle();
    update();
  }

  void changeTheme(Color lightColor, Color darkColor) {
    _lightColor = lightColor;
    _darkColor = darkColor;
    update();
  }

  Future<void> _loadCurrentTheme() async {
    _lightMap = await rootBundle.loadString('assets/map/light_map.json');
    _darkMap = await rootBundle.loadString('assets/map/dark_map.json');
    _lightMapTaxi = await rootBundle.loadString('assets/map/light_taxi.json');
    _darkTheme = sharedPreferences.getBool(AppConstants.theme) ?? false;
    Get.changeThemeMode(_darkTheme ? ThemeMode.dark : ThemeMode.light);
    _setSystemOverlayStyle();
    update();
  }

  void _setSystemOverlayStyle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: _darkTheme ? const Color(0xFF0F1621) : const Color(0xFFFFF6F0),
      statusBarIconBrightness: _darkTheme ? Brightness.light : Brightness.dark,
      statusBarBrightness: _darkTheme ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness: _darkTheme ? Brightness.light : Brightness.dark,
    ));
  }
}
