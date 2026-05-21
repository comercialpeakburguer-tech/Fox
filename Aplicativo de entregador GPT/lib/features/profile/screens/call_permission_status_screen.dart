import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/helper/call_permission_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class CallPermissionStatusScreen extends StatefulWidget {
  const CallPermissionStatusScreen({super.key});

  @override
  State<CallPermissionStatusScreen> createState() => _CallPermissionStatusScreenState();
}

class _CallPermissionStatusScreenState extends State<CallPermissionStatusScreen> {
  bool _loading = true;
  bool _notifications = false;
  bool _overlay = false;
  bool _fsi = false;
  bool _battery = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    _notifications = await CallPermissionHelper.isNotificationGranted();
    _overlay = await CallPermissionHelper.isOverlayGranted();
    _fsi = await CallPermissionHelper.isFullScreenIntentAvailable();
    _battery = await CallPermissionHelper.isIgnoringBatteryOptimizations();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  int get _activeCount {
    int total = 0;
    if (_notifications) total++;
    if (_overlay) total++;
    if (_battery) total++;
    if (_fsi) total++;
    return total;
  }

  bool get _criticalReady => _notifications && _overlay && _battery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'foxgo_call_permissions_title'.tr),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: (_criticalReady ? Colors.green : Theme.of(context).primaryColor).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _criticalReady ? 'foxgo_permissions_ready_title'.tr : 'foxgo_permissions_attention_title'.tr,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        _criticalReady ? 'foxgo_permissions_ready_desc'.tr : 'foxgo_permissions_attention_desc'.tr,
                        style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      LinearProgressIndicator(value: _activeCount / 4),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        '${'foxgo_permissions_active_count'.tr}: $_activeCount/4',
                        style: robotoMedium,
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _PermissionTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'foxgo_perm_notifications_title'.tr,
                    description: 'foxgo_perm_notifications_desc'.tr,
                    status: _notifications,
                    requiredItem: true,
                    buttonText: 'foxgo_perm_open_notifications'.tr,
                    onTap: _notifications
                        ? null
                        : () async {
                            await CallPermissionHelper.openNotificationSettings();
                            await _loadStatus();
                          },
                  ),
                  _PermissionTile(
                    icon: Icons.layers_outlined,
                    title: 'foxgo_perm_overlay_title'.tr,
                    description: 'foxgo_perm_overlay_desc'.tr,
                    status: _overlay,
                    requiredItem: true,
                    buttonText: 'foxgo_perm_open_overlay'.tr,
                    onTap: _overlay
                        ? null
                        : () async {
                            await CallPermissionHelper.openOverlaySettings();
                            await _loadStatus();
                          },
                  ),
                  _PermissionTile(
                    icon: Icons.battery_saver_outlined,
                    title: 'foxgo_perm_battery_title'.tr,
                    description: 'foxgo_perm_battery_desc'.tr,
                    status: _battery,
                    requiredItem: true,
                    buttonText: 'foxgo_perm_open_battery'.tr,
                    onTap: _battery
                        ? null
                        : () async {
                            await CallPermissionHelper.openBatterySettings();
                            await _loadStatus();
                          },
                  ),
                  _PermissionTile(
                    icon: Icons.fullscreen_outlined,
                    title: 'foxgo_perm_fsi_title'.tr,
                    description: 'foxgo_perm_fsi_desc'.tr,
                    status: _fsi,
                    requiredItem: false,
                    buttonText: 'foxgo_perm_fsi_info'.tr,
                    onTap: null,
                  ),

                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('foxgo_permissions_device_tips_title'.tr, style: robotoBold),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text('foxgo_permissions_device_tips_desc'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                    ]),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  CustomButtonWidget(buttonText: 'foxgo_refresh_permissions'.tr, onPressed: _loadStatus),
                ],
              ),
            ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool status;
  final bool requiredItem;
  final String buttonText;
  final VoidCallback? onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.requiredItem,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status ? Colors.green : Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.10),
            child: Icon(icon, color: statusColor),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: robotoBold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status ? 'foxgo_perm_status_ok'.tr : 'foxgo_perm_status_attention'.tr,
                    style: robotoMedium.copyWith(color: statusColor, fontSize: Dimensions.fontSizeExtraSmall),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(description, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
              const SizedBox(height: 6),
              Text(
                requiredItem ? 'foxgo_perm_required'.tr : 'foxgo_perm_optional'.tr,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
              ),
            ]),
          ),
        ]),
        if (onTap != null) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
          CustomButtonWidget(buttonText: buttonText, onPressed: onTap, height: 42),
        ],
      ]),
    );
  }
}
