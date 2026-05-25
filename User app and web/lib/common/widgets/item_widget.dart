import 'package:sixam_mart/common/widgets/cart_count_view.dart';
import 'package:sixam_mart/common/widgets/corner_banner/banner.dart';
import 'package:sixam_mart/common/widgets/corner_banner/corner_discount_tag.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_favourite_widget.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/common/widgets/not_available_widget.dart';
import 'package:sixam_mart/common/widgets/organic_tag.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemWidget extends StatelessWidget {
  final Item? item;
  final Store? store;
  final bool isStore;
  final int index;
  final int? length;
  final bool inStore;
  final bool isCampaign;
  final bool isFeatured;
  final bool fromCartSuggestion;
  final double? imageHeight;
  final double? imageWidth;
  final bool? isCornerTag;
  const ItemWidget({super.key, required this.item, required this.isStore, required this.store, required this.index,
    required this.length, this.inStore = false, this.isCampaign = false, this.isFeatured = false,
    this.fromCartSuggestion = false, this.imageHeight, this.imageWidth, this.isCornerTag = false});

  @override
  Widget build(BuildContext context) {
    final bool ltr = Get.find<LocalizationController>().isLtr;
    final bool desktop = ResponsiveHelper.isDesktop(context);
    double? discount;
    String? discountType;
    bool isAvailable;
    String genericName = '';

    if(!isStore && item?.genericName != null && item!.genericName!.isNotEmpty) {
      for (String name in item!.genericName!) {
        genericName += name;
      }
    }
    if(isStore) {
      discount = store!.discount != null ? store!.discount!.discount : 0;
      discountType = store!.discount != null ? store!.discount!.discountType : 'percent';
      isAvailable = store!.open == 1 && store!.active!;
    }else {
      discount = item!.discount;
      discountType = item!.discountType;
      isAvailable = DateConverter.isAvailable(item!.availableTimeStarts, item!.availableTimeEnds);
    }

    final double safeDiscount = discount ?? 0;

    return Stack(
      children: [
        Container(
          margin: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: FoxGoDesign.card,
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07), width: 1),
            boxShadow: FoxGoDesign.premiumShadow(opacity: 0.07, blur: 20, offset: const Offset(0, 9)),
          ),
          child: CustomInkWell(
            onTap: () {
              if(isStore) {
                if(store != null) {
                  if(isFeatured && Get.find<SplashController>().moduleList != null) {
                    for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                      if(module.id == store!.moduleId) {
                        Get.find<SplashController>().setModule(module);
                        break;
                      }
                    }
                  }
                  Get.toNamed(
                    RouteHelper.getStoreRoute(id: store!.id, page: isFeatured ? 'module' : 'item', slug: store?.slug??''),
                    arguments: StoreScreen(store: store, fromModule: isFeatured),
                  );
                }
              }else {
                if(isFeatured && Get.find<SplashController>().moduleList != null) {
                  for(ModuleModel module in Get.find<SplashController>().moduleList!) {
                    if(module.id == item!.moduleId) {
                      Get.find<SplashController>().setModule(module);
                      break;
                    }
                  }
                }
                Get.find<ItemController>().navigateToItemPage(item, context, inStore: inStore, isCampaign: isCampaign);
              }
            },
            radius: 28,
            padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.all(fromCartSuggestion ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall) : const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: TextHover(
              builder: (hovered) {
                return Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                  Expanded(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: desktop ? 0 : Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [

                      Stack(children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: FoxGoDesign.premiumShadow(opacity: 0.08, blur: 14, offset: const Offset(0, 6)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CustomImage(
                              isHovered: hovered,
                              image: '${isStore ? store != null ? store!.logoFullUrl : '' : item!.imageFullUrl}',
                              height: imageHeight ?? (desktop ? 132 : length == null ? 112 : 102),
                              width: imageWidth ?? (desktop ? 132 : 102),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        (isStore || isCornerTag!) ? DiscountTag(
                          discount: discount, discountType: discountType,
                          freeDelivery: isStore ? store!.freeDelivery : false,
                        ) : const SizedBox(),

                        !isStore ? OrganicTag(item: item!, placeInImage: true) : const SizedBox(),

                        isAvailable ? const SizedBox() : NotAvailableWidget(isStore: isStore),

                        Positioned(
                          top: 7, left: 7,
                          child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                            bool isWished = isStore ? favouriteController.wishStoreIdList.contains(store!.id) : favouriteController.wishItemIdList.contains(item!.id);
                            return CustomFavouriteWidget(
                              isWished: isWished,
                              isStore: isStore,
                              store: store,
                              item: item,
                            );
                          }),
                        ),
                      ]),
                      const SizedBox(width: Dimensions.paddingSizeDefault),

                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Flexible(
                              child: Text(
                                isStore ? store!.name! : item!.name!,
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.12, color: FoxGoDesign.graphite),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            (!isStore && Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!)
                                ? Image.asset(item != null && item!.veg == 0 ? Images.nonVegImage : Images.vegImage,
                                height: 10, width: 10, fit: BoxFit.contain) : const SizedBox(),

                            (!isStore && Get.find<SplashController>().configModel!.moduleConfig!.module!.unit! && item != null && item!.unitType != null) ? Text(
                              '(${ item!.unitType ?? ''})',
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor),
                            ) : const SizedBox(),

                            SizedBox(width: !isStore && item != null && item!.isStoreHalalActive! && item!.isHalalItem! ? Dimensions.paddingSizeExtraSmall : 0),

                            !isStore && item != null && item!.isStoreHalalActive! && item!.isHalalItem! ? const CustomAssetImageWidget(
                                Images.halalTag, height: 13, width: 13) : const SizedBox(),

                            SizedBox(width: ResponsiveHelper.isDesktop(context) ? 20 : 0),
                          ]),
                          const SizedBox(height: 5),

                          inStore ? const SizedBox() : (isStore ? store!.address != null : item!.storeName != null) ? Text(
                            isStore ? store!.address ?? '' : item!.storeName ?? '',
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: FoxGoDesign.textMuted,
                              height: 1.15,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ) : const SizedBox(),

                          (genericName.isNotEmpty) ? Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                genericName,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: FoxGoDesign.textMuted,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ) : const SizedBox(),
                          const SizedBox(height: 7),

                          isStore && (store != null && store!.ratingCount! > 0) ? Row(children: [

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: FoxGoDesign.softRed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.star_rounded, size: 15, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 3),
                                Text(store!.avgRating!.toStringAsFixed(1), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                              ]),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Flexible(child: Text('(${store!.ratingCount})', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: FoxGoDesign.textMuted))),

                          ]) : !isStore && (item!.ratingCount! > 0) ? Row(children: [

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: FoxGoDesign.softRed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.star_rounded, size: 15, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 3),
                                Text(item!.avgRating!.toStringAsFixed(1), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor)),
                              ]),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text('(${item!.ratingCount})', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: FoxGoDesign.textMuted)),

                          ]) : const SizedBox(),

                          SizedBox(height: !isStore ? Dimensions.paddingSizeExtraSmall : 0),

                          !isStore ? Row(children: [
                            Flexible(
                              child: Text(
                                PriceConverter.convertPrice(item!.price, discount: discount, discountType: discountType),
                                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault + 1, color: Theme.of(context).primaryColor), textDirection: TextDirection.ltr,
                              ),
                            ),
                            SizedBox(width: safeDiscount > 0 ? Dimensions.paddingSizeExtraSmall : 0),

                            safeDiscount > 0 ? Flexible(child: Text(
                              PriceConverter.convertPrice(item!.price),
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: FoxGoDesign.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ), textDirection: TextDirection.ltr,
                            )) : const SizedBox(),
                          ]) : const SizedBox(),

                        ]),
                      ),

                      !isStore && item != null ? Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        const SizedBox(),

                        Container(
                          decoration: BoxDecoration(
                            color: FoxGoDesign.softRed,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: CartCountView(
                            item: item!,
                            index: index,
                          ),
                        ),

                      ]) : const SizedBox(),

                    ]),
                  )),

                ]);
              }
            ),
          ),
        ),

        (!isStore && isCornerTag! == false) ? Positioned(
          right: ltr ? 0 : null, left: ltr ? null : 0,
          child: CornerDiscountTag(
            bannerPosition: ltr ? CornerBannerPosition.topRight : CornerBannerPosition.topLeft,
            elevation: 0,
            discount: discount, discountType: discountType,
            freeDelivery: isStore ? store!.freeDelivery : false,
        )) : const SizedBox(),

      ],
    );
  }
}
