import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/features/home/widgets/active_order_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/home_earning_widget.dart';
import 'package:sixam_mart_delivery/features/home/widgets/order_count_widget.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoMapHomeWidget extends StatefulWidget {
  final ProfileController profileController;
  final Future<void> Function() onRefresh;
  final Function()? onNavigateToOrders;
  final Function()? onNavigateToRequests;
  final Function()? onNavigateToProfile;

  const FoxGoMapHomeWidget({
    super.key,
    required this.profileController,
    required this.onRefresh,
    this.onNavigateToOrders,
    this.onNavigateToRequests,
    this.onNavigateToProfile,
  });

  @override
  State<FoxGoMapHomeWidget> createState() => _FoxGoMapHomeWidgetState();
}

class _FoxGoMapHomeWidgetState extends State<FoxGoMapHomeWidget> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  static const LatLng _fallbackCenter = LatLng(-23.5505, -46.6333);

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  LatLng get _driverPosition {
    final dynamic location = widget.profileController.recordLocationBody;
    final double? lat = _toDouble(location?.latitude);
    final double? lng = _toDouble(location?.longitude);

    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }

    return _fallbackCenter;
  }

  bool get _hasLocation {
    final dynamic location = widget.profileController.recordLocationBody;
    final double? lat = _toDouble(location?.latitude);
    final double? lng = _toDouble(location?.longitude);
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  bool get _isOnline => widget.profileController.profileModel?.active == 1;

  Future<void> _toggleOnline() async {
    if (widget.profileController.profileModel == null) return;
    await widget.profileController.updateActiveStatus();
  }

  Future<void> _centerMap() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _driverPosition, zoom: _hasLocation ? 17 : 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng position = _driverPosition;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Stack(children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: _hasLocation ? 17 : 13),
            myLocationEnabled: _hasLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            markers: _hasLocation
                ? {
                    Marker(
                      markerId: const MarkerId('foxgo_driver_location'),
                      position: position,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    ),
                  }
                : <Marker>{},
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
          ),
        ),

        Center(
          child: IgnorePointer(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Color(0xFF1976D2),
                size: 34,
              ),
            ),
          ),
        ),

        Positioned(
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
          top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeSmall,
          child: Row(children: [
            _RoundHomeButton(
              color: const Color(0xFF6D28D9),
              icon: Icons.menu_rounded,
              tooltip: 'foxgo_home_menu'.tr,
              onTap: widget.onNavigateToProfile ?? () => Get.toNamed(RouteHelper.getMainRoute('profile')),
            ),
            const Spacer(),
            _RoundHomeButton(
              color: const Color(0xFFE53935),
              icon: Icons.assignment_rounded,
              tooltip: 'foxgo_home_requests'.tr,
              onTap: widget.onNavigateToRequests ?? () => Get.toNamed(RouteHelper.getMainRoute('order-request')),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _RoundHomeButton(
              color: const Color(0xFF1976D2),
              icon: Icons.chat_bubble_rounded,
              tooltip: 'foxgo_home_messages'.tr,
              onTap: () => Get.toNamed(RouteHelper.getConversationListRoute()),
            ),
          ]),
        ),

        Positioned(
          right: Dimensions.paddingSizeDefault,
          bottom: 168 + MediaQuery.of(context).padding.bottom,
          child: _RoundHomeButton(
            color: Theme.of(context).cardColor,
            iconColor: Theme.of(context).primaryColor,
            icon: Icons.my_location_rounded,
            tooltip: 'foxgo_home_my_location'.tr,
            onTap: _centerMap,
          ),
        ),

        DraggableScrollableSheet(
          minChildSize: 0.12,
          initialChildSize: 0.15,
          maxChildSize: 0.56,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  top: Dimensions.paddingSizeSmall,
                  bottom: 104 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'foxgo_home_earnings_panel'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isOnline ? 'foxgo_home_online_ready'.tr : 'foxgo_home_offline_hint'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ]),
                    ),
                    Text(
                      PriceConverterHelper.convertPrice(widget.profileController.profileModel?.todaysEarning ?? 0),
                      style: robotoBold.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ]),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  if (!_hasLocation)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Text(
                        'foxgo_home_waiting_location'.tr,
                        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  if (!_hasLocation) const SizedBox(height: Dimensions.paddingSizeDefault),
                  if (widget.profileController.profileModel?.earnings == 1)
                    HomeEarningWidget(profileController: widget.profileController),
                  OrderCountWidget(profileController: widget.profileController),
                  ActiveOrderWidget(
                    onNavigateToOrders: widget.onNavigateToOrders ?? () => Get.toNamed(RouteHelper.getMainRoute('order')),
                  ),
                ]),
              ),
            );
          },
        ),

        Positioned(
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
          bottom: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: widget.profileController.profileModel == null ? null : _toggleOnline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOnline ? const Color(0xFF0D7A20) : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isOnline ? Icons.check_circle_rounded : Icons.power_settings_new_rounded),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    _isOnline ? 'foxgo_home_online_button'.tr : 'foxgo_home_go_online'.tr,
                    style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _RoundHomeButton extends StatelessWidget {
  final Color color;
  final Color? iconColor;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundHomeButton({
    required this.color,
    this.iconColor,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: iconColor ?? Colors.white, size: 25),
          ),
        ),
      ),
    );
  }
}
