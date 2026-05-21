import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/order_request_overlay_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/enums.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  bool _isNotificationPermissionGranted = true;
  bool _isBatteryOptimizationGranted = true;
  bool _isTogglingOnline = false;
  static const LatLng _fallbackPosition = LatLng(-23.5897, -46.5115);

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
    _mapController?.dispose();
    super.dispose();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  LatLng _driverPosition(ProfileController profileController) {
    final location = profileController.recordLocationBody;
    final double? lat = _toDouble(location?.latitude);
    final double? lng = _toDouble(location?.longitude);
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    return _fallbackPosition;
  }

  bool _hasRealLocation(ProfileController profileController) {
    final location = profileController.recordLocationBody;
    final double? lat = _toDouble(location?.latitude);
    final double? lng = _toDouble(location?.longitude);
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  Future<void> _centerOnDriver(ProfileController profileController) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _driverPosition(profileController), zoom: _hasRealLocation(profileController) ? 17 : 14),
      ),
    );
  }

  Future<void> _toggleOnline(ProfileController profileController) async {
    if (_isTogglingOnline || profileController.profileModel == null) return;
    setState(() => _isTogglingOnline = true);
    await profileController.updateActiveStatus();
    if (profileController.profileModel?.active == 1) {
      await profileController.recordLocation();
      await _centerOnDriver(profileController);
    }
    if (mounted) setState(() => _isTogglingOnline = false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      final bool isOnline = profileController.profileModel?.active == 1;
      final LatLng driverPosition = _driverPosition(profileController);
      final bool hasRealLocation = _hasRealLocation(profileController);

      return Scaffold(
        key: _scaffoldKey,
        drawer: _FoxGoHomeDrawer(
          onNavigateToOrders: widget.onNavigateToOrders,
          onNavigateToRequests: widget.onNavigateToRequests,
          onNavigateToProfile: widget.onNavigateToProfile,
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: driverPosition, zoom: hasRealLocation ? 17 : 14),
              myLocationEnabled: hasRealLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              markers: hasRealLocation
                  ? {
                      Marker(
                        markerId: const MarkerId('foxgo_driver_real_location'),
                        position: driverPosition,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: 'Sua localização'),
                      ),
                    }
                  : <Marker>{},
              onMapCreated: (controller) => _mapController = controller,
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleAction(
                      icon: Icons.menu_rounded,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Row(
                      children: [
                        _circleAction(
                          icon: Icons.flash_on_rounded,
                          onTap: widget.onNavigateToRequests ?? () => Get.toNamed(RouteHelper.getMainRoute('order-request')),
                        ),
                        const SizedBox(width: 12),
                        _circleAction(
                          icon: Icons.chat_bubble_rounded,
                          color: const Color(0xFF00B264),
                          iconColor: Colors.white,
                          onTap: () => Get.toNamed(RouteHelper.getConversationListRoute()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 18,
              bottom: 186 + MediaQuery.of(context).padding.bottom,
              child: _circleAction(
                icon: Icons.my_location_rounded,
                onTap: () => _centerOnDriver(profileController),
              ),
            ),

            Positioned(
              left: 18,
              bottom: 186 + MediaQuery.of(context).padding.bottom,
              child: _circleAction(
                icon: Icons.shield_rounded,
                color: const Color(0xFF0B7CFF),
                iconColor: Colors.white,
                onTap: () => Get.toNamed(RouteHelper.getPermissionCenterRoute()),
              ),
            ),

            if (!_isNotificationPermissionGranted || !_isBatteryOptimizationGranted)
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: _permissionBanner(),
              ),

            DraggableScrollableSheet(
              initialChildSize: 0.16,
              minChildSize: 0.16,
              maxChildSize: 0.46,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 18)],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 24 + MediaQuery.of(context).padding.bottom),
                    children: [
                      Center(
                        child: Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFFFEA00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _isTogglingOnline ? null : () => _toggleOnline(profileController),
                          child: _isTogglingOnline
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  isOnline ? 'Ficar offline' : 'Ficar online',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 25, letterSpacing: 1.1),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _panelCard(profileController),
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

  Widget _panelCard(ProfileController profileController) {
    final String todayEarning = PriceConverterHelper.convertPrice(profileController.profileModel?.todaysEarning ?? 0);
    final String advanceValue = PriceConverterHelper.convertPrice(profileController.profileModel?.withDrawableBalance ?? profileController.profileModel?.balance ?? 0);
    final String todayOrders = '${profileController.profileModel?.todaysOrderCount ?? 0}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Text('Painel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        SizedBox(width: 10),
        Icon(Icons.visibility_rounded, size: 23, color: Colors.black),
      ]),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9E9E9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Row(children: [
              Expanded(child: _metric(todayEarning, 'Ganhos hoje')),
              Container(width: 1, height: 28, color: const Color(0xFFECECEC)),
              Expanded(child: _metric(todayOrders, 'Pedidos hoje')),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF9EC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF0D7A20), size: 28),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Valor de adiantamento\ndisponível:', style: TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.w500)),
              ),
              Text(advanceValue, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 26),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _metric(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF626262), letterSpacing: 1.2)),
    ]);
  }

  Widget _permissionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Atenção: conceda permissões de notificação/bateria para manter o app online.',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _circleAction({required IconData icon, required VoidCallback onTap, Color color = Colors.white, Color iconColor = Colors.black}) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 56, height: 56, child: Icon(icon, color: iconColor, size: 28)),
      ),
    );
  }
}

