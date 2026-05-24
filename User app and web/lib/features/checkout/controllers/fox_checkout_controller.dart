import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/checkout/widgets/order_successfull_dialog.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class FoxCheckoutController extends CheckoutController {
  FoxCheckoutController({required CheckoutServiceInterface checkoutServiceInterface})
      : super(checkoutServiceInterface: checkoutServiceInterface);

  @override
  void callback(
    bool isSuccess,
    String? message,
    String orderID,
    int? zoneID,
    double amount,
    double? maximumCodOrderAmount,
    bool fromCart,
    bool isCashOnDeliveryActive,
    String? contactNumber,
    String userID,
  ) async {
    if (isSuccess) {
      if (fromCart) {
        Get.find<CartController>().clearCartList();
      }
      setGuestAddress(null);
      if (!Get.find<OrderController>().showBottomSheet) {
        Get.find<OrderController>().showRunningOrders(canUpdate: false);
      }
      if (isDmTipSave) {
        saveSharedPrefDmTipIndex(selectedTips.toString());
      }
      stopLoader(canUpdate: false);
      HomeScreen.loadData(true);

      if (paymentMethodIndex == 2) {
        await Get.find<AuthController>().saveGuestNumber(contactNumber ?? '');
        _openInternalPaymentRoute(
          orderID: orderID,
          userID: userID,
          orderType: orderType,
          amount: amount,
          isCashOnDeliveryActive: isCashOnDeliveryActive,
          paymentMethod: digitalPaymentName,
          contactNumber: contactNumber,
          createAccount: isCreateAccount,
        );
      } else {
        _redirectAfterSuccessfulNonDigitalOrder(
          orderID: orderID,
          amount: amount,
          contactNumber: contactNumber,
        );
      }

      clearPrevData();
      Get.find<CouponController>().removeCouponData(false);
      updateTips(
        getSharedPrefDmTipIndex().isNotEmpty ? int.parse(getSharedPrefDmTipIndex()) : 0,
        notify: false,
      );
    } else {
      showCustomSnackBar(message);
    }
  }

  @override
  Future<void> paymentAfterDigitalCancel(PaymentModel paymentData, bool fromHome) async {
    Get.find<SplashController>().togglePaymentIncompleteBottomSheet(false);
    if (paymentMethodIndex == 0) {
      bool isSuccess = await Get.find<OrderController>().switchToCOD(paymentData.orderID, guestId: paymentData.guestId);
      if (isSuccess) {
        _redirection(paymentData, fromHome);
      }
    } else if (paymentMethodIndex == 1) {
      debugPrint('------wallet selected');
      bool isSuccess = await Get.find<OrderController>().switchToWalletPayment(paymentData.orderID);
      if (isSuccess) {
        _redirection(paymentData, fromHome);
      }
    } else if (paymentMethodIndex == 2) {
      _openInternalPaymentRoute(
        orderID: paymentData.orderID!,
        userID: paymentData.userId?.toString() ?? '',
        orderType: paymentData.orderType,
        amount: paymentData.orderAmount!,
        isCashOnDeliveryActive: paymentData.isCashOnDeliveryActive,
        paymentMethod: digitalPaymentName,
        contactNumber: paymentData.contactNumber,
        guestId: paymentData.guestId,
        createAccount: isCreateAccount,
      );
    } else if (paymentMethodIndex == 3) {
      debugPrint('------offline selected');
      if (Get.isBottomSheetOpen!) {
        Get.back();
      }
      Get.toNamed(RouteHelper.getOfflinePaymentScreen(
        zoneId: paymentData.zoneId,
        total: paymentData.orderAmount!,
        orderId: paymentData.orderID!,
        contactNumber: paymentData.contactNumber ?? '',
        maxCodOrderAmount: paymentData.maxCodOrderAmount,
        fromCart: false,
        isCodActive: paymentData.isCashOnDeliveryActive,
        forParcel: paymentData.orderType == 'parcel',
      ));
    }
    clearPrevData();
    Get.find<CouponController>().removeCouponData(false);
  }

  void _openInternalPaymentRoute({
    required String orderID,
    required String userID,
    required String? orderType,
    required double amount,
    required bool? isCashOnDeliveryActive,
    required String? paymentMethod,
    required String? contactNumber,
    String? guestId,
    bool createAccount = false,
  }) {
    final int? createdUserId = int.tryParse(userID);
    final int paymentUserId = Get.find<ProfileController>().userInfoModel?.id ?? createdUserId ?? 0;
    final String resolvedGuestId = guestId?.isNotEmpty == true ? guestId! : (userID.isNotEmpty ? userID : AuthHelper.getGuestId());

    Get.offNamed(RouteHelper.getPaymentRoute(
      orderID,
      paymentUserId,
      orderType,
      amount,
      isCashOnDeliveryActive,
      paymentMethod,
      guestId: resolvedGuestId,
      contactNumber: contactNumber,
      createAccount: createAccount,
      createUserId: createdUserId,
    ));
  }

  void _redirectAfterSuccessfulNonDigitalOrder({
    required String orderID,
    required double amount,
    required String? contactNumber,
  }) {
    double total = ((amount / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
    if (AuthHelper.isLoggedIn()) {
      Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
    }
    if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()) {
      Get.offNamed(RouteHelper.getInitialRoute());
      Future.delayed(
        const Duration(seconds: 2),
        () => Get.dialog(Center(child: SizedBox(height: 350, width: 500, child: OrderSuccessfulDialog(orderID: orderID)))),
      );
    } else {
      Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: isCreateAccount));
    }
  }

  void _redirection(PaymentModel paymentData, bool fromHome) {
    Get.find<SplashController>().savePaymentIncompleteSheetStatus(false);
    double total = ((paymentData.orderAmount! / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
    if (AuthHelper.isLoggedIn()) {
      Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
    }
    if (Get.currentRoute.contains(RouteHelper.orderDetails)) {
      Get.back();
    } else if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()) {
      if (fromHome && Get.isDialogOpen!) {
        Get.back();
      } else {
        Get.offNamed(RouteHelper.getInitialRoute());
        Future.delayed(
          const Duration(seconds: 2),
          () => Get.dialog(Center(child: SizedBox(height: 350, width: 500, child: OrderSuccessfulDialog(orderID: paymentData.orderID)))),
        );
      }
    } else {
      Get.offNamed(RouteHelper.getOrderSuccessRoute(paymentData.orderID!, paymentData.contactNumber, createAccount: isCreateAccount));
    }
  }
}
