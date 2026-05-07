import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef NewCallOverlayActionCallback = FutureOr<void> Function(Map<dynamic, dynamic>? data);

class NewCallOverlayHelper {
  static const MethodChannel _channel = MethodChannel('com.foxgo.entregador/call_permissions');
  static bool _callbacksBound = false;

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
      final payload = _safePayload(call.arguments);
      debugPrint('FoxGoCallAction Flutter recebeu ${call.method} payload=$payload orderId=${_detectOrderId(payload)} callbackAccept=${onAccept != null} callbackReject=${onReject != null}');
      try {
        if(call.method == 'onNewCallAccept') {
          await onAccept?.call(payload);
        } else if(call.method == 'onNewCallReject') {
          await onReject?.call(payload);
        } else if(call.method == 'onNewCallDismissed') {
          await onDismissed?.call(payload);
        }
      } catch(error, stackTrace) {
        debugPrint('FoxGoCallAction erro ao executar callback ${call.method}: $error\n$stackTrace');
      }
    });
  }

  static Future<bool> show(Map<String, dynamic> data) async {
    final started = await _channel.invokeMethod<bool>('showNewCallOverlay', data);
    return _confirmVisibleAfterStart(started, data, action: 'show');
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    final started = await _channel.invokeMethod<bool>('updateNewCallOverlay', data);
    return _confirmVisibleAfterStart(started, data, action: 'update');
  }

  static Future<bool> dismiss() async {
    final result = await _channel.invokeMethod<bool>('dismissNewCallOverlay');
    return result ?? false;
  }

  static Future<bool> isShowing() async {
    final result = await _channel.invokeMethod<bool>('isOverlayShowing');
    return result ?? false;
  }

  static Future<bool> showFallback(Map<String, dynamic> data) async {
    final result = await _channel.invokeMethod<bool>('showNewCallFallback', data);
    return result ?? false;
  }

  static Future<bool> _confirmVisibleAfterStart(
    bool? started,
    Map<String, dynamic> data, {
    required String action,
  }) async {
    if(started != true) {
      debugPrint('FoxGoOverlayService $action service não iniciou/retornou falso callId=${data['callId']} orderId=${data['orderId']}');
      return false;
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final visible = await isShowing();
    debugPrint('FoxGoOverlayService $action confirmação real visible=$visible callId=${data['callId']} orderId=${data['orderId']}');
    return visible;
  }

  static Map<dynamic, dynamic>? _safePayload(dynamic arguments) {
    if(arguments == null) return null;
    if(arguments is Map) return Map<dynamic, dynamic>.from(arguments);
    debugPrint('FoxGoCallAction payload ignorado por tipo inválido: ${arguments.runtimeType}');
    return null;
  }

  static String? _detectOrderId(Map<dynamic, dynamic>? payload) {
    for(final key in ['orderId', 'order_id', 'id', 'callId']) {
      final value = payload?[key]?.toString();
      if(value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
