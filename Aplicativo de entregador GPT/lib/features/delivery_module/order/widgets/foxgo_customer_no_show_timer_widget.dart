import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoCustomerNoShowTimerWidget extends StatefulWidget {
  final OrderModel order;
  final bool parcel;

  const FoxGoCustomerNoShowTimerWidget({
    super.key,
    required this.order,
    required this.parcel,
  });

  @override
  State<FoxGoCustomerNoShowTimerWidget> createState() => _FoxGoCustomerNoShowTimerWidgetState();
}

class _FoxGoCustomerNoShowTimerWidgetState extends State<FoxGoCustomerNoShowTimerWidget> {
  static const int _totalSeconds = 300;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;
  bool _started = false;
  bool _finished = false;

  bool get _isDeliveryStage {
    return widget.order.orderStatus == AppConstants.pickedUp;
  }

  bool get _isParcel => widget.parcel;

  String get _personLabel => _isParcel ? 'foxgo_no_show_recipient_label'.tr : 'foxgo_no_show_customer_label'.tr;

  String get _title => _isParcel ? 'foxgo_no_show_recipient_title'.tr : 'foxgo_no_show_customer_title'.tr;

  String get _supportReasonKey => _isParcel ? 'destinatario_nao_aparece' : 'cliente_nao_aparece';

  String get _supportInitialMessage {
    final String orderId = widget.order.id?.toString() ?? '-';
    return _isParcel
        ? 'Olá, estou com o pedido #$orderId e o destinatário não apareceu. Aguardei 5 minutos no local e preciso de orientação.'
        : 'Olá, estou com o pedido #$orderId e o cliente não apareceu. Aguardei 5 minutos no local e preciso de orientação.';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_started) {
      return;
    }

    setState(() {
      _started = true;
      _finished = false;
      _remainingSeconds = _totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _finished = true;
        });
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _openSupport() {
    if (!_finished) {
      return;
    }

    final notificationBody = NotificationBodyModel(
      orderId: widget.order.id,
      adminId: 0,
      type: AppConstants.admin,
    );

    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: notificationBody,
      user: null,
      conversationId: null,
      fromNotification: false,
      fromSupport: true,
      initialMessage: '[$_supportReasonKey] $_supportInitialMessage',
    ));
  }

  String _formatRemaining() {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeliveryStage) {
      return const SizedBox();
    }

    final Color primary = Theme.of(context).primaryColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color hintColor = Theme.of(context).hintColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeDefault,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Icon(Icons.person_search_outlined, color: primary, size: 23),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 4),
              Text(
                'foxgo_no_show_description'.trParams({'person': _personLabel}),
                style: robotoRegular.copyWith(color: hintColor, fontSize: Dimensions.fontSizeSmall),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _started ? 'foxgo_no_show_waiting_title'.tr : 'foxgo_no_show_before_start_title'.tr,
              style: robotoBold.copyWith(color: primary),
            ),
            const SizedBox(height: 8),
            Text(
              _started ? _formatRemaining() : '05:00',
              style: robotoBold.copyWith(fontSize: 30, color: primary),
            ),
            const SizedBox(height: 6),
            Text(
              _finished
                  ? 'foxgo_no_show_timer_finished'.tr
                  : (_started ? 'foxgo_no_show_wait_instruction'.tr : 'foxgo_no_show_start_instruction'.tr),
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ]),
        ),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        if (!_started)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text('foxgo_no_show_start_timer'.tr, style: robotoBold.copyWith(color: Colors.white)),
            ),
          ),

        if (_started && !_finished)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text('foxgo_no_show_support_locked'.tr, style: robotoMedium),
            ),
          ),

        if (_finished)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text('foxgo_no_show_open_support'.tr, style: robotoBold.copyWith(color: Colors.white)),
            ),
          ),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(
          'foxgo_no_show_keep_delivery_available'.tr,
          style: robotoRegular.copyWith(color: hintColor, fontSize: Dimensions.fontSizeExtraSmall),
        ),
      ]),
    );
  }
}
