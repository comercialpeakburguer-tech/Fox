import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/new_call_overlay_helper.dart';

class GlobalCallRouteHelper {
  static String? _lastOrderId;
  static DateTime? _lastRoutedAt;
  static String _lastRouteResult = 'nenhuma_tentativa';

  static bool get isAppForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static bool shouldRoute(String? orderId, {int seconds = 8, String reason = 'precheck'}) {
    final now = DateTime.now();
    if(orderId != null && orderId.isNotEmpty && _lastOrderId == orderId && _lastRoutedAt != null) {
      final elapsed = now.difference(_lastRoutedAt!).inSeconds;
      if(elapsed < seconds) {
        final remaining = seconds - elapsed;
        debugPrint('FoxGoCallRoute dedupe bloqueou orderId=$orderId restante=${remaining}s motivo=$reason ultimoResultado=$_lastRouteResult');
        return false;
      }
    }
    return true;
  }

  static void markVisualHandled(String? orderId, {required String result}) {
    _lastRouteResult = result;
    if(orderId == null || orderId.isEmpty) return;
    _lastOrderId = orderId;
    _lastRoutedAt = DateTime.now();
    debugPrint('FoxGoCallRoute dedupe marcado orderId=$orderId resultado=$result');
  }

  static Future<bool> routeOrderModel(OrderModel order, {required String source}) async {
    final payload = payloadFromOrder(order);
    debugPrint('FoxGoCallRoute source=$source latest_orders orderId=${payload['orderId']} callId=${payload['callId']}');
    if(!shouldRoute(payload['orderId']?.toString(), reason: source)) {
      return true;
    }
    return routePayload(payload, source: source);
  }

  static Future<bool> routePayload(Map<String, dynamic> payload, {required String source}) async {
    bool overlayVisible = false;
    try {
      debugPrint('FoxGoCallRoute chamou routeNewCallMessage/global source=$source keys=${payload.keys.toList()} type=${payload['type']} orderId=${payload['orderId']}');
      debugPrint('FoxGoOverlayService tentando start NewCallOverlayService source=$source callId=${payload['callId']}');
      final isShowing = await NewCallOverlayHelper.isShowing();
      overlayVisible = isShowing ? await NewCallOverlayHelper.update(payload) : await NewCallOverlayHelper.show(payload);
      debugPrint('FoxGoOverlayService confirmação visual overlayVisible=$overlayVisible source=$source callId=${payload['callId']}');
    } on PlatformException catch (error) {
      debugPrint('FoxGoOverlayService start/confirm falha PlatformException source=$source code=${error.code} message=${error.message}');
    } catch (error) {
      debugPrint('FoxGoOverlayService start/confirm falha source=$source error=$error');
    }

    if(overlayVisible) {
      markVisualHandled(payload['orderId']?.toString(), result: 'overlay_visivel');
      return true;
    }

    _lastRouteResult = 'overlay_pendente_confirmacao_nativa';
    debugPrint('FoxGoCallRoute fallback delegado ao nativo source=$source orderId=${payload['orderId']} callId=${payload['callId']}');
    return false;
  }

  static Future<bool> emitFallback(Map<String, dynamic> payload, {required String source}) async {
    try {
      debugPrint('FoxGoCallFallback solicitando fallback source=$source orderId=${payload['orderId']} callId=${payload['callId']} foreground=$isAppForeground');
      final emitted = await NewCallOverlayHelper.showFallback(payload);
      debugPrint('FoxGoCallFallback fallback resultado=$emitted source=$source orderId=${payload['orderId']} callId=${payload['callId']}');
      return emitted;
    } catch (error) {
      debugPrint('FoxGoCallFallback fallback falhou source=$source error=$error');
      return false;
    }
  }

  static Map<String, dynamic> payloadFromOrder(OrderModel order) {
    final orderId = order.id?.toString();
    final rawType = order.moduleType ?? order.orderType ?? 'latest_orders';
    return {
      'callId': orderId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'orderId': orderId,
      'rawType': rawType,
      'type': 'latest_orders',
      'moduleType': order.moduleType,
      'title': 'Nova chamada',
      'originName': order.storeName ?? '',
      'pickupAddress': order.storeAddress ?? '',
      'destinationAddress': order.deliveryAddress?.address ?? '',
      'earning': order.orderAmount?.toString() ?? '',
      'driverEarningAmount': order.orderAmount?.toString() ?? '',
      'distance': '',
      'totalDistanceKm': '',
      'expiresAt': '',
      'ttlSeconds': '',
      'paymentMethod': order.paymentMethod ?? '',
      'isRide': rawType.toLowerCase().contains('ride'),
      'isFood': _isFoodRaw(rawType),
      'itemsSummary': null,
    };
  }

  static bool _isFoodRaw(String rawType) {
    final raw = rawType.toLowerCase();
    if(raw.contains('parcel') || raw.contains('pharmacy') || raw.contains('grocery') || raw.contains('market') || raw.contains('ride') || raw.contains('taxi')) {
      return false;
    }
    return raw.isEmpty || raw.contains('food') || raw.contains('restaurant') || raw.contains('comida') || raw == 'latest_orders';
  }
}
