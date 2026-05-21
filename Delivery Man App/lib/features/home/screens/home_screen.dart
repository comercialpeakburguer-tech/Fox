import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/chat/screens/conversation_screen.dart';
import 'package:sixam_mart_delivery/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/order_request_overlay_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/enums.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onNavigateToOrders});
  final Function()? onNavigateToOrders;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _listener;
  bool _isNotificationPermissionGranted = true;
  bool _isBatteryOptimizationGranted = true;
  final LatLng _mockPosition = const LatLng(-23.5897, -46.5115);

  @override
  void initState() {
    super.initState();
    _checkSystemNotification();
    _listener = AppLifecycleListener(onStateChange: _onStateChanged);
    _loadData();
    Future.delayed(const Duration(milliseconds: 200), checkPermission);
  }

  Future<void> _loadData() async {
    final orderController = Get.find<OrderController>();
    orderController.getIgnoreList();
    orderController.removeFromIgnoreList();
    await orderController.getRunningOrders(1, willUpdate: false);
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

  void _onStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermission();
      _refreshOnResume();
    }
  }

  Future<void> _refreshOnResume() async {
    try {
      final auth = Get.find<AuthController>();
      final profile = Get.find<ProfileController>().profileModel;
      final isOnline = auth.isLoggedIn() && profile != null && profile.active == 1;
      if (!isOnline) return;
      await OrderRequestOverlayHelper.refreshRequests(source: 'app-resumed', routeGlobal: true);
    } catch (_) {}
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

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isOnline = profileController.profileModel?.active == 1;
      return Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _mockPosition, zoom: 15),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('driver-position'),
                  position: _mockPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: 'Você está aqui'),
                ),
              },
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleAction(
                      icon: Icons.menu,
                      onTap: () => Get.toNamed(RouteHelper.getProfileRoute()),
                    ),
                    Row(
                      children: [
                        _circleAction(
                          icon: Icons.flash_on,
                          onTap: widget.onNavigateToOrders ?? () => Get.offAll(DashboardScreen(pageIndex: 2)),
                        ),
                        const SizedBox(width: 12),
                        _circleAction(
                          icon: Icons.chat_bubble_outline,
                          onTap: () => Get.to(() => const ConversationScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 16,
              bottom: 220,
              child: _circleAction(
                icon: Icons.shield_outlined,
                onTap: () => Get.toNamed(RouteHelper.getProfileRoute()),
              ),
            ),

            DraggableScrollableSheet(
              initialChildSize: 0.16,
              minChildSize: 0.16,
              maxChildSize: 0.38,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Center(
                        child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEB00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () => Get.find<ProfileController>().updateActiveStatus(),
                          child: Text(
                            isOnline ? 'Ficar offline' : 'Ficar online',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Arraste para cima para ver resumo do dia', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      _summaryTile('Saldo do dia', 'R\$ 0,00'),
                      _summaryTile('Entregas concluídas', '0'),
                      _summaryTile('Entregas recusadas', '0'),
                      if (!_isNotificationPermissionGranted || !_isBatteryOptimizationGranted)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Atenção: conceda permissões para manter o app online.', textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))],
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 56, height: 56, child: Icon(icon, color: Colors.black87)),
      ),
    );
  }
}
