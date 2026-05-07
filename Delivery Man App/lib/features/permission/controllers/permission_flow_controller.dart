import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';

const String _permissionChannelName = 'com.foxgo.entregador/call_permissions';

enum FoxGoPermissionStep {
  preciseLocation,
  backgroundLocation,
  notifications,
  overlay,
  batteryOptimization,
}

enum FoxGoPermissionStatus {
  granted,
  missing,
  denied,
  needsSettings,
  notApplicable,
}

class FoxGoPermissionCheck {
  final FoxGoPermissionStep step;
  final FoxGoPermissionStatus status;
  final bool critical;
  final String title;
  final String activeLabel;
  final String inactiveLabel;
  final String? details;

  const FoxGoPermissionCheck({
    required this.step,
    required this.status,
    required this.critical,
    required this.title,
    required this.activeLabel,
    required this.inactiveLabel,
    this.details,
  });

  bool get isGranted => status == FoxGoPermissionStatus.granted || status == FoxGoPermissionStatus.notApplicable;
  bool get needsAction => !isGranted;
}

class PermissionFlowController extends GetxController implements GetxService {
  static const MethodChannel _channel = MethodChannel(_permissionChannelName);
  static const String _logTag = 'FoxGoPermissionFlow';

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isFlowOpen = false;
  bool get isFlowOpen => _isFlowOpen;

  bool _waitingExternalSettings = false;
  bool get waitingExternalSettings => _waitingExternalSettings;

  FoxGoPermissionStep? _currentStep;
  FoxGoPermissionStep? get currentStep => _currentStep;

  List<FoxGoPermissionCheck> _checks = const [];
  List<FoxGoPermissionCheck> get checks => _checks;

  int _flowPasses = 0;
  DateTime? _lastFlowOpenAt;

  Future<List<FoxGoPermissionCheck>> refreshStatuses({bool notify = true}) async {
    if (_isRefreshing) return _checks;
    _isRefreshing = true;
    if (notify) update();

    final List<FoxGoPermissionCheck> result = [];
    final LocationPermission locationPermission = await Geolocator.checkPermission();
    final bool preciseGranted = await _isPreciseLocationGranted(locationPermission);
    result.add(FoxGoPermissionCheck(
      step: FoxGoPermissionStep.preciseLocation,
      status: preciseGranted ? FoxGoPermissionStatus.granted : _locationStatus(locationPermission),
      critical: true,
      title: 'Localização precisa',
      activeLabel: 'Ativa',
      inactiveLabel: 'Inativa',
      details: 'Usada para encontrar entregas próximas e calcular rotas de entrega.',
    ));

    final bool backgroundApplicable = GetPlatform.isAndroid || GetPlatform.isIOS;
    result.add(FoxGoPermissionCheck(
      step: FoxGoPermissionStep.backgroundLocation,
      status: !backgroundApplicable
          ? FoxGoPermissionStatus.notApplicable
          : locationPermission == LocationPermission.always
              ? FoxGoPermissionStatus.granted
              : preciseGranted
                  ? FoxGoPermissionStatus.needsSettings
                  : FoxGoPermissionStatus.missing,
      critical: true,
      title: 'Localização o tempo todo',
      activeLabel: backgroundApplicable ? 'Ativa' : 'Não aplicável',
      inactiveLabel: preciseGranted ? 'Abrir configurações' : 'Pendente',
      details: 'Mantém chamadas e rotas de entrega funcionando em segundo plano.',
    ));

    final bool notificationApplicable = GetPlatform.isAndroid ? await _androidSdkAtLeast(33) : GetPlatform.isIOS;
    final PermissionStatus notificationStatus = await Permission.notification.status;
    result.add(FoxGoPermissionCheck(
      step: FoxGoPermissionStep.notifications,
      status: !notificationApplicable
          ? FoxGoPermissionStatus.notApplicable
          : notificationStatus.isGranted
              ? FoxGoPermissionStatus.granted
              : notificationStatus.isPermanentlyDenied
                  ? FoxGoPermissionStatus.needsSettings
                  : FoxGoPermissionStatus.missing,
      critical: true,
      title: 'Notificações',
      activeLabel: notificationApplicable ? 'Ativa' : 'Não aplicável',
      inactiveLabel: notificationStatus.isPermanentlyDenied ? 'Abrir configurações' : 'Inativa',
      details: 'Avisos de novas chamadas de entrega e status do serviço.',
    ));

    final bool overlayApplicable = GetPlatform.isAndroid;
    final bool overlayGranted = overlayApplicable && await isOverlayGranted();
    result.add(FoxGoPermissionCheck(
      step: FoxGoPermissionStep.overlay,
      status: !overlayApplicable
          ? FoxGoPermissionStatus.notApplicable
          : overlayGranted
              ? FoxGoPermissionStatus.granted
              : FoxGoPermissionStatus.needsSettings,
      critical: true,
      title: 'Aparecer sobre outros apps',
      activeLabel: overlayApplicable ? 'Ativa' : 'Não aplicável',
      inactiveLabel: 'Inativa',
      details: 'Ajuda você a não perder chamadas de entrega usando outros aplicativos.',
    ));

    final bool batteryApplicable = GetPlatform.isAndroid;
    final bool batteryGranted = batteryApplicable && await isIgnoringBatteryOptimizations();
    result.add(FoxGoPermissionCheck(
      step: FoxGoPermissionStep.batteryOptimization,
      status: !batteryApplicable
          ? FoxGoPermissionStatus.notApplicable
          : batteryGranted
              ? FoxGoPermissionStatus.granted
              : FoxGoPermissionStatus.needsSettings,
      critical: true,
      title: 'Otimização de bateria',
      activeLabel: batteryApplicable ? 'Permitida' : 'Não aplicável',
      inactiveLabel: 'Restrita',
      details: 'Permite receber chamadas, localização e notificações com o Fox GO em segundo plano.',
    ));

    _checks = result;
    _currentStep = nextMissingStep;
    _isRefreshing = false;
    _log('refreshStatuses current=$_currentStep missing=${missingCriticalChecks.map((e) => e.title).join(', ')}');
    update();
    return result;
  }

