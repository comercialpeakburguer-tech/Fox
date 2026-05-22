import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/support/widgets/foxgo_support_center_sheet.dart';
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
  static const Color _foxYellow = Color(0xFFFFEA00);
  static const Color _foxGreen = Color(0xFF00B264);
  static const Color _foxDark = Color(0xFF101316);

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
        drawerScrimColor: Colors.black.withValues(alpha: 0.58),
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
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.46),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.32, 0.72],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SizedBox(
                  height: 64,
                  child: Stack(alignment: Alignment.center, children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _circleAction(
                        icon: Icons.menu_rounded,
                        color: Colors.black.withValues(alpha: 0.72),
                        iconColor: Colors.white,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                    const _FoxGoWordmark(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _circleAction(
                            icon: Icons.flash_on_rounded,
                            color: Colors.black.withValues(alpha: 0.70),
                            iconColor: _foxYellow,
                            onTap: widget.onNavigateToRequests ?? () => Get.toNamed(RouteHelper.getMainRoute('order-request')),
                          ),
                          const SizedBox(width: 12),
                          _circleAction(
                            icon: Icons.chat_bubble_rounded,
                            color: _foxGreen,
                            iconColor: Colors.white,
                            onTap: () => Get.toNamed(RouteHelper.getConversationListRoute()),
                          ),
                        ],
                      ),
                    ),
                  ]),
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
                top: MediaQuery.of(context).padding.top + 86,
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
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _foxYellow,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: _isTogglingOnline ? null : () => _toggleOnline(profileController),
                          icon: _isTogglingOnline ? const SizedBox.shrink() : const Icon(Icons.bolt_rounded, size: 25),
                          label: _isTogglingOnline
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  isOnline ? 'Ficar offline' : 'Ficar online',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 23, letterSpacing: 1.1),
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
    final String weeklyBalance = PriceConverterHelper.convertPrice(profileController.profileModel?.thisWeekEarning ?? 0);
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
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getEarningReportRoute()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF9EC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF0D7A20), size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Saldo da semana', style: TextStyle(fontSize: 17, height: 1.35, fontWeight: FontWeight.w600)),
                ),
                Text(weeklyBalance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: Colors.black, size: 26),
              ]),
            ),
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

class _FoxGoWordmark extends StatelessWidget {
  const _FoxGoWordmark();

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      RichText(
        text: const TextSpan(children: [
          TextSpan(text: 'FOX ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic, letterSpacing: 1.1)),
          TextSpan(text: 'GO', style: TextStyle(color: Color(0xFFFFEA00), fontWeight: FontWeight.w900, fontSize: 22, fontStyle: FontStyle.italic, letterSpacing: 1.1)),
        ]),
      ),
      const SizedBox(height: 2),
      const Text('DELIVERY', style: TextStyle(color: Colors.white70, fontSize: 8.5, letterSpacing: 3.2, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _FoxGoHomeDrawer extends StatelessWidget {
  const _FoxGoHomeDrawer({this.onNavigateToOrders, this.onNavigateToRequests, this.onNavigateToProfile});

  final Function()? onNavigateToOrders;
  final Function()? onNavigateToRequests;
  final Function()? onNavigateToProfile;
  static const Color _drawerDark = Color(0xFF080B0D);
  static const Color _foxYellow = Color(0xFFFFEA00);
  static const Color _dangerRed = Color(0xFFFF6B7D);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _drawerDark,
      width: MediaQuery.of(context).size.width * 0.86,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 22, 24),
            child: Row(children: [
              GetBuilder<ProfileController>(builder: (profileController) {
                final imageUrl = profileController.profileModel?.imageFullUrl?.toString() ?? '';
                return Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _foxYellow,
                    border: Border.all(color: _foxYellow, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? CustomImageWidget(image: imageUrl, height: 54, width: 54, fit: BoxFit.cover)
                        : Container(
                            color: Colors.white,
                            child: const Icon(Icons.person_rounded, color: Colors.black, size: 34),
                          ),
                  ),
                );
              }),
              const SizedBox(width: 14),
              const Expanded(child: _FoxGoWordmark()),
            ]),
          ),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 22), color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                _drawerTile(Icons.support_agent_rounded, 'Ajuda / Suporte', () {
                  Get.back();
                  FoxGoSupportCenterSheet.show(initialReason: 'Ajuda pelo menu lateral');
                }),
                _drawerTile(Icons.chat_bubble_outline_rounded, 'Mensagens', () => Get.toNamed(RouteHelper.getConversationListRoute())),
                _drawerTile(Icons.payments_rounded, 'Repasses', () => Get.toNamed(RouteHelper.getDisbursementRoute())),
                _drawerTile(Icons.analytics_rounded, 'Relatórios / Ganhos', () => Get.toNamed(RouteHelper.getEarningReportRoute())),
                _drawerTile(Icons.account_balance_wallet_rounded, 'Carteira', () => Get.toNamed(RouteHelper.getMyAccountRoute())),
                _drawerTile(Icons.receipt_long_rounded, 'Pedidos', onNavigateToOrders ?? () => Get.toNamed(RouteHelper.getMainRoute('order'))),
                _drawerTile(Icons.local_activity_rounded, 'Solicitações', onNavigateToRequests ?? () => Get.toNamed(RouteHelper.getMainRoute('order-request'))),
                _drawerTile(Icons.person_outline_rounded, 'Perfil', onNavigateToProfile ?? () => Get.toNamed(RouteHelper.getMainRoute('profile'))),
                _drawerTile(Icons.settings_rounded, 'Configurações', () => Get.toNamed(RouteHelper.getPermissionCenterRoute())),
                _drawerTile(Icons.shield_rounded, 'Central Fox GO', () {
                  Get.back();
                  FoxGoSupportCenterSheet.show(initialReason: 'Central Fox GO');
                }),
              ],
            ),
          ),
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 22), color: Colors.white.withValues(alpha: 0.10)),
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
    final Color iconColor = isLogout ? _dangerRed : _foxYellow;
    final Color textColor = isLogout ? _dangerRed : Colors.white.withValues(alpha: 0.92);
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 27),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 18.5, fontWeight: isLogout ? FontWeight.w800 : FontWeight.w500, letterSpacing: 0.9)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.56), size: 28),
      minLeadingWidth: 34,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      onTap: onTap,
    );
  }
}
