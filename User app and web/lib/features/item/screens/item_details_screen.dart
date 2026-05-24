import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/readmore_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/widgets/details_app_bar_widget.dart';
import 'package:sixam_mart/features/item/widgets/details_web_view_widget.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/features/item/widgets/item_title_view_widget.dart';

class ItemDetailsScreen extends StatefulWidget {
  final int itemId;
  final bool inStorePage;
  final bool isCampaign;
  const ItemDetailsScreen({super.key, required this.itemId, required this.inStorePage, this.isCampaign = false});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final Size size = Get.size;
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  final GlobalKey<DetailsAppBarWidgetState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    Get.find<ItemController>().getItemDetails(itemId: widget.itemId, isCampaign: widget.isCampaign);
    Get.find<ItemController>().setSelect(0, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if(Get.find<SplashController>().deeplinkRoute != null) {
          Get.find<SplashController>().setDeeplink(null);
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          Get.back();
        }
      },
      child: GetBuilder<CartController>(builder: (cartController) {
        return GetBuilder<ItemController>(builder: (itemController) {

          Item? item = itemController.item;

          int? stock = 0;
          CartModel? cartModel;
          OnlineCart? cart;
          double priceWithAddons = 0;
          int? cartId = cartController.getCartId(itemController.cartIndex);
          if(item != null && itemController.variationIndex != null){
            List<String> variationList = [];
            for (int index = 0; index < item.choiceOptions!.length; index++) {
              variationList.add(item.choiceOptions![index].options![itemController.variationIndex![index]].replaceAll(' ', ''));
            }
            String variationType = '';
            bool isFirst = true;
            for (var variation in variationList) {
              if (isFirst) {
                variationType = '$variationType$variation';
                isFirst = false;
              } else {
                variationType = '$variationType-$variation';
              }
            }

            double? price = item.price;
            Variation? variation;
            stock = item.stock ?? 0;
            for (Variation v in item.variations!) {
              if (v.type == variationType) {
                price = v.price;
                variation = v;
                stock = v.stock;
                break;
              }
            }

            double? discount = item.discount;
            String? discountType = item.discountType;
            double priceWithDiscount = PriceConverter.convertWithDiscount(price, discount, discountType)!;
            double priceWithQuantity = priceWithDiscount * itemController.quantity!;
            double addonsCost = 0;
            List<AddOn> addOnIdList = [];
            List<AddOns> addOnsList = [];
            for (int index = 0; index < item.addOns!.length; index++) {
              if (itemController.addOnActiveList[index]) {
                addonsCost = addonsCost + (item.addOns![index].price! * itemController.addOnQtyList[index]!);
                addOnIdList.add(AddOn(id: item.addOns![index].id, quantity: itemController.addOnQtyList[index]));
                addOnsList.add(item.addOns![index]);
              }
            }

            cartModel = CartModel(
              null, price, priceWithDiscount, variation != null ? [variation] : [], [],
              (price! - PriceConverter.convertWithDiscount(price, discount, discountType)!),
              itemController.quantity, addOnIdList, addOnsList, item.availableDateStarts != null, stock, item,
              item.quantityLimit,
            );

            List<int?> listOfAddOnId = _getSelectedAddonIds(addOnIdList: addOnIdList);
            List<int?> listOfAddOnQty = _getSelectedAddonQtnList(addOnIdList: addOnIdList);

            cart = OnlineCart(
              cartId, widget.itemId, null, priceWithDiscount.toString(), '',
              variation != null ? [variation] : [], null,
              itemController.cartIndex != -1 ? cartController.cartList[itemController.cartIndex].quantity
                : itemController.quantity, listOfAddOnId, addOnsList, listOfAddOnQty, 'Item'
            );
            priceWithAddons = priceWithQuantity + (Get.find<SplashController>().configModel!.moduleConfig!.module!.addOn! ? addonsCost : 0);
          }

          return Scaffold(
            key: _globalKey,
            backgroundColor: FoxGoDesign.softBackground,
            endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
            appBar: ResponsiveHelper.isDesktop(context)? const CustomAppBar(title: '') : DetailsAppBarWidget(key: _key),

            body: SafeArea(child: (item != null) ? ResponsiveHelper.isDesktop(context) ? DetailsWebViewWidget(
              cartModel: cartModel, stock: stock, priceWithAddOns: priceWithAddons, cart: cart,
            ) : Column(children: [
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge),
                physics: const BouncingScrollPhysics(),
                child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: FoxGoDesign.card,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07), width: 1),
                          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.10, blur: 24, offset: const Offset(0, 10)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ItemImageViewWidget(item: item, isCampaign: widget.isCampaign),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: FoxGoDesign.card,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07), width: 1),
                          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.065, blur: 18, offset: const Offset(0, 8)),
                        ),
                        child: Builder(
                          builder: (context) {
                            return ItemTitleViewWidget(
                              item: item, inStorePage: widget.inStorePage, isCampaign: item.availableDateStarts != null,
                              isOutOfStock: (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && stock! <= 0),
                            );
                          }
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      item.isPrescriptionRequired! ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '* ${'prescription_required'.tr}',
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error),
                        ),
                      ) : const SizedBox(),

                      (item.description != null && item.description!.isNotEmpty) ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: FoxGoDesign.card,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.06)),
                          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.045, blur: 14, offset: const Offset(0, 7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('description'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: FoxGoDesign.graphite)),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            ReadMoreText(
                              item.description!,
                              style: robotoRegular.copyWith(color: FoxGoDesign.textMuted, fontSize: Dimensions.fontSizeDefault, height: 1.38),
                              trimMode: TrimMode.Line,
                              trimLines: 3,
                              colorClickableText: Theme.of(context).primaryColor,
                              lessStyle: robotoBold.copyWith(color: Theme.of(context).primaryColor),
                              trimCollapsedText: 'read_more'.tr,
                              moreStyle: robotoBold.copyWith(color: Theme.of(context).primaryColor, decoration: TextDecoration.none),
                              trimExpandedText: ' ${'show_less'.tr}',
                            ),
                          ],
                        ),
                      ) : const SizedBox(),
                      (item.description != null && item.description!.isNotEmpty) ? const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),

                      (item.nutritionsName != null && item.nutritionsName!.isNotEmpty) ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('nutrition_details'.tr, style: robotoBold),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Wrap(children: List.generate(item.nutritionsName!.length, (index) {
                            return Text(
                              '${item.nutritionsName![index]}${item.nutritionsName!.length-1 == index ? '.' : ', '}',
                              style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                            );
                          })),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ) : const SizedBox(),

                      (item.allergiesName != null && item.allergiesName!.isNotEmpty) ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('allergic_ingredients'.tr, style: robotoBold),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Wrap(children: List.generate(item.allergiesName!.length, (index) {
                            return Text(
                              '${item.allergiesName![index]}${item.allergiesName!.length-1 == index ? '.' : ', '}',
                              style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                            );
                          })),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ) : const SizedBox(),

                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: item.choiceOptions!.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.choiceOptions![index].title!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: FoxGoDesign.graphite)),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                            SizedBox(
                              height: 42,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                  itemCount: item.choiceOptions![index].options!.length,
                                  itemBuilder: (context, i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                                      child: InkWell(
                                        onTap: () {
                                          itemController.setCartVariationIndex(index, i, item);
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            color: itemController.variationIndex![index] != i ? FoxGoDesign.card : Theme.of(context).primaryColor,
                                            border: Border.all(color: itemController.variationIndex![index] != i ? Theme.of(context).primaryColor.withValues(alpha: 0.10) : Theme.of(context).primaryColor, width: 1),
                                          ),
                                          child: Text(
                                            item.choiceOptions![index].options![i].trim(), maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: itemController.variationIndex![index] != i ? robotoMedium.copyWith(
                                              color: FoxGoDesign.textMuted,
                                            ) : robotoBold.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    );
                              }),
                            ),
                            SizedBox(height: index != item.choiceOptions!.length-1 ? Dimensions.paddingSizeLarge : 0),
                          ]);
                        },
                      ),
                      item.choiceOptions!.isNotEmpty ? const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),


                    ],
                  ))),
              )),

              Container(
                decoration: BoxDecoration(
                  color: FoxGoDesign.card,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.06))),
                  boxShadow: FoxGoDesign.premiumShadow(opacity: 0.12, blur: 24, offset: const Offset(0, -8)),
                ),
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                child: Column(
                  children: [
                    Container(width: 42, height: 4, margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall), decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999))),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('total_amount'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite)),

                      Text(
                        PriceConverter.convertPrice(itemController.cartIndex != -1
                            ? _getItemDetailsDiscountPrice(cart: Get.find<CartController>().cartList[itemController.cartIndex])
                            : priceWithAddons), textDirection: TextDirection.ltr,
                        style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeExtraLarge),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(
                      children: [

                        GetBuilder<CartController>(
                            builder: (cartController) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: FoxGoDesign.softRed,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(children: [
                                  InkWell(
                                    onTap: cartController.isLoading ? null : () {
                                      if(itemController.cartIndex != -1) {
                                        if(cartController.cartList[itemController.cartIndex].quantity! > 1) {
                                          cartController.setQuantity(false, itemController.cartIndex, stock, cartController.cartList[itemController.cartIndex].quantity);
                                        }
                                      }else {
                                        if(itemController.quantity! > 1) {
                                          itemController.setQuantity(false, stock, item.quantityLimit);
                                        }
                                      }
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(9),
                                      child: Icon(Icons.remove, size: 19, color: Theme.of(context).primaryColor),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                    child: Text(
                                      itemController.cartIndex != -1 ? cartController.cartList[itemController.cartIndex].quantity.toString()
                                          : itemController.quantity.toString(),
                                      style:robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: FoxGoDesign.graphite),
                                    ),
                                  ),

                                  InkWell(
                                    onTap: cartController.isLoading ? null : () => itemController.cartIndex != -1
                                        ? cartController.setQuantity(true, itemController.cartIndex, stock, cartController.cartList[itemController.cartIndex].quantityLimit)
                                        : itemController.setQuantity(true, stock, item.quantityLimit),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(9),
                                      child: const Icon(Icons.add, size: 19, color: Colors.white),
                                    ),
                                  ),
                                ]),
                              );
                            }
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Expanded(
                          child: GetBuilder<CartController>(
                            builder: (cartController) {
                              return Container(
                                width: 1170,
                                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                child: CustomButton(
                                  isLoading: cartController.isLoading,
                                  buttonText: (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && stock! <= 0) ? 'out_of_stock'.tr
                                      : item.availableDateStarts != null ? 'order_now'.tr : itemController.cartIndex != -1 ? 'update_in_cart'.tr : 'add_to_cart'.tr,
                                  onPressed: (!Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! || stock! > 0) ?  () async {

                                    if(AddressHelper.getUserAddressFromSharedPref() == null) {
                                      Get.find<LocationController>().navigateToLocationScreen('home', canRoute: true);
                                      return;
                                    }

                                    if(!Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! || stock! > 0) {
                                      if(item.availableDateStarts != null) {
                                        Get.toNamed(RouteHelper.getCheckoutRoute('campaign'), arguments: CheckoutScreen(
                                          storeId: null, fromCart: false, cartList: [cartModel],
                                        ));
                                      }else {
                                        if (cartController.existAnotherStoreItem(cartModel!.item!.storeId, Get.find<SplashController>().module == null ? Get.find<SplashController>().cacheModule!.id : Get.find<SplashController>().module!.id)) {
                                          Get.dialog(ConfirmationDialog(
                                            icon: Images.warning,
                                            title: 'are_you_sure_to_reset'.tr,
                                            description: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                                                ? 'if_you_continue'.tr : 'if_you_continue_without_another_store'.tr,
                                            onYesPressed: () {
                                              Get.back();
                                              cartController.clearCartOnline().then((success) async {
                                                if(success) {
                                                  await cartController.addToCartOnline(cart!);
                                                  itemController.setExistInCart(item, null);
                                                  showCartSnackBar();
                                                }
                                              });

                                            },
                                          ), barrierDismissible: false);
                                        } else {
                                          if(itemController.cartIndex == -1) {
                                            await cartController.addToCartOnline(cart!).then((success) {
                                              if(success){
                                                itemController.setExistInCart(item, null);
                                                showCartSnackBar();
                                                _key.currentState!.shake();
                                              }
                                            });
                                          } else {
                                            await cartController.updateCartOnline(cart!).then((success) {
                                              if(success) {
                                                showCartSnackBar();
                                                _key.currentState!.shake();
                                              }
                                            });
                                          }

                                        }
                                      }
                                    }
                                  } : null,
                                ),
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ]) : const Center(child: CircularProgressIndicator())),
          );
        });
      }),
    );
  }

  List<int?> _getSelectedAddonIds({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnId = [];
    for (var addOn in addOnIdList) {
      listOfAddOnId.add(addOn.id);
    }
    return listOfAddOnId;
  }

  List<int?> _getSelectedAddonQtnList({required List<AddOn> addOnIdList }) {
    List<int?> listOfAddOnQty = [];
    for (var addOn in addOnIdList) {
      listOfAddOnQty.add(addOn.quantity);
    }
    return listOfAddOnQty;
  }

  double _getItemDetailsDiscountPrice({required CartModel cart}) {
    double discountedPrice = 0;

    double? discount = cart.item!.discount;
    String? discountType = cart.item!.discountType;
    String variationType = cart.variation != null && cart.variation!.isNotEmpty ? cart.variation![0].type! : '';

    if(cart.variation != null && cart.variation!.isNotEmpty){
      for (Variation variation in cart.item!.variations!) {
        if (variation.type == variationType) {
          discountedPrice = (PriceConverter.convertWithDiscount(variation.price!, discount, discountType)! * cart.quantity!);
          break;
        }
      }
    } else {
      discountedPrice = (PriceConverter.convertWithDiscount(cart.item!.price!, discount, discountType)! * cart.quantity!);
    }

    return discountedPrice;
  }

}