  List<FoxGoPermissionCheck> get missingCriticalChecks => _checks.where((check) => check.critical && check.needsAction).toList(growable: false);
  bool get hasCriticalMissing => missingCriticalChecks.isNotEmpty;

  FoxGoPermissionStep? get nextMissingStep {
    for (final FoxGoPermissionStep step in FoxGoPermissionStep.values) {
      final FoxGoPermissionCheck? check = _checks.firstWhereOrNull((item) => item.step == step);
      if (check != null && check.critical && check.needsAction) return step;
    }
    return null;
  }

  Future<bool> ensureCriticalPermissions({bool openFlow = true, bool fromLogin = false, bool replaceRoute = false}) async {
    await refreshStatuses();
    if (!hasCriticalMissing) return true;
    if (openFlow) await openPermissionFlow(fromLogin: fromLogin, replaceRoute: replaceRoute);
    return false;
  }

  Future<void> openPermissionFlow({FoxGoPermissionStep? startAt, bool fromLogin = false, bool replaceRoute = false}) async {
    await refreshStatuses();
    _currentStep = startAt ?? nextMissingStep;
    if (_currentStep == null) return;
    final DateTime now = DateTime.now();
    if (_isFlowOpen && _lastFlowOpenAt != null && now.difference(_lastFlowOpenAt!).inMilliseconds < 800) return;
    _isFlowOpen = true;
    _flowPasses = 0;
    _lastFlowOpenAt = now;
    _log('openPermissionFlow step=$_currentStep fromLogin=$fromLogin replace=$replaceRoute');
    final String route = RouteHelper.getPermissionOnboardingRoute(fromLogin: fromLogin);
    if (replaceRoute) {
      Get.offAllNamed(route);
    } else if (Get.currentRoute != RouteHelper.permissionOnboarding) {
      await Get.toNamed(route);
    }
    _isFlowOpen = false;
    update();
  }

  Future<void> openCentral() async {
    await refreshStatuses();
    Get.toNamed(RouteHelper.getPermissionCenterRoute());
  }

  Future<void> revalidateAfterReturn() async {
    _waitingExternalSettings = false;
    await refreshStatuses();
    if (_isFlowOpen) advanceToNextStep();
  }

  void advanceToNextStep() {
    _flowPasses++;
    _currentStep = nextMissingStep;
    if (_flowPasses > 20) {
      _log('Fluxo interrompido para evitar loop infinito. passes=$_flowPasses');
      return;
    }
    update();
  }

