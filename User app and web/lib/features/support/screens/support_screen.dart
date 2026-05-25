import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/support/widgets/web_help_support_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/support/widgets/support_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'help_support'.tr),
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge),
        physics: const BouncingScrollPhysics(),
        child: Center(child: FooterView(
          child: ResponsiveHelper.isDesktop(context) ? const SizedBox(
            width: double.infinity, height: 650,
            child: WebSupportScreen(),
          ) : SizedBox(width: Dimensions.webMaxWidth, child: Column(children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Container(
              height: 132,
              width: 132,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: FoxGoDesign.redGradient(),
                borderRadius: BorderRadius.circular(34),
                boxShadow: FoxGoDesign.premiumShadow(opacity: 0.14, blur: 24, offset: const Offset(0, 10)),
              ),
              child: Image.asset(Images.supportImage, fit: BoxFit.contain),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07)),
                boxShadow: FoxGoDesign.premiumShadow(opacity: 0.06, blur: 16, offset: const Offset(0, 7)),
              ),
              child: Column(children: [
                Image.asset(Images.logo, width: 150),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('Ajuda rápida Fox GO', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: FoxGoDesign.graphite)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('Fale com a gente pelos canais oficiais abaixo.', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            SupportButtonWidget(
              icon: Icons.location_on, title: 'address'.tr, color: Colors.blue,
              info: Get.find<SplashController>().configModel!.address,
              onTap: () {},
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SupportButtonWidget(
              icon: Icons.call, title: 'call'.tr, color: Colors.red,
              info: Get.find<SplashController>().configModel!.phone,
              onTap: () async {
                if(await canLaunchUrlString('tel:${Get.find<SplashController>().configModel!.phone}')) {
                  launchUrlString('tel:${Get.find<SplashController>().configModel!.phone}');
                }else {
                  showCustomSnackBar('${'can_not_launch'.tr} ${Get.find<SplashController>().configModel!.phone}');
                }
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            SupportButtonWidget(
              icon: Icons.mail_outline, title: 'email_us'.tr, color: Colors.green,
              info: Get.find<SplashController>().configModel!.email,
              onTap: () {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: Get.find<SplashController>().configModel!.email,
                );
                launchUrlString(emailLaunchUri.toString());
              },
            ),

          ])),
        )),
      ),
    );
  }
}
