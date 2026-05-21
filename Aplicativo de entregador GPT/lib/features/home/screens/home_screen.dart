import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/home/widgets/active_order_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/active_ride_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/cash_in_hand_card_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/home_earning_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/foxgo_map_home_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/order_count_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/referal_card_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/ride_activity_view.dart';
import 'package:sixam_mart_delivery/features/home/widgets/ride_floating_button_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/ride_order_count_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/vehicle_add_widget.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/order_request_overlay_helper.dart';
import 'package:sixam_mart_delivery/features/ride_module/ride_order/controllers/ride_controller.dart';
import 'package:sixam_mart_delivery/features/ride_module/trip/controllers/trip_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToOrders, this.onNavigateToRequests, this.onNavigateToProfile});
  final Function()? onNavigateToOrders;
  final Function()? onNavigateToRequests;
  final Function()? onNavigateToProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late final AppLifecycleListener _listener;
  bool _isNotificationPermissionGranted = true;
  bool _isBatteryOptimizationGranted = true;
  bool isRideActive = AppConstants.appMode == AppMode.ride;

  @override
  void initState() {
    super.initState();

    _checkSystemNotification();

    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );

    _loadData();

    Future.delayed(const Duration(milliseconds: 200), () {
      checkPermission();
    });
  }

  Future<void> _loadData() async {

    Get.find<OrderController>().getIgnoreList();
    Get.find<OrderController>().removeFromIgnoreList();

    if(isRideActive){
      Get.find<RideController>().getLastRideDetail();
      Get.find<TripController>().getDailyLog();
      Get.find<TripController>().rideCancellationReasonList();
      Get.find<RideController>().ongoingTripList();
      Get.find<ProfileController>().getProfileLevelInfo();
      await Get.find<TripController>().getTripList(1);
    }else{
      await Get.find<OrderController>().getRunningOrders(1, willUpdate: false);
    }
    await Get.find<ProfileController>().getProfile();
    await Get.find<NotificationController>().getNotificationList();
  }

  Future<void> _checkSystemNotification() async {
    await Get.find<PermissionFlowController>().refreshStatuses();
    final bool notificationMissing = Get.find<PermissionFlowController>().checks.any(
      (check) => check.step == FoxGoPermissionStep.notifications && check.needsAction,
    );
    if (notificationMissing) {
      await Get.find<AuthController>().setNotificationActive(false);
    }
  }

  // Listen to the app lifecycle state changes
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        checkPermission();
        _refreshOnResume();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        break;
    }
  }


  Future<void> _refreshOnResume() async {
    try {
      final auth = Get.find<AuthController>();
      final profile = Get.find<ProfileController>().profileModel;
      final isOnline = auth.isLoggedIn() && profile != null && profile.active == 1;
      debugPrint('FoxGoOrderRefresh source=app-resumed online=$isOnline');
      if(!isOnline) return;
      await OrderRequestOverlayHelper.refreshRequests(source: 'app-resumed', routeGlobal: true);
    } catch (error, stackTrace) {
      debugPrint('FoxGoOrderRefresh source=app-resumed erro=$error\n$stackTrace');
    }
  }

  Future<void> checkPermission() async {
    final controller = Get.find<PermissionFlowController>();
    await controller.refreshStatuses();
    final notificationMissing = controller.checks.any((check) => check.step == FoxGoPermissionStep.notifications && check.needsAction);
    final batteryMissing = controller.checks.any((check) => check.step == FoxGoPermissionStep.batteryOptimization && check.needsAction);
    if (mounted) {
      setState(() {
        _isNotificationPermissionGranted = !notificationMissing;
        _isBatteryOptimizationGranted = !batteryMissing;
      });
    }
    Get.find<ProfileController>().setBackgroundNotificationActive(!batteryMissing);
  }


  Future<void> requestNotificationPermission() async {
    await Get.find<PermissionFlowController>().openPermissionFlow(startAt: FoxGoPermissionStep.notifications);
    await checkPermission();
  }


  void requestBatteryOptimization() async {
    await Get.find<PermissionFlowController>().openPermissionFlow(startAt: FoxGoPermissionStep.batteryOptimization);
    await checkPermission();
  }


  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController){

      bool isRideActive = AppConstants.appMode == AppMode.ride;

      return Scaffold(
        body: Column(children: [

          if(!_isNotificationPermissionGranted)
            permissionWarning(isBatteryPermission: false, onTap: requestNotificationPermission, closeOnTap: () {
              setState(() {
                _isNotificationPermissionGranted = true;
              });
            }),

          if(!_isBatteryOptimizationGranted)
            permissionWarning(isBatteryPermission: true, onTap: requestBatteryOptimization, closeOnTap: () {
              setState(() {
                _isBatteryOptimizationGranted = true;
              });
            }),

          Expanded(
            child: FoxGoMapHomeWidget(
              profileController: profileController,
              onRefresh: _loadData,
              onNavigateToOrders: widget.onNavigateToOrders,
              onNavigateToRequests: widget.onNavigateToRequests,
              onNavigateToProfile: widget.onNavigateToProfile,
            ),
          ),
        ]),
      );
    });
  }

  Widget permissionWarning({required bool isBatteryPermission, required Function() onTap, required Function() closeOnTap}) {
    return GetPlatform.isAndroid ? Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.7),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(children: [

            if(isBatteryPermission)
              Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Image.asset(Images.allertIcon, height: 20, width: 20),
              ),

            Expanded(
              child: Row(children: [
                Flexible(
                  child: Text(
                    isBatteryPermission ? 'for_better_performance_allow_notification_to_run_in_background'.tr
                        : 'notification_is_disabled_please_allow_notification'.tr,
                    maxLines: 2, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                const Icon(Icons.arrow_circle_right_rounded, color: Colors.white, size: 24,),
              ]),
            ),

            // const SizedBox(width: 20),
          ]),
        ),
      ),
    ) : const SizedBox();
  }
}
