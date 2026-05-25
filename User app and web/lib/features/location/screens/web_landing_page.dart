import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/screens/foxgo_mobile_home_screen.dart';

class WebLandingPage extends StatelessWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  const WebLandingPage({super.key, required this.fromSignUp, required this.fromHome, required this.route});

  @override
  Widget build(BuildContext context) {
    return const FoxGoMobileHomeScreen();
  }
}
