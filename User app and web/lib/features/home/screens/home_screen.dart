import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/foxgo_mobile_home_screen.dart';

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
    return const FoxGoMobileHomeScreen();
  }
}