class QuantityButton extends StatelessWidget {
  final bool isIncrement;
  final int? quantity;
  final bool isCartWidget;
  final int? stock;
  final bool isExistInCart;
  final int cartIndex;
  final int? quantityLimit;
  final CartController cartController;
  const QuantityButton({super.key,
    required this.isIncrement,
    required this.quantity,
    required this.stock,
    required this.isExistInCart,
    required this.cartIndex,
    this.isCartWidget = false,
    this.quantityLimit,
    required this.cartController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: cartController.isLoading ? null : () {
        if(isExistInCart) {
          if (!isIncrement && quantity! > 1) {
            Get.find<CartController>().setQuantity(false, cartIndex, stock, quantityLimit);
          } else if (isIncrement && quantity! > 0) {
            if(quantity! < stock! || !Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!) {
              Get.find<CartController>().setQuantity(true, cartIndex, stock, quantityLimit);
            }else {
              showCustomSnackBar('out_of_stock'.tr);
            }
          }
        } else {
          if (!isIncrement && quantity! > 1) {
            Get.find<ItemController>().setQuantity(false, stock, quantityLimit);
          } else if (isIncrement && quantity! > 0) {
            if(quantity! < stock! || !Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!) {
              Get.find<ItemController>().setQuantity(true, stock, quantityLimit);
            }else {
              showCustomSnackBar('out_of_stock'.tr);
            }
          }

        }
      },
      child: Container(
        height: 36, width: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (quantity! == 1 && !isIncrement) || cartController.isLoading ? FoxGoDesign.softRed : Theme.of(context).primaryColor,
        ),
        child: Center(
          child: Icon(
            isIncrement ? Icons.add : Icons.remove,
            color: isIncrement ? Colors.white : quantity! == 1 ? Theme.of(context).disabledColor : Colors.white,
            size: isCartWidget ? 26 : 20,
          ),
        ),
      ),
    );
  }
}