class _FoxGoHomeDrawer extends StatelessWidget {
  const _FoxGoHomeDrawer({this.onNavigateToOrders, this.onNavigateToRequests, this.onNavigateToProfile});

  final Function()? onNavigateToOrders;
  final Function()? onNavigateToRequests;
  final Function()? onNavigateToProfile;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.86,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: GetBuilder<ProfileController>(builder: (profileController) {
              final name = '${profileController.profileModel?.fName ?? ''} ${profileController.profileModel?.lName ?? ''}'.trim();
              return Row(children: [
                const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF2F2F2), child: Icon(Icons.person_rounded, color: Colors.black, size: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(name.isEmpty ? 'Perfil' : name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]);
            }),
          ),
          const Divider(height: 22),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(Icons.support_agent_rounded, 'Ajuda / Suporte', () => Get.toNamed(RouteHelper.getConversationListRoute())),
                _drawerTile(Icons.chat_rounded, 'Chat', () => Get.toNamed(RouteHelper.getConversationListRoute())),
                _drawerTile(Icons.payments_rounded, 'Repasses', () => Get.toNamed(RouteHelper.getDisbursementRoute())),
                _drawerTile(Icons.account_balance_wallet_rounded, 'Carteira', () => Get.toNamed(RouteHelper.getMyAccountRoute())),
                _drawerTile(Icons.receipt_long_rounded, 'Pedidos', onNavigateToOrders ?? () => Get.toNamed(RouteHelper.getMainRoute('order'))),
                _drawerTile(Icons.local_activity_rounded, 'Solicitações', onNavigateToRequests ?? () => Get.toNamed(RouteHelper.getMainRoute('order-request'))),
                _drawerTile(Icons.person_rounded, 'Perfil', onNavigateToProfile ?? () => Get.toNamed(RouteHelper.getMainRoute('profile'))),
                _drawerTile(Icons.notifications_rounded, 'Notificações', () => Get.toNamed(RouteHelper.getNotificationRoute())),
                _drawerTile(Icons.settings_rounded, 'Configurações', () => Get.toNamed(RouteHelper.getPermissionCenterRoute())),
                _drawerTile(Icons.hub_rounded, 'Central Fox GO', () => Get.toNamed(RouteHelper.getConversationListRoute())),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
            child: _drawerTile(Icons.logout_rounded, 'Sair', () {
              Get.find<AuthController>().clearSharedData();
              Get.find<ProfileController>().stopLocationRecord();
              Get.offAllNamed(RouteHelper.getSignInRoute());
            }, isLogout: true),
          ),
        ]),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? const Color(0xFF321414) : Colors.black, size: 28),
      title: Text(title, style: TextStyle(fontSize: 21, fontWeight: isLogout ? FontWeight.w800 : FontWeight.w500, letterSpacing: 1.2)),
      trailing: isLogout ? null : const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A9A), size: 30),
      minLeadingWidth: 34,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      onTap: onTap,
    );
  }
}
