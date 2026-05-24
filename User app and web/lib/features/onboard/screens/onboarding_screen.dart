import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    Get.find<OnBoardingController>().getOnBoardingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoxGoDesign.softBackground,
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      body: SafeArea(
        child: GetBuilder<OnBoardingController>(
          builder: (onBoardingController) {
            bool showIndicatorAndButton = onBoardingController.selectedIndex < onBoardingController.onBoardingList.length-1;
            return onBoardingController.onBoardingList.isNotEmpty ? SafeArea(
              child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: Column(children: [

                Expanded(child: PageView.builder(
                  itemCount: onBoardingController.onBoardingList.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                        showIndicatorAndButton && onBoardingController.onBoardingList[index].imageUrl != '' ? Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxHeight: context.height * 0.48),
                          padding: EdgeInsets.all(context.height * 0.035),
                          decoration: BoxDecoration(
                            gradient: FoxGoDesign.redGradient(),
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: FoxGoDesign.premiumShadow(opacity: 0.14, blur: 28, offset: const Offset(0, 12)),
                          ),
                          child: Image.asset(onBoardingController.onBoardingList[index].imageUrl, height: context.height*0.35, fit: BoxFit.contain),
                        ) : const SizedBox(),
                        SizedBox(height: context.height * 0.035),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          decoration: BoxDecoration(
                            color: FoxGoDesign.card,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07)),
                            boxShadow: FoxGoDesign.premiumShadow(opacity: 0.06, blur: 18, offset: const Offset(0, 8)),
                          ),
                          child: Column(children: [
                            Text(
                              onBoardingController.onBoardingList[index].title,
                              style: robotoBold.copyWith(fontSize: context.height*0.026, color: FoxGoDesign.graphite, height: 1.08),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.height*0.018),

                            Text(
                              onBoardingController.onBoardingList[index].description,
                              style: robotoMedium.copyWith(fontSize: context.height*0.016, color: FoxGoDesign.textMuted, height: 1.38),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                        ),

                      ]),
                    );
                  },
                  onPageChanged: (index) {
                    onBoardingController.changeSelectIndex(index);
                    if(onBoardingController.selectedIndex == 3) {
                      _configureToRouteInitialPage();
                    }
                  },
                )),

                showIndicatorAndButton ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _pageIndicators(onBoardingController, context),
                ) : const SizedBox(),
                SizedBox(height: context.height*0.035),

                showIndicatorAndButton ? Padding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    onBoardingController.selectedIndex == 2 ? const SizedBox() : Expanded(
                      child: CustomButton(
                        transparent: true,
                        radius: 24,
                        onPressed: () {
                          _configureToRouteInitialPage();
                        },
                        buttonText: 'skip'.tr,
                      ),
                    ),
                    SizedBox(width: onBoardingController.selectedIndex == 2 ? 0 : Dimensions.paddingSizeSmall),
                    Expanded(
                      child: CustomButton(
                        radius: 24,
                        buttonText: onBoardingController.selectedIndex != 2 ? 'next'.tr : 'get_started'.tr,
                        onPressed: () {
                          if(onBoardingController.selectedIndex != 2) {
                           _pageController.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
                          } else {
                            _configureToRouteInitialPage();
                          }
                        },
                      ),
                    ),
                  ]),
                ) : const SizedBox(),

              ]))),
            ) : const SizedBox();
          },
        ),
      ),
    );
  }

  List<Widget> _pageIndicators(OnBoardingController onBoardingController, BuildContext context) {
    List<Container> indicators = [];

    for (int i = 0; i < onBoardingController.onBoardingList.length-1; i++) {
      indicators.add(
        Container(
          width: i == onBoardingController.selectedIndex ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: i == onBoardingController.selectedIndex ? FoxGoDesign.redGradient() : null,
            color: i == onBoardingController.selectedIndex ? null : Theme.of(context).disabledColor.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }
    return indicators;
  }

  void _configureToRouteInitialPage() async {
    Get.find<SplashController>().disableIntro();
    await Get.find<AuthController>().guestLogin();
    if (AddressHelper.getUserAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<LocationController>().navigateToLocationScreen(RouteHelper.onBoarding, offNamed: true).then((v) {
        _pageController.jumpToPage(Get.find<OnBoardingController>().onBoardingList.length-2);
      });
    }
  }
}
