import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/screens/order_details_screen.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:get/get.dart';

typedef NewCallOverlayActionCallback = FutureOr<void> Function(Map<dynamic, dynamic>? data);

class NewCallOverlayHelper {
  static const MethodChannel _channel = MethodChannel('com.foxgo.entregador/call_permissions');
  static bool _callbacksBound = false;
  static bool _handlingAction = false;

  static NewCallOverlayActionCallback? onAccept;
  static NewCallOverlayActionCallback? onReject;
  static NewCallOverlayActionCallback? onDismissed;

  static void setCallbacks({
    NewCallOverlayActionCallback? accept,
    NewCallOverlayActionCallback? reject,
    NewCallOverlayActionCallback? dismissed,
  }) {
    onAccept = accept;
    onReject = reject;
    onDismissed = dismissed;

    if(_callbacksBound) return;
    _callbacksBound = true;
    _channel.setMethodCallHandler((call) async {
      final payload = call.arguments as Map<dynamic, dynamic>?;
      if(call.method == 'onNewCallAccept') {
        await onAccept?.call(payload);
      } else if(call.method == 'onNewCallReject') {
        await onReject?.call(payload);
      } else if(call.method == 'onNewCallDismissed') {
        await onDismissed?.call(payload);
      }
    });
  }


  static void bindDefaultCallbacks() {
    setCallbacks(
      accept: handleAccept,
      reject: handleReject,
      dismissed: handleDismissed,
    );
  }

  static Future<void> handleAccept(Map<dynamic, dynamic>? payload) async {
    if(_handlingAction) {
      return;
    }

    _handlingAction = true;
    try {
      final String? orderId = _payloadValue(payload, ['orderId', 'order_id', 'callId']);
      if(orderId == null || orderId.isEmpty) {
        return;
      }

      final OrderController orderController = Get.find<OrderController>();
      await orderController.getLatestOrders();

      final order = orderController.foxgoFindLatestOrderById(orderId);
      if(order == null) {
        await orderController.getLatestOrders();
        return;
      }

      final bool isSuccess = await orderController.foxgoAcceptOverlayOrder(order.id, order);
      if(isSuccess) {
        order.orderStatus = (order.orderStatus == 'pending' || order.orderStatus == 'confirmed') ? 'accepted' : order.orderStatus;

        final int orderIndex = ((orderController.currentOrderList?.length ?? 1) - 1).clamp(0, 999999).toInt();
        Get.toNamed(
          RouteHelper.getOrderDetailsRoute(order.id),
          arguments: OrderDetailsScreen(
            orderId: order.id,
            isRunningOrder: true,
            orderIndex: orderIndex,
          ),
        );
      } else {
        await orderController.getLatestOrders();
      }
    } finally {
      _handlingAction = false;
    }
  }

  static Future<void> handleReject(Map<dynamic, dynamic>? payload) async {
    try {
      await Get.find<OrderController>().getLatestOrders();
    } catch (_) {}
  }

  static Future<void> handleDismissed(Map<dynamic, dynamic>? payload) async {
    final String? expired = _payloadValue(payload, ['expired']);
    final String? reason = _payloadValue(payload, ['reason']);

    if(expired == 'true' || reason == 'expired') {
      try {
        await Get.find<OrderController>().getLatestOrders();
      } catch (_) {}
    }
  }

  static String? _payloadValue(Map<dynamic, dynamic>? payload, List<String> keys) {
    if(payload == null) {
      return null;
    }

    for(final String key in keys) {
      final value = payload[key];
      if(value != null) {
        return value.toString();
      }
    }

    return null;
  }

  static Future<bool> show(Map<String, dynamic> data) async {
    final result = await _channel.invokeMethod<bool>('showNewCallOverlay', data);
    return result ?? false;
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    final result = await _channel.invokeMethod<bool>('updateNewCallOverlay', data);
    return result ?? false;
  }

  static Future<bool> dismiss() async {
    final result = await _channel.invokeMethod<bool>('dismissNewCallOverlay');
    return result ?? false;
  }

  static Future<bool> isShowing() async {
    final result = await _channel.invokeMethod<bool>('isOverlayShowing');
    return result ?? false;
  }
}
