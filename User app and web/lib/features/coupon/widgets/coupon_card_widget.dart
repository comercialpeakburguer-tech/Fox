import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/features/coupon/domain/models/coupon_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class CouponCardWidget extends StatelessWidget {
  final CouponModel coupon;
  final int index;
  final List<JustTheController>? toolTipController;
  const CouponCardWidget({super.key, required this.coupon, required this.index, this.toolTipController});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: FoxGoDesign.premiumShadow(opacity: 0.08, blur: 18, offset: const Offset(0, 8)),
      ),
      child: Stack(children: [

        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Transform.rotate(
            angle: Get.find<LocalizationController>().isLtr ? 0 : pi,
            child: Image.asset(
              Get.find<ThemeController>().darkTheme ? Images.couponBgDark : Images.couponBgLight,
              height: ResponsiveHelper.isMobilePhone() ? 174 : 160, width: size.width,
              fit: ResponsiveHelper.isMobilePhone() ? BoxFit.cover : BoxFit.contain,
            ),
          ),
        ),

        Container(
          alignment: Alignment.center,
          child: Row(children: [

            Container(
              alignment: Alignment.center,

              width: ResponsiveHelper.isDesktop(context) ? 150 : size.width * 0.3,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(
                  coupon.discountType == 'percent' ? Images.percentCouponOffer : coupon.couponType
                      == 'free_delivery' ? Images.freeDelivery : Images.money,
                  height: 30, width: 30,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(
                  coupon.couponType == 'free_delivery' ? 'free_delivery'.tr : '${coupon.discount}${coupon.discountType == 'percent' ? '%' : Get.find<SplashController>().configModel!.currencySymbol} ${'off'.tr}',
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault + 1, color: FoxGoDesign.graphite),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                coupon.store == null ?  Flexible(child: Text(
                  coupon.couponType == 'store_wise' ? '${'on'.tr} ${coupon.data}' : Get.find<SplashController>().module?.moduleName == 'Rental' ? "on_all_provider".tr : 'on_all_store'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )) : Flexible(child: Text(
                  coupon.couponType == 'store_wise' ? '${'on'.tr} ${coupon.data}' : coupon.couponType == 'default' ? '${coupon.store!.name}' : '',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 10 : 20),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [

                JustTheTooltip(
                  backgroundColor: FoxGoDesign.graphite,
                  controller: toolTipController?[index],
                  preferredDirection: AxisDirection.up,
                  tailLength: 14,
                  tailBaseWidth: 20,
                  triggerMode: TooltipTriggerMode.manual,
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${'code_copied'.tr} !',style: robotoRegular.copyWith(color: Theme.of(context).cardColor)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 1,
                        strokeCap: StrokeCap.butt,
                        dashPattern: const [5, 5],
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                        radius: const Radius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [

                        Flexible(
                          child: Text(
                            '${coupon.code}',
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Icon(Icons.copy_rounded, color: Theme.of(context).primaryColor, size: 20),

                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  '${DateConverter.stringDateTimeToDate(coupon.startDate!)} - ${DateConverter.stringDateTimeToDate(coupon.expireDate!)}',
                  style: robotoMedium.copyWith(color: FoxGoDesign.graphite, fontSize: Dimensions.fontSizeSmall),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [

                  Text('*', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall)),

                  Text(
                    '${'min_purchase'.tr} ',
                    style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    PriceConverter.convertPrice(coupon.minPurchase),
                    style: robotoBold.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                  ),

                ]),

                coupon.maxDiscount! > 0 ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  //
                  // Text('*', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error, fontSize: Dimensions.fontSizeSmall)),

                  Text(
                    '${'max_discount'.tr} ',
                    style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    PriceConverter.convertPrice(coupon.maxDiscount),
                    style: robotoBold.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr,
                  ),

                ]) : const SizedBox(),

              ]),
            ),

          ]),
        ),

      ]),
    );
  }
}
