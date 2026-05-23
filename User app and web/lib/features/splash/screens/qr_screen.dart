import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/splash/helpers/qr_redirect_stub.dart'
    if (dart.library.js_interop) 'package:sixam_mart/features/splash/helpers/qr_redirect_web.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {

  @override
  void initState() {
    super.initState();
    _handleQrRouting();
  }
  Future<void> _handleQrRouting() async {

    final SplashController splashController = Get.find<SplashController>();
    await splashController.fetchAppDownloadSection();
    final links = splashController.appDownloadSection?.downloadUserAppLinks;
    if (GetPlatform.isAndroid && links?.playstoreUrl != null && links!.playstoreUrl!.isNotEmpty) {
      String url = links.playstoreUrl!;
      redirectTo(url);
    } else if (GetPlatform.isIOS && links?.appleStoreUrl != null && links!.appleStoreUrl!.isNotEmpty) {
      String url = links.appleStoreUrl!;
      redirectTo(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),);
  }
}
