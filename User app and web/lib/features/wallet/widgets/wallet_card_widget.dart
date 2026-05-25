import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/wallet/widgets/add_fund_dialogue_widget.dart';

class WalletCardWidget extends StatelessWidget {
  final JustTheController tooltipController;
  const WalletCardWidget({super.key, required this.tooltipController});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    final ScrollController cardScrollController = ScrollController();

    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isDesktop ? const SizedBox() : const SizedBox(height: Dimensions.paddingSizeSmall),

            Stack(children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 36 : 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: FoxGoDesign.redGradient(),
                  boxShadow: FoxGoDesign.premiumShadow(opacity: 0.18, blur: 26, offset: const Offset(0, 12)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('wallet_amount'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).cardColor.withValues(alpha: 0.90))),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(children: [
                    Text(
                      PriceConverter.convertPrice(profileController.userInfoModel!.walletBalance), textDirection: TextDirection.ltr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge + 4, color: Theme.of(context).cardColor, height: 1.0),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),

                    Get.find<SplashController>().configModel!.addFundStatus! && Get.find<SplashController>().configModel!.digitalPayment! ? JustTheTooltip(
                      backgroundColor: FoxGoDesign.graphite,
                      controller: tooltipController,
                      preferredDirection: AxisDirection.right,
                      tailLength: 14,
                      tailBaseWidth: 20,
                      content: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'if_you_want_to_add_fund_to_your_wallet_then_click_add_fund_button'.tr,
                          style: robotoRegular.copyWith(color: Colors.white),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => tooltipController.showTooltip(),
                        child: Container(height: 34, width: 34, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.info_outline, color: Theme.of(context).cardColor, size: 19)),
                      ),
                    ) : const SizedBox(),
                  ]),
                ]),
              ),

              Get.find<SplashController>().configModel!.addFundStatus! && Get.find<SplashController>().configModel!.digitalPayment! ? Positioned(
                top: 24, right: Get.find<LocalizationController>().isLtr ? 22 : null,
                left: Get.find<LocalizationController>().isLtr ? null : 10,
                child: InkWell(
                  onTap: () {
                    Get.dialog(
                      Dialog(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, child: SizedBox(
                        width: 500, child: SingleChildScrollView(controller: cardScrollController, child: AddFundDialogueWidget(cardScrollController: cardScrollController)),
                      )),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor, boxShadow: FoxGoDesign.premiumShadow(opacity: 0.12, blur: 14, offset: const Offset(0, 5))),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                  ),
                ),
              ) : const SizedBox(),

            ]),
            isDesktop ? const SizedBox() : const SizedBox(height: Dimensions.paddingSizeSmall),
            isDesktop ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            isDesktop ? Text('how_to_use'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge + 1, color: FoxGoDesign.graphite)) : const SizedBox(),
            isDesktop ? const SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

            !isDesktop ? const SizedBox() : const WalletStepper(),
          ],
        );
      }
    );
  }
}

class WalletStepper extends StatelessWidget {
  const WalletStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
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
                Text('earn_money_to_your_wallet_by_completing_the_offer_challenged'.tr, style: robotoMedium.copyWith(color: FoxGoDesign.graphite)),
                Text('convert_your_loyalty_points_into_wallet_money'.tr, style: robotoMedium.copyWith(color: FoxGoDesign.graphite)),
                Text('amin_also_reward_their_top_customers_with_wallet_money'.tr, style: robotoMedium.copyWith(color: FoxGoDesign.graphite)),
                Text('send_your_wallet_money_while_order'.tr, style: robotoMedium.copyWith(color: FoxGoDesign.graphite)),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

