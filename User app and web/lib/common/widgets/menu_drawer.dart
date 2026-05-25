import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/hover/on_hover.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/auth_dialog_widget.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  MenuDrawerState createState() => MenuDrawerState();
}

class MenuDrawerState extends State<MenuDrawer> with SingleTickerProviderStateMixin {
  final List<Menu> _menuList = [
    Menu(icon: Images.profile, title: 'profile'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getProfileRoute());
    }),
    Menu(icon: Images.orders, title: 'my_orders'.tr, onTap: () {
      Get.back();
      Get.offAllNamed(RouteHelper.getOrderRoute());
    }),
    Menu(icon: Images.location, title: 'my_address'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getAddressRoute());
    }),
    Menu(icon: Images.coupon, title: 'coupon'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getCouponRoute());
    }),
    Menu(icon: Images.support, title: 'help_support'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getSupportRoute());
    }),
    Menu(icon: Images.chat, title: 'live_chat'.tr, onTap: () {
      Get.back();
      Get.toNamed(RouteHelper.getConversationRoute());
    }),
  ];

  static const _initialDelayTime = Duration(milliseconds: 200);
  static const _itemSlideTime = Duration(milliseconds: 250);
  static const _staggerTime = Duration(milliseconds: 50);
  static const _buttonDelayTime = Duration(milliseconds: 150);
  static const _buttonTime = Duration(milliseconds: 500);
  final _animationDuration = _initialDelayTime + (_staggerTime * 7) + _buttonDelayTime + _buttonTime;

  late AnimationController _staggeredController;
  final List<Interval> _itemSlideIntervals = [];

  @override
  void initState() {
    super.initState();

    if(Get.find<SplashController>().configModel != null) {
      if (Get.find<SplashController>().configModel!.refundPolicyStatus == 1) {
        _menuList.add(Menu(icon: Images.refund, title: 'refund_policy'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.refundPolicy);
        }));
      }
      if (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1) {
        _menuList.add(Menu(icon: Images.cancellation, title: 'cancellation_policy'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.cancellationPolicy);
        }));
      }
      if (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1) {
        _menuList.add(Menu(icon: Images.shippingPolicy, title: 'shipping_policy'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.shippingPolicy);
        }));
      }

      if (Get.find<SplashController>().configModel!.customerWalletStatus == 1) {
        _menuList.add(Menu(icon: Images.wallet, title: 'wallet'.tr, onTap: () {
          if (Get.currentRoute.contains('wallet')) {
            Get.back();
          }
          Get.back();
          Get.toNamed(RouteHelper.getWalletRoute());
        }));
      }

      if (Get.find<SplashController>().configModel!.loyaltyPointStatus == 1) {
        _menuList.add(Menu(icon: Images.loyal, title: 'loyalty_points'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.getLoyaltyRoute());
        }));
      }
      if (Get.find<SplashController>().configModel!.refEarningStatus == 1) {
        _menuList.add(Menu(icon: Images.referCode, title: 'refer_and_earn'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.getReferAndEarnRoute());
        }));
      }
      if (Get.find<SplashController>().configModel!.toggleDmRegistration ?? false) {
        _menuList.add(Menu(
            icon: Images.deliveryManJoin, title: 'join_as_a_delivery_man'.tr, onTap: () {
          Get.back();
          Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
        }));
      }
      if (Get.find<SplashController>().configModel!.toggleStoreRegistration ?? false) {
        _menuList.add(Menu(
          icon: Images.restaurantJoin,
          title: (Get.find<SplashController>().configModel!.moduleConfig?.module?.showRestaurantText ?? false)
              ? 'join_as_a_restaurant'.tr
              : 'join_as_a_store'.tr,
          onTap: () {
            Get.back();
            Get.toNamed(RouteHelper.getRestaurantRegistrationRoute());
          },
        ));
      }


    }

    _menuList.add(Menu(icon: Images.logOut, title: AuthHelper.isLoggedIn() ? 'logout'.tr : 'sign_in'.tr, onTap: () {
      Get.back();
      if(AuthHelper.isLoggedIn()) {
        Get.dialog(ConfirmationDialog(icon: Images.support, description: 'are_you_sure_to_logout'.tr, isLogOut: true, onYesPressed: () async {
          Get.find<AuthController>().resetOtpView();
          Get.find<ProfileController>().clearUserInfo();
          await Get.find<AuthController>().clearSharedData();
          Get.find<CartController>().clearCartList();
          Get.find<AuthController>().socialLogout();
          Get.find<FavouriteController>().removeFavourite();
          if(ResponsiveHelper.isDesktop(Get.context)) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }else{
            Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
          }
        }), useSafeArea: false);
      }else {
        Get.find<FavouriteController>().removeFavourite();
        if(ResponsiveHelper.isDesktop(context)){
          Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)), barrierDismissible: false);
        }else{
          Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.main));
        }
      }
    }));

    _createAnimationIntervals();

    _staggeredController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();
  }

  void _createAnimationIntervals() {
    for (var i = 0; i < _menuList.length; ++i) {
      final startTime = _initialDelayTime + (_staggerTime * i);
      final endTime = startTime + _itemSlideTime;
      _itemSlideIntervals.add(
        Interval(
          startTime.inMilliseconds / _animationDuration.inMilliseconds,
          endTime.inMilliseconds / _animationDuration.inMilliseconds,
        ),
      );
    }
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? _buildContent() : const SizedBox();
  }

  Widget _buildContent() {
    return Align(alignment: Get.find<LocalizationController>().isLtr ? Alignment.topRight : Alignment.topLeft, child: Container(
      width: 330,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 16, 22),
          decoration: BoxDecoration(
            gradient: FoxGoDesign.redGradient(),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            boxShadow: FoxGoDesign.premiumShadow(opacity: 0.14, blur: 22, offset: const Offset(0, 10)),
          ),
          alignment: Alignment.centerLeft,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SvgPicture.asset(Images.foxGoLogoLight, width: 150),
              IconButton(
                padding: const EdgeInsets.all(0),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16)),
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 18),
            Text('Menu Fox GO', style: robotoBold.copyWith(fontSize: 22, color: Colors.white, height: 1.05)),
            const SizedBox(height: 6),
            Text('Acesse sua conta, pedidos, carteira e benefícios.', style: robotoRegular.copyWith(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.88), height: 1.25)),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _menuList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _staggeredController,
                builder: (context, child) {
                  final animationPercent = Curves.easeOut.transform(
                    _itemSlideIntervals[index].transform(_staggeredController.value),
                  );
                  final opacity = animationPercent;
                  final slideDistance = (1.0 - animationPercent) * 150;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(slideDistance, 0),
                      child: child,
                    ),
                  );
                },
                child: OnHover(
                  isItem: true,
                  fromMenu: true,
                  child: InkWell(
                    onTap: _menuList[index].onTap as void Function()?,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.06)),
                        boxShadow: FoxGoDesign.premiumShadow(opacity: 0.055, blur: 14, offset: const Offset(0, 6)),
                      ),
                      child: Row(children: [
                        Container(
                          height: 48, width: 48, alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: index != _menuList.length-1
                                ? FoxGoDesign.softRed
                                : AuthHelper.isLoggedIn()
                                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.10)
                                    : Colors.green.withValues(alpha: 0.10),
                          ),
                          child: Image.asset(
                            _menuList[index].icon,
                            color: index != _menuList.length-1
                                ? Theme.of(context).primaryColor
                                : AuthHelper.isLoggedIn()
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.green,
                            height: 24,
                            width: 24,
                          ),
                        ),
                        const SizedBox(width: 13),

                        Expanded(child: Text(
                          _menuList[index].title,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )),
                        Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor, size: 22),

                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    ));
  }
}

class Menu {
  String icon;
  String title;
  Function onTap;

  Menu({required this.icon, required this.title, required this.onTap});
}
