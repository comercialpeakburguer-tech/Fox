import 'dart:async';
import 'dart:io';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromNotification;
  final bool fromResetPassword;
  final bool? fromRideDialog;
  const SignInScreen({super.key, required this.exitFromApp, required this.backFromThis, this.fromNotification = false, this.fromResetPassword = false, this.fromRideDialog});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        if(widget.fromNotification || widget.fromResetPassword) {
          Navigator.pushNamed(context, RouteHelper.getInitialRoute());
        } else if(widget.exitFromApp) {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            } else {
              Navigator.pushNamed(context, RouteHelper.getInitialRoute());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        } else {
          if(Get.find<AuthController>().isOtpViewEnable){
            Get.find<AuthController>().enableOtpView(enable: false);
          }else{
            // Get.back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: (ResponsiveHelper.isDesktop(context) ? null : !widget.exitFromApp ? AppBar(leading: IconButton(
            onPressed: () {
              if(widget.fromNotification || widget.fromResetPassword) {
                Navigator.pushNamed(context, RouteHelper.getInitialRoute());
              }else if(Get.find<AuthController>().isOtpViewEnable){
                Get.find<AuthController>().enableOtpView(enable: false);
              }else{
                Get.back(result: false);
              }
            },
            icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
          elevation: 0, backgroundColor: Theme.of(context).colorScheme.surface, actions: const [SizedBox()],
        ) : null),
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,

        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: context.width > 700 ? 520 : context.width,
              padding: context.width > 700 ? const EdgeInsets.all(38) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              margin: context.width > 700 ? const EdgeInsets.all(34) : EdgeInsets.zero,
              decoration: context.width > 700 ? BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07)),
                boxShadow: FoxGoDesign.premiumShadow(opacity: 0.10, blur: 24, offset: const Offset(0, 12)),
              ) : null,
              child: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [

                  ResponsiveHelper.isDesktop(context) ? Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.clear),
                    ),
                  ) : const SizedBox(),

                  Container(
                    height: 92,
                    width: 92,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FoxGoDesign.softRed,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: FoxGoDesign.premiumShadow(opacity: 0.08, blur: 18, offset: const Offset(0, 8)),
                    ),
                    child: Image.asset(Images.logo, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis, fromResetPassword: widget.fromResetPassword, isOtpViewEnable: (v){},),

                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
