import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CallPermissionHelper {
  static const MethodChannel _channel = MethodChannel('com.foxgo.entregador/call_permissions');

  static Future<bool> isNotificationGranted() async {
    if(!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> isOverlayGranted() async {
    if(!Platform.isAndroid) return true;
    final bool? granted = await _channel.invokeMethod<bool>('isOverlayGranted');
    return granted ?? false;
  }

  static Future<bool> isFullScreenIntentAvailable() async {
    if(!Platform.isAndroid) return false;
    final bool? available = await _channel.invokeMethod<bool>('isFullScreenIntentAvailable');
    return available ?? false;
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if(!Platform.isAndroid) return true;
    return (await Permission.ignoreBatteryOptimizations.status).isGranted;
  }

  static Future<void> openOverlaySettings() async {
    await _channel.invokeMethod('openOverlaySettings');
  }

  static Future<void> openNotificationSettings() async {
    if(!await openAppSettings()) {
      await _channel.invokeMethod('openAppSettings');
    }
  }

  static Future<void> openBatterySettings() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if(status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    } else {
      await _channel.invokeMethod('openBatterySettings');
    }
  }
}
