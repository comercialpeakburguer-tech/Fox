import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FoxGoOnlineServiceHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.foxgo.entregador/call_permissions',
  );

  static Future<bool> start() async {
    if (!GetPlatform.isAndroid) return true;
    try {
      final bool? started = await _channel.invokeMethod<bool>(
        'startOnlineForegroundService',
      );
      debugPrint('FoxGoOnlineService start result=$started');

      await Future<void>.delayed(const Duration(milliseconds: 900));
      bool running = await isRunning();
      if (!running && started == true) {
        debugPrint('FoxGoOnlineService start verificacao falhou; tentando iniciar novamente');
        await _channel.invokeMethod<bool>('startOnlineForegroundService');
        await Future<void>.delayed(const Duration(milliseconds: 900));
        running = await isRunning();
      }

      debugPrint('FoxGoOnlineService start verifiedRunning=$running');
      return (started ?? false) && running;
    } catch (error, stackTrace) {
      debugPrint('FoxGoOnlineService erro ao iniciar: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  static Future<bool> stop() async {
    if (!GetPlatform.isAndroid) return true;
    try {
      final bool? stopped = await _channel.invokeMethod<bool>(
        'stopOnlineForegroundService',
      );
      debugPrint('FoxGoOnlineService stop result=$stopped');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final bool stillRunning = await isRunning();
      debugPrint('FoxGoOnlineService stop verifiedStillRunning=$stillRunning');
      return (stopped ?? false) && !stillRunning;
    } catch (error, stackTrace) {
      debugPrint('FoxGoOnlineService erro ao parar: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  static Future<bool> isRunning() async {
    if (!GetPlatform.isAndroid) return false;
    try {
      final bool? running = await _channel.invokeMethod<bool>(
        'isOnlineForegroundServiceRunning',
      );
      return running ?? false;
    } catch (error, stackTrace) {
      debugPrint('FoxGoOnlineService erro ao consultar: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }
}
