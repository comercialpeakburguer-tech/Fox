import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoHomeDriverPanelWidget extends StatelessWidget {
  final Function()? onNavigateToOrders;

  const FoxGoHomeDriverPanelWidget({
    super.key,
    this.onNavigateToOrders,
  });

  static const LatLng _fallbackLatLng = LatLng(-23.550520, -46.633308);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return GetBuilder<OrderController>(builder: (orderController) {
        final bool isOnline = profileController.profileModel?.active == 1;
        final int activeOrders = orderController.currentOrderList?.length ?? 0;
        final int pendingCalls = orderController.latestOrderList?.length ?? 0;

        final double? lat = profileController.recordLocationBody?.latitude;
        final double? lng = profileController.recordLocationBody?.longitude;
        final bool hasLocation = lat != null && lng != null && !(lat == 0 && lng == 0);
        final LatLng driverLatLng = hasLocation ? LatLng(lat, lng) : _fallbackLatLng;

        return Container(
          margin: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            SizedBox(
              height: 210,
              child: Stack(children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: driverLatLng,
                    zoom: hasLocation ? 16 : 11,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('foxgo_driver_current_position'),
                      position: driverLatLng,
                      infoWindow: InfoWindow(
                        title: isOnline ? 'foxgo_home_online'.tr : 'foxgo_home_offline'.tr,
                        snippet: hasLocation ? 'foxgo_home_current_position'.tr : 'foxgo_home_waiting_location'.tr,
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.42),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeDefault,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          isOnline ? 'foxgo_home_you_are_online'.tr : 'foxgo_home_you_are_offline'.tr,
                          style: robotoBold.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLocation ? 'foxgo_home_location_active'.tr : 'foxgo_home_location_waiting'.tr,
                          style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.88)),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.withValues(alpha: 0.92) : Colors.red.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isOnline ? 'online'.tr : 'offline'.tr,
                        style: robotoBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(children: [
                Row(children: [
                  _MetricTile(
                    title: 'foxgo_home_active_orders'.tr,
                    value: activeOrders.toString(),
                    icon: Icons.delivery_dining_rounded,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  _MetricTile(
                    title: 'foxgo_home_pending_calls'.tr,
                    value: pendingCalls.toString(),
                    icon: Icons.notifications_active_outlined,
                  ),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    key: const ValueKey('foxgo_home_big_online_button'),
                    icon: Icon(isOnline ? Icons.pause_circle_outline : Icons.play_circle_fill_rounded),
                    label: Text(
                      isOnline ? 'foxgo_home_go_offline'.tr : 'foxgo_home_go_online'.tr,
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: profileController.profileModel == null ? null : () async {
                      await profileController.updateActiveStatus();
                    },
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                InkWell(
                  onTap: onNavigateToOrders,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.receipt_long_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('foxgo_home_view_orders'.tr, style: robotoMedium),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        );
      });
    });
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: robotoBold.copyWith(fontSize: 20, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 2),
              Text(title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}
