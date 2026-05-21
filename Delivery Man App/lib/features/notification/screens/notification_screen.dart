import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/images.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/features/notification/widgets/notification_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatefulWidget {
  final bool fromNotification;
  const NotificationScreen({super.key, this.fromNotification = false});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    Get.find<NotificationController>().getNotificationList();
  }

  void _handleBack() {
    if (widget.fromNotification) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBack(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: GetBuilder<NotificationController>(builder: (notificationController) {
            final notifications = notificationController.notificationList;
            if (notifications != null) {
              notificationController.saveSeenNotificationCount(notifications.length);
            }

            final seenIds = notificationController.getSeenNotificationIdList() ?? [];
            final unreadCount = notifications?.where((item) => !seenIds.contains(item.id)).length ?? 0;
            final filtered = _filteredNotifications(notifications ?? [], seenIds);

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
                  ),
                  Expanded(
                    child: Text(
                      'NOTIFICAÇÕES',
                      textAlign: TextAlign.center,
                      style: robotoBold.copyWith(fontSize: 15, letterSpacing: 1.5, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Text('Suas notificações', style: robotoBold.copyWith(fontSize: 34, height: 1.05, color: Colors.black)),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(children: [
                  _filterChip(label: 'Todas', filter: _NotificationFilter.all),
                  const SizedBox(width: 10),
                  _filterChip(label: 'Não lidas', counter: unreadCount, filter: _NotificationFilter.unread),
                  const SizedBox(width: 10),
                  _filterChip(label: 'Alertas', filter: _NotificationFilter.alerts),
                ]),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: notifications == null
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(child: Text('no_notification_found'.tr, style: robotoMedium.copyWith(color: Colors.black54)))
                        : RefreshIndicator(
                            onRefresh: () async => notificationController.getNotificationList(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final bool isSeen = seenIds.contains(item.id);
                                final bool addDateTitle = index == 0 || _dateKey(filtered[index - 1]) != _dateKey(item);

                                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (addDateTitle)
                                    Padding(
                                      padding: EdgeInsets.only(top: index == 0 ? 2 : 18, bottom: 12),
                                      child: Text(
                                        _dateTitle(item),
                                        style: robotoMedium.copyWith(fontSize: 15, color: const Color(0xFF6B6B6B)),
                                      ),
                                    ),
                                  _notificationCard(notificationController, item, isSeen),
                                ]);
                              },
                            ),
                          ),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required _NotificationFilter filter, int? counter}) {
    final selected = _filter == filter;
    final text = counter == null ? label : '$label ($counter)';
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.black : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          text,
          style: robotoMedium.copyWith(fontSize: 15, color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _notificationCard(NotificationController controller, NotificationModel item, bool isSeen) {
    final hasImage = item.imageFullUrl != null && item.imageFullUrl!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if(item.id != null) {
            controller.addSeenNotificationId(item.id!);
          }
          showDialog(
            context: context,
            builder: (BuildContext context) => NotificationDialogWidget(notificationModel: item),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isSeen ? const Color(0xFFEFEFEF) : const Color(0xFFFFD400), width: isSeen ? 1 : 1.4),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSeen ? Colors.transparent : const Color(0xFFFFD400),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(fontSize: 17, color: Colors.black),
                ),
                const SizedBox(height: 7),
                Text(
                  item.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: 14, color: const Color(0xFF626262), height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  DateConverterHelper.beforeTimeFormat(item.updatedAt ?? item.createdAt ?? '', isWithUTC: true),
                  style: robotoMedium.copyWith(fontSize: 12, color: const Color(0xFF9B9B9B)),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF1F1F1),
                child: hasImage
                    ? CustomImageWidget(image: item.imageFullUrl!, width: 72, height: 72, fit: BoxFit.cover)
                    : Image.asset(_fallbackImage(item), width: 72, height: 72, fit: BoxFit.cover),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<NotificationModel> _filteredNotifications(List<NotificationModel> notifications, List<int> seenIds) {
    switch (_filter) {
      case _NotificationFilter.unread:
        return notifications.where((item) => !seenIds.contains(item.id)).toList();
      case _NotificationFilter.alerts:
        return notifications.where((item) {
          final type = item.data?.type?.toLowerCase() ?? '';
          return type.contains('order') || type.contains('alert') || type.contains('status') || type.contains('warning');
        }).toList();
      case _NotificationFilter.all:
        return notifications;
    }
  }

  String _fallbackImage(NotificationModel item) {
    final type = item.data?.type?.toLowerCase() ?? '';
    if(type.contains('order')) return Images.orderNotification;
    return Images.notificationPlaceholder;
  }

  String _dateKey(NotificationModel item) {
    final createdAt = item.createdAt;
    if(createdAt == null || createdAt.isEmpty) return '';
    final date = DateConverterHelper.dateTimeStringToDate(createdAt);
    return '${date.year}-${date.month}-${date.day}';
  }

  String _dateTitle(NotificationModel item) {
    final createdAt = item.createdAt;
    if(createdAt == null || createdAt.isEmpty) return '';
    return DateConverterHelper.convertTodayYesterdayDate(createdAt);
  }
}

enum _NotificationFilter { all, unread, alerts }
