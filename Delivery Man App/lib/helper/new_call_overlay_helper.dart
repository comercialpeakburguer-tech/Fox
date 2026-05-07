import 'package:flutter/services.dart';

typedef NewCallOverlayActionCallback = void Function(Map<dynamic, dynamic>? data);

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
      final payload = call.arguments as Map<dynamic, dynamic>?;
      if(call.method == 'onNewCallAccept') {
        onAccept?.call(payload);
      } else if(call.method == 'onNewCallReject') {
        onReject?.call(payload);
      } else if(call.method == 'onNewCallDismissed') {
        onDismissed?.call(payload);
      }
    });
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
