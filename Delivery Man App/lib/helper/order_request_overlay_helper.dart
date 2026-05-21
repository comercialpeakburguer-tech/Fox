import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_loader.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/fox_go_accepted_order_card_widget.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/fox_go_order_request_card_widget.dart';
import 'package:sixam_mart_delivery/helper/new_call_overlay_helper.dart';
import 'package:sixam_mart_delivery/helper/global_call_route_helper.dart';

class OrderRequestOverlayHelper {
  static bool _showingIncomingCard = false;
  static String? _showingOrderId;
  static String? _lastDismissedOrderId;
  static DateTime? _lastDismissedAt;
  static final Set<String> _handledOrderIds = <String>{};

  static Future<void> refreshRequests({String? orderId, bool showCard = true, bool routeGlobal = true, String source = 'manual'}) async {
    final orderController = Get.find<OrderController>();
    debugPrint('FoxGoOrderRefresh source=$source refresh iniciado routeGlobal=$routeGlobal showCard=$showCard orderId=$orderId');
    await orderController.getLatestOrders();
    orderController.getOrderCount(orderController.orderType);
    orderController.getRunningOrders(1, status: 'all');

    if(!showCard) return;

    final order = _findOrder(orderController, orderId);
    if(order == null) {
      debugPrint('FoxGoOrderRefresh source=$source pedidos encontrados=0 routeGlobal=$routeGlobal');
      return;
    }

    final nextOrderId = order.id?.toString();
    if(_wasRecentlyHandled(nextOrderId)) {
      debugPrint('FoxGoOrderRefresh source=$source bloqueado por handled/recentDismiss orderId=$nextOrderId');
      return;
    }

    debugPrint('FoxGoOrderRefresh source=$source pedidos encontrados=${orderController.latestOrderList?.length ?? 0} orderId=${order.id} routeGlobal=$routeGlobal');
    if(routeGlobal) {
      debugPrint('FoxGoOrderRefresh source=$source routeGlobal chamado orderId=${order.id}');
      final overlayStarted = await GlobalCallRouteHelper.routeOrderModel(order, source: 'OrderRequestOverlayHelper.refreshRequests/$source');
      debugPrint('FoxGoCallRoute source=$source overlay chamado orderId=${order.id} dedupe ${overlayStarted ? 'aceitou' : 'bloqueou/fallback'}');
      if(overlayStarted) return;
      if(!GlobalCallRouteHelper.isAppForeground) return;
    }
    final index = orderController.latestOrderList?.indexWhere((request) => request.id == order.id) ?? -1;
    if(index < 0) return;

    showIncomingCard(order: order, index: index);
  }

