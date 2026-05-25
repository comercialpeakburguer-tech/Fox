import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/foxgo_mobile_home_screen.dart';
import 'package:sixam_mart/features/home/screens/foxgo_web_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static Future<void> loadData(bool reload, {bool fromModule = false}) async {
    // A Home visual da Fox GO não deve bloquear a abertura da página esperando
    // módulos, endereço ou listas da API. Esses dados serão ligados aos cards
    // depois, sem travar o primeiro carregamento.
    return;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return const FoxGoWebHomeScreen();
    }
    return const FoxGoMobileHomeScreen();
  }
}
