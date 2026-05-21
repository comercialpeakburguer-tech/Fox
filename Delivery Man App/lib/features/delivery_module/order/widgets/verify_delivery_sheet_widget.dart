import 'dart:async';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyDeliverySheetWidget extends StatefulWidget {
  final OrderModel currentOrderModel;
  final bool? verify;
  final bool? cod;
  final double? orderAmount;
  final bool isSenderPay;
  final bool? isParcel;
  final bool? isSetOtp;
  const VerifyDeliverySheetWidget({super.key, required this.currentOrderModel, required this.verify, required this.orderAmount,
    required this.cod, this.isSenderPay = false, this.isParcel = false, this.isSetOtp = true});

  @override
  State<VerifyDeliverySheetWidget> createState() => _VerifyDeliverySheetWidgetState();
}

class _VerifyDeliverySheetWidgetState extends State<VerifyDeliverySheetWidget> {
  Timer? _timer;
  int _seconds = 0;

  bool get _isPickupStep => widget.currentOrderModel.orderStatus == AppConstants.handover || widget.currentOrderModel.orderStatus == 'handover';
  bool get _isParcel => widget.isParcel == true;

  @override
  void initState() {
    super.initState();
    if(widget.isSetOtp!) {
      Get.find<OrderController>().setOtp('');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      if(mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey.shade900 : Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: GetBuilder<OrderController>(builder: (orderController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                height: 5,
                width: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 18),
              widget.verify! ? _otpContent(context, orderController) : _completeContent(context),
              const SizedBox(height: 18),
              !orderController.isLoading ? CustomButtonWidget(
                buttonText: widget.verify! ? (_isPickupStep ? 'Confirmar retirada' : 'Confirmar entrega') : 'ok'.tr,
                radius: 18,
                height: 52,
                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                onPressed: (widget.verify! && orderController.otp.length != 4) ? null : () => _submit(orderController),
              ) : const Center(child: CircularProgressIndicator()),
              if(widget.verify!) _resendRow(context),
            ]),
          ),
        );
      }),
    );
  }

  Widget _otpContent(BuildContext context, OrderController orderController) {
    final Color primary = Theme.of(context).primaryColor;
    final String title = _isPickupStep
        ? (_isParcel ? 'OTP de retirada da encomenda' : 'OTP de retirada')
        : (_isParcel ? 'OTP de entrega da encomenda' : 'OTP de entrega');
    final String description = _isPickupStep
        ? 'Digite o código informado no local de retirada para confirmar a coleta com segurança.'
        : 'Digite o código informado pelo cliente para concluir a entrega.';

    return Column(children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(_isPickupStep ? Icons.inventory_2_rounded : Icons.verified_user_rounded, color: primary, size: 38),
      ),
      const SizedBox(height: 16),
      Text(title, style: robotoBold.copyWith(fontSize: 24, color: Colors.black), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(description, style: robotoRegular.copyWith(color: const Color(0xFF646464), fontSize: Dimensions.fontSizeDefault, height: 1.35), textAlign: TextAlign.center),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Column(children: [
          SizedBox(
            width: 220,
            child: PinCodeTextField(
              length: 4,
              appContext: context,
              keyboardType: TextInputType.number,
              animationType: AnimationType.slide,
              textStyle: robotoBold.copyWith(fontSize: 22, color: Colors.black),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                fieldHeight: 48,
                fieldWidth: 44,
                borderWidth: 1.4,
                borderRadius: BorderRadius.circular(14),
                selectedColor: primary,
                selectedFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                inactiveColor: const Color(0xFFD8D8D8),
                activeColor: primary,
                activeFillColor: Colors.white,
              ),
              animationDuration: const Duration(milliseconds: 300),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              onChanged: (String text) => orderController.setOtp(text),
              beforeTextPaste: (text) => true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isPickupStep ? 'Confirme o código antes de sair do local.' : 'Preserve a foto/prova quando for solicitada pelo pedido.',
            style: robotoRegular.copyWith(color: const Color(0xFF777777), fontSize: Dimensions.fontSizeSmall),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    ]);
  }

  Widget _completeContent(BuildContext context) {
    return Column(children: [
      Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(color: const Color(0xFFEFF9EC), shape: BoxShape.circle),
        child: Image.asset(Images.deliveredSuccess, height: 72, width: 72),
      ),
      const SizedBox(height: 16),
      Text(
        widget.isSenderPay ? 'Receber valor da retirada' : (_isPickupStep ? 'Concluir retirada?' : 'Concluir entrega?'),
        textAlign: TextAlign.center,
        style: robotoBold.copyWith(fontSize: 24, color: Colors.black),
      ),
      const SizedBox(height: 10),
      Text(
        widget.isSenderPay ? 'Confirme o recebimento do valor antes de seguir.' : 'Essa ação atualiza o status real do pedido.',
        textAlign: TextAlign.center,
        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: const Color(0xFF646464)),
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${'order_amount'.tr}:', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Text(PriceConverterHelper.convertPrice(widget.orderAmount), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor)),
        ]),
      ),
    ]);
  }

  Widget _resendRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(
            'Não recebeu a notificação/código?',
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
          ),
        ),
        Get.find<NotificationController>().hideNotificationButton ? const SizedBox() : InkWell(
          onTap: _seconds < 1 ? () {
            Get.find<NotificationController>().sendDeliveredNotification(widget.currentOrderModel.id);
            _startTimer();
          } : null,
          child: Text('Reenviar${_seconds > 0 ? ' (${_seconds}s)' : ''}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  void _submit(OrderController orderController) {
    if(widget.cod!){
      if(widget.verify! && widget.isParcel!) {
        Get.back(result: 'show_price_view');
      } else {
        Get.find<OrderController>().updateOrderStatus(
          widget.currentOrderModel,
          widget.currentOrderModel.orderStatus == 'handover' ? 'picked_up' : 'delivered',
          parcel: widget.isParcel,
          stopOtherDataCall: true,
        );
      }
    } else{
      Get.find<OrderController>().updateOrderStatus(
        widget.currentOrderModel,
        widget.currentOrderModel.orderStatus == 'handover' ? 'picked_up' : 'delivered',
        parcel: widget.isParcel,
      ).then((success) {
        if(success) {
          Get.find<ProfileController>().getProfile();
          Get.find<OrderController>().getRunningOrders(orderController.offset);
          if(!widget.isSenderPay) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }
        }
      });
    }
  }
}