  Future<void> requestCurrentStep() async {
    final FoxGoPermissionStep? step = _currentStep ?? nextMissingStep;
    if (step == null) return;
    await requestStep(step);
  }

  Future<void> requestStep(FoxGoPermissionStep step) async {
    _log('requestStep $step');
    switch (step) {
      case FoxGoPermissionStep.preciseLocation:
        await _requestPreciseLocation();
        break;
      case FoxGoPermissionStep.backgroundLocation:
        await _requestBackgroundLocation();
        break;
      case FoxGoPermissionStep.notifications:
        await _requestNotification();
        break;
      case FoxGoPermissionStep.overlay:
        await openOverlaySettings();
        break;
      case FoxGoPermissionStep.batteryOptimization:
        await openBatteryOptimizationSettings();
        break;
    }
    await refreshStatuses();
    advanceToNextStep();
  }

  Future<void> _requestPreciseLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _waitingExternalSettings = true;
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _requestBackgroundLocation() async {
    if (!await _isPreciseLocationGranted(await Geolocator.checkPermission())) {
      await _requestPreciseLocation();
      return;
    }
    _waitingExternalSettings = true;
    if (GetPlatform.isAndroid && await _androidSdkAtLeast(30)) {
      await openAppLocationSettings();
      return;
    }
    final LocationPermission permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always) {
      await openAppLocationSettings();
    }
  }

  Future<void> _requestNotification() async {
    final PermissionStatus status = await Permission.notification.status;
    if (status.isGranted) return;
    final PermissionStatus result = await Permission.notification.request();
    if (result.isPermanentlyDenied) await openAppSettings();
  }

  Future<bool> _isPreciseLocationGranted(LocationPermission permission) async {
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever || permission == LocationPermission.unableToDetermine) {
      return false;
    }
    if (!GetPlatform.isAndroid && !GetPlatform.isIOS) return true;
    try {
      final LocationAccuracyStatus accuracy = await Geolocator.getLocationAccuracy();
      return accuracy == LocationAccuracyStatus.precise;
    } catch (_) {
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    }
  }

  FoxGoPermissionStatus _locationStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return FoxGoPermissionStatus.missing;
      case LocationPermission.deniedForever:
        return FoxGoPermissionStatus.needsSettings;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return FoxGoPermissionStatus.needsSettings;
    }
  }

  Future<bool> isOverlayGranted() async {
    if (!GetPlatform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isOverlayGranted') ?? false;
    } catch (e) {
      _log('Falha ao validar overlay: $e');
      return await Permission.systemAlertWindow.status.isGranted;
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!GetPlatform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (e) {
      _log('Falha ao validar bateria: $e');
      return await Permission.ignoreBatteryOptimizations.status.isGranted;
    }
  }

  Future<void> openOverlaySettings() async {
    if (!GetPlatform.isAndroid) return;
    _waitingExternalSettings = true;
    try {
      await _channel.invokeMethod('openOverlaySettingsSmart');
    } catch (e) {
      _log('Fallback overlay por plugin: $e');
      await Permission.systemAlertWindow.request();
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!GetPlatform.isAndroid) return;
    if (await isIgnoringBatteryOptimizations()) return;
    _waitingExternalSettings = true;
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettingsSmart');
    } catch (e) {
      _log('Fallback bateria por plugin: $e');
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> openAppLocationSettings() async {
    try {
      if (GetPlatform.isAndroid) {
        await _channel.invokeMethod('openAppLocationSettings');
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (e) {
      _log('Fallback localização settings: $e');
      await Geolocator.openAppSettings();
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {
      await Permission.notification.request();
    }
  }

  Future<Map<String, dynamic>> getAndroidDeviceInfo() async {
    if (!GetPlatform.isAndroid) return const <String, dynamic>{};
    try {
      final Map<dynamic, dynamic>? data = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDeviceInfo');
      return data?.map((key, value) => MapEntry(key.toString(), value)) ?? const <String, dynamic>{};
    } catch (e) {
      _log('Falha ao obter device info: $e');
      return const <String, dynamic>{};
    }
  }

  Future<bool> _androidSdkAtLeast(int version) async {
    if (!GetPlatform.isAndroid) return false;
    final Map<String, dynamic> info = await getAndroidDeviceInfo();
    final Object? sdk = info['sdkInt'];
    return sdk is int ? sdk >= version : false;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[$_logTag] $message');
  }
}