  static void showIncomingCard({required OrderModel order, required int index}) {
    final nextOrderId = order.id?.toString();
    if(_wasRecentlyHandled(nextOrderId)) return;
    if(_showingIncomingCard) {
      debugPrint('FoxGoIncomingCard bloqueou dialog duplicado atual=$_showingOrderId novo=$nextOrderId');
      return;
    }
    if(Get.isDialogOpen == true) {
      debugPrint('FoxGoIncomingCard bloqueou porque já existe dialog aberto novo=$nextOrderId');
      return;
    }

    _showingIncomingCard = true;
    _showingOrderId = nextOrderId;

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        backgroundColor: Colors.transparent,
        child: FoxGoOrderRequestCardWidget(
          orderModel: order,
          index: index,
          compact: true,
          onTap: () {
            _markDismissed(nextOrderId);
            if(Get.isDialogOpen == true) {
              Get.back();
            }
          },
        ),
      ),
      barrierDismissible: false,
    ).whenComplete(() {
      _showingIncomingCard = false;
      _showingOrderId = null;
    });
  }

  static Future<void> acceptFromOverlayPayload(Map<dynamic, dynamic>? payload) async {
    debugPrint('FoxGoCallAction acceptFromOverlayPayload chamado payload=$payload');
    try {
      final registered = Get.isRegistered<OrderController>();
      final orderId = _detectOrderId(payload);
      debugPrint('FoxGoCallAction acceptFromOverlayPayload OrderControllerRegistrado=$registered orderId detectado=$orderId');
      if(!registered) {
        debugPrint('FoxGoCallAction OrderController indisponível no aceitar; abrindo app sem crash orderId=$orderId');
        return;
      }
      final orderController = Get.find<OrderController>();

      _markHandled(orderId?.toString());
      await NewCallOverlayHelper.dismiss();
      await orderController.getLatestOrders();

      final index = orderController.latestOrderList?.indexWhere((order) => order.id == orderId) ?? -1;
      if(index < 0) {
        debugPrint('FoxGoCallAction pedido não encontrado para aceite orderId=$orderId latestCount=${orderController.latestOrderList?.length ?? 0}');
        return;
      }

      final order = orderController.latestOrderList![index];
      _closeIncomingCardIfOpen();
      if(Get.isDialogOpen != true) {
        Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      }
      debugPrint('FoxGoCallAction chamando OrderController.acceptOrder orderId=${order.id} index=$index');
      final isSuccess = await orderController.acceptOrder(order.id, index, order);
      _safeCloseLoader();
      if(isSuccess) {
        order.orderStatus = (order.orderStatus == 'pending' || order.orderStatus == 'confirmed') ? 'accepted' : order.orderStatus;
        if(Get.isDialogOpen != true) {
          Get.dialog(FoxGoAcceptedOrderCardWidget(orderModel: order), barrierDismissible: false);
        }
      } else {
        await orderController.getLatestOrders();
      }
    } catch(error, stackTrace) {
      debugPrint('FoxGoCallAction erro em acceptFromOverlayPayload: $error\n$stackTrace');
      _safeCloseLoader();
    }
  }

  static Future<void> rejectFromOverlayPayload(Map<dynamic, dynamic>? payload) async {
    debugPrint('FoxGoCallAction rejectFromOverlayPayload chamado payload=$payload');
    try {
      final registered = Get.isRegistered<OrderController>();
      final orderId = _detectOrderId(payload);
      debugPrint('FoxGoCallAction rejectFromOverlayPayload OrderControllerRegistrado=$registered orderId detectado=$orderId');
      if(!registered) {
        debugPrint('FoxGoCallAction OrderController indisponível no recusar; abrindo app sem crash orderId=$orderId');
        return;
      }
      final orderController = Get.find<OrderController>();

      _markHandled(orderId?.toString());
      await NewCallOverlayHelper.dismiss();
      bool ignored = orderController.ignoreOrderById(orderId);
      if(!ignored) {
        await orderController.getLatestOrders();
        ignored = orderController.ignoreOrderById(orderId);
      }
      _closeIncomingCardIfOpen();
      if(!ignored) {
        debugPrint('FoxGoCallAction recusa sem pedido local correspondente; latest_orders atualizado orderId=$orderId');
        await refreshRequests(orderId: orderId?.toString(), showCard: false);
      }
    } catch(error, stackTrace) {
      debugPrint('FoxGoCallAction erro em rejectFromOverlayPayload: $error\n$stackTrace');
    }
  }

  static int? _detectOrderId(Map<dynamic, dynamic>? payload) {
    for(final key in ['orderId', 'order_id', 'id', 'callId']) {
      final raw = payload?[key]?.toString();
      final parsed = int.tryParse(raw ?? '');
      if(parsed != null) return parsed;
    }
    return null;
  }

  static void _closeIncomingCardIfOpen() {
    if(_showingIncomingCard && Get.isDialogOpen == true) {
      Get.back();
      _showingIncomingCard = false;
      _showingOrderId = null;
    }
  }

  static void _safeCloseLoader() {
    try {
      if(Get.isDialogOpen == true) {
        Get.back();
      }
    } catch(_) {}
  }

  static OrderModel? _findOrder(OrderController orderController, String? orderId) {
    final requests = orderController.latestOrderList;
    if(requests == null || requests.isEmpty) return null;
    if(orderId != null && orderId.isNotEmpty) {
      final int? parsedId = int.tryParse(orderId);
      for(final order in requests) {
        if(order.id == parsedId) return order;
      }
    }
    for(final order in requests) {
      if(!_wasRecentlyHandled(order.id?.toString())) return order;
    }
    return null;
  }

  static bool _wasRecentlyHandled(String? orderId) {
    if(orderId == null || orderId.isEmpty) return false;
    if(_handledOrderIds.contains(orderId)) return true;
    if(_lastDismissedOrderId == orderId && _lastDismissedAt != null) {
      return DateTime.now().difference(_lastDismissedAt!).inSeconds < 15;
    }
    return false;
  }

  static void _markHandled(String? orderId) {
    if(orderId == null || orderId.isEmpty) return;
    _handledOrderIds.add(orderId);
    Future.delayed(const Duration(minutes: 2), () => _handledOrderIds.remove(orderId));
  }

  static void _markDismissed(String? orderId) {
    if(orderId == null || orderId.isEmpty) return;
    _lastDismissedOrderId = orderId;
    _lastDismissedAt = DateTime.now();
  }
}
