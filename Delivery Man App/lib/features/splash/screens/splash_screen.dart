import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/notification_helper.dart';
import 'package:sixam_mart_delivery/helper/pusher_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  const SplashScreen({super.key, required this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  bool _configLoadFailed = false;
  bool _isRetryingConfig = false;

  @override
  void initState() {
    super.initState();

    if(Get.find<AuthController>().isLoggedIn()) {
      Get.find<ProfileController>().getProfile();
    }

    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);

      if(!firstTime) {
        isConnected ? ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar() : const SizedBox();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(isConnected ? 'connected'.tr : 'no_connection'.tr, textAlign: TextAlign.center),
        ));
        if(isConnected) {
          _route();
        }
      }

      firstTime = false;
    });

    Get.find<SplashController>().initSharedData();
    _route();

  }

  @override
  void dispose() {
    super.dispose();

    _onConnectivityChanged?.cancel();
  }

  void _route() {
    debugPrint('[Splash] Iniciando carregamento de config em ${AppConstants.baseUrl}${AppConstants.configUri}');
    if(mounted) {
      setState(() {
        _isRetryingConfig = true;
        _configLoadFailed = false;
      });
    }

    Get.find<SplashController>().getConfigData().then((isSuccess) async {
      debugPrint('[Splash] Retorno getConfigData: success=$isSuccess');
      if (isSuccess) {
        final config = Get.find<SplashController>().configModel;
        final bool hasMinimumAndroid = config?.appMinimumVersionAndroid != null;
        final bool hasMinimumIos = config?.appMinimumVersionIos != null;
        final bool hasMaintenance = config?.maintenanceMode != null;
        final bool hasWebsocket = config?.webSocketStatus != null;

        if(!(hasMinimumAndroid && hasMinimumIos && hasMaintenance && hasWebsocket)) {
          debugPrint('[Splash] Falha de config: campos essenciais ausentes.'
              ' androidMin=$hasMinimumAndroid iosMin=$hasMinimumIos maintenance=$hasMaintenance websocket=$hasWebsocket');
          if(mounted) {
            setState(() {
              _configLoadFailed = true;
              _isRetryingConfig = false;
            });
          }
          return;
        }

        if(mounted) {
          setState(() {
            _configLoadFailed = false;
            _isRetryingConfig = false;
          });
        }

        if(Get.find<AuthController>().getUserToken().isNotEmpty && (Get.find<SplashController>().configModel?.webSocketStatus ?? false)){
          PusherHelper.initializePusher();
        }

        Timer(const Duration(seconds: 1), () async {
          double? minimumVersion = _getMinimumVersion();
          if(minimumVersion == null) {
            debugPrint('[Splash] Falha de config: versão mínima ausente para plataforma atual');
            if(mounted) {
              setState(() {
                _configLoadFailed = true;
                _isRetryingConfig = false;
              });
            }
            return;
          }
          bool isMaintenanceMode = Get.find<SplashController>().configModel?.maintenanceMode ?? false;
          bool needsUpdate = AppConstants.appVersion < minimumVersion;

          if (needsUpdate || isMaintenanceMode) {
            Get.offNamed(RouteHelper.getUpdateRoute(needsUpdate));
          }else{
            if(widget.body != null) {
              await _handleNotificationRoutingWithPermissionGate(widget.body);
            }else{
              await _handleDefaultRouting();
            }
          }
        });
      } else {
        debugPrint('[Splash] Falha ao carregar config. Exibindo estado de erro/retry.');
        if(mounted) {
          setState(() {
            _configLoadFailed = true;
            _isRetryingConfig = false;
          });
        }
      }
    });
  }

  double? _getMinimumVersion() {
    if (GetPlatform.isAndroid) {
      return Get.find<SplashController>().configModel!.appMinimumVersionAndroid;
    } else if (GetPlatform.isIOS) {
      return Get.find<SplashController>().configModel!.appMinimumVersionIos;
    }
    return 0;
  }


  Future<void> _handleNotificationRoutingWithPermissionGate(NotificationBodyModel? notificationBody) async {
    if (!Get.find<AuthController>().isLoggedIn()) {
      Get.offNamed(RouteHelper.getSignInRoute());
      return;
    }

    Get.find<AuthController>().updateToken();
    await Get.find<ProfileController>().getProfile();
    final bool permissionsOk = await Get.find<PermissionFlowController>().ensureCriticalPermissions(openFlow: false);
    if (!permissionsOk) {
      await Get.find<PermissionFlowController>().openPermissionFlow(fromLogin: true, replaceRoute: true);
      return;
    }

    if (notificationBody?.notificationType == NotificationType.ride_request) {
      NotificationHelper.notificationToRoute(notificationBody!, formSplash: true);
    } else {
      await _handleDeliveryNotificationRouting(notificationBody);
    }
  }

  Future<void> _handleDeliveryNotificationRouting(NotificationBodyModel? notificationBody) async {
    final notificationType = notificationBody?.notificationType;

    final Map<NotificationType, Function> notificationActions = {
      NotificationType.order: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(notificationBody?.orderId, fromNotification: true)),
      NotificationType.order_request: () {
        if(isDeliveryManActive(showPopUp: false)){
          return Get.toNamed(RouteHelper.getMainRoute('order-request'));
        }
        else{
          return Get.toNamed(RouteHelper.getMainRoute('home'));
        }
      },
      NotificationType.block: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
      NotificationType.unblock: () => Get.offAllNamed(RouteHelper.getSignInRoute()),
      NotificationType.otp: () => null,
      NotificationType.unassign: () => Get.to(const DashboardScreen(pageIndex: 1)),
      NotificationType.message: () => Get.toNamed(RouteHelper.getChatRoute(notificationBody: notificationBody, conversationId: notificationBody?.conversationId, fromNotification: true)),
      NotificationType.general: () => Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true)),
    };

    notificationActions[notificationType]?.call();
  }

  Future<void> _handleDefaultRouting() async {
    if (Get.find<AuthController>().isLoggedIn()) {
      Get.find<AuthController>().updateToken();
      await Get.find<ProfileController>().getProfile();
      final bool permissionsOk = await Get.find<PermissionFlowController>().ensureCriticalPermissions(openFlow: false);
      if (permissionsOk) {
        Get.offNamed(RouteHelper.getInitialRoute());
      } else {
        await Get.find<PermissionFlowController>().openPermissionFlow(fromLogin: true, replaceRoute: true);
      }
    } else {
      Get.offNamed(RouteHelper.getSignInRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(Images.logo, width: 200),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text('suffix_name'.tr, style: robotoMedium, textAlign: TextAlign.center),
            if(_configLoadFailed) ...[
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text('Falha na conexão', style: robotoMedium, textAlign: TextAlign.center),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              const Text(
                'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
                  ElevatedButton(
                onPressed: _isRetryingConfig ? null : () {
                  if (kDebugMode) {
                    debugPrint('[Splash] Retry acionado pelo usuário');
                  }
                  _route();
                },
                child: Text(_isRetryingConfig ? 'Carregando...' : 'Tentar novamente'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
