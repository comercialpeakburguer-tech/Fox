import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/loyalty/widgets/loyalty_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';

class LoyaltyCardWidget extends StatelessWidget {
  final JustTheController tooltipController;
  const LoyaltyCardWidget({super.key, required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 36 : 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: FoxGoDesign.redGradient(),
                boxShadow: FoxGoDesign.premiumShadow(opacity: 0.18, blur: 26, offset: const Offset(0, 12)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                Container(height: 70, width: 70, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(24)), child: Image.asset(Images.loyal, height: 46, width: 46)),
                const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                  ResponsiveHelper.isDesktop(context) ? const SizedBox() : Text(
                    '${'convertible_points'.tr} !',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).cardColor.withValues(alpha: 0.90)),
                  ),

                  Text(
                    profileController.userInfoModel!.loyaltyPoint == null ? '0' : profileController.userInfoModel!.loyaltyPoint.toString(),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge + 6, color: Theme.of(context).cardColor, height: 1.0),
                  ),

                  ResponsiveHelper.isDesktop(context) ? Text(
                    '${'convertible_points'.tr} !',
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).cardColor.withValues(alpha: 0.90)),
                  ) : const SizedBox(),

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ]),
              ]),
            ),

            ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            ResponsiveHelper.isDesktop(context) ? Text('how_to_use'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge + 1, color: FoxGoDesign.graphite)) : const SizedBox(),
            ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            !ResponsiveHelper.isDesktop(context) ? const SizedBox() : const LoyaltyStepper(),
          ],
        );
      }
    );
  }
}



class LoyaltyStepper extends StatelessWidget {
  const LoyaltyStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                    ),
                  ),

                  Expanded(
                    child: VerticalDivider(
                      thickness: 3,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.30),
                    ),
                  ),

                  Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                    ),
                  ),
                ],
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('convert_your_loyalty_point_to_wallet_money'.tr, style: robotoMedium.copyWith(color: FoxGoDesign.graphite)),
                    Text('${'minimun'.tr} ${Get.find<SplashController>().configModel!.loyaltyPointExchangeRate} ${'points_required_to_convert_into_currency'.tr}', style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),

            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        CustomButton(
          radius: 22,
          isBold: true,
          buttonText: 'convert_to_currency_now'.tr,
          onPressed: () {
            Get.dialog(
              Dialog(backgroundColor: Colors.transparent, child: LoyaltyBottomSheetWidget(
                amount: Get.find<ProfileController>().userInfoModel!.loyaltyPoint == null
                  ? '0' : Get.find<ProfileController>().userInfoModel!.loyaltyPoint.toString(),
              )),
            );
          },
        ),
      ],
    );
  }
}

