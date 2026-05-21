import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoDeliverySupportWidget extends StatelessWidget {
  static final Map<int, DateTime> _pickupStartedAtByOrderId = <int, DateTime>{};
  final OrderModel order;
  final bool parcel;

  const FoxGoDeliverySupportWidget({
    super.key,
    required this.order,
    required this.parcel,
  });

  bool get _isPickupStage => order.orderStatus?.toLowerCase() == AppConstants.handover;

  DateTime? get _pickupStartedAt {
    final int key = order.id ?? 0;
    return _pickupStartedAtByOrderId.putIfAbsent(key, () => DateTime.now());
  }

  int get _pickupWaitedMinutes {
    final DateTime? started = _pickupStartedAt;
    if (started == null) {
      return 0;
    }
    return DateTime.now().difference(started).inMinutes;
  }

  int get _pickupRemainingMinutes {
    final int remaining = 10 - _pickupWaitedMinutes;
    return remaining > 0 ? remaining : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('foxgo_nina_support_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'foxgo_nina_support_subtitle'.tr,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        CustomButtonWidget(
          buttonText: 'foxgo_talk_to_nina'.tr,
          onPressed: () => _startNinaFlow(context),
        ),
      ]),
    );
  }

  void _startNinaFlow(BuildContext context) {
    if (_isPickupStage && _pickupRemainingMinutes > 0) {
      _showPickupWaitSheet(context);
      return;
    }

    _openReasonSheet(context);
  }

  void _showPickupWaitSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('foxgo_pickup_wait_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'foxgo_pickup_wait_description'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Text(
                '${'foxgo_time_remaining'.tr}: $_pickupRemainingMinutes min',
                style: robotoBold.copyWith(color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomButtonWidget(
              buttonText: 'back'.tr,
              onPressed: () => Get.back(),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openReasonSheet(BuildContext context) {
    final List<_FoxGoSupportReason> reasons = _isPickupStage ? _pickupReasons : _generalReasons;

    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('foxgo_support_reason_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              'foxgo_support_reason_subtitle'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reasons.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reason = reasons[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason.title.tr, style: robotoMedium),
                    subtitle: Text(reason.description.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleReason(context, reason),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _handleReason(BuildContext context, _FoxGoSupportReason reason) {
    if (reason.code == 'pedido_nao_pronto') {
      _showOrderNotReadySheet(context);
      return;
    }

    if (reason.code == 'outro') {
      _showDynamicWaitSheet(context, reason);
      return;
    }

    _openSupportChat(reason);
  }

  void _showOrderNotReadySheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('foxgo_order_not_ready_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'foxgo_order_not_ready_description'.tr,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomButtonWidget(
              buttonText: 'foxgo_wait_more_5_min'.tr,
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomButtonWidget(
              buttonText: 'foxgo_talk_to_nina'.tr,
              backgroundColor: Theme.of(context).disabledColor,
              onPressed: () => _openSupportChat(
                const _FoxGoSupportReason(
                  'pedido_nao_pronto',
                  'foxgo_reason_order_not_ready',
                  'foxgo_reason_order_not_ready_description',
                ),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomButtonWidget(
              buttonText: 'foxgo_release_to_another_deliveryman'.tr,
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () => _releaseToAnotherDeliveryman(),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }


  Future<void> _releaseToAnotherDeliveryman() async {
    if(Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    await Get.find<OrderController>().releaseToAnotherDeliveryman(
      order.id,
      'pedido_nao_pronto_entregador_solicitou_outro_entregador',
    );
  }

  void _showDynamicWaitSheet(BuildContext context, _FoxGoSupportReason reason) {
    final int waitMinutes = 15 + Random().nextInt(16);

    Get.bottomSheet(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('foxgo_nina_wait_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              '${'foxgo_nina_wait_description'.tr} $waitMinutes min.',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomButtonWidget(
              buttonText: 'foxgo_talk_to_nina'.tr,
              onPressed: () => _openSupportChat(reason, extraWaitMinutes: waitMinutes),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openSupportChat(_FoxGoSupportReason reason, {int? extraWaitMinutes}) {
    if(Get.isBottomSheetOpen ?? false) {
      Get.back();
    }

    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(
        orderId: order.id,
        adminId: 0,
        type: AppConstants.admin,
      ),
      user: User(
        id: 0,
        fName: 'Nina',
        lName: 'Fox GO',
      ),
      fromSupport: true,
      initialMessage: _buildInitialMessage(reason, extraWaitMinutes: extraWaitMinutes),
    ));
  }

  String _buildInitialMessage(_FoxGoSupportReason reason, {int? extraWaitMinutes}) {
    final location = Get.find<ProfileController>().recordLocationBody;

    return [
      '[Nina - Suporte Fox GO]',
      'Motivo: ${reason.title.tr}',
      'Pedido: #${order.id ?? 'não informado'}',
      'Status atual: ${order.orderStatus ?? 'não informado'}',
      'Tipo: ${parcel ? 'Entrega/Parcel' : 'Pedido/Delivery'}',
      'Loja/Origem: ${(order.storeName ?? '').trim().isEmpty ? 'não informado' : order.storeName}',
      'Endereço de retirada: ${(order.storeAddress ?? '').trim().isEmpty ? 'não informado' : order.storeAddress}',
      'Tempo em retirada: $_pickupWaitedMinutes min',
      if(extraWaitMinutes != null) 'Espera dinâmica sugerida: $extraWaitMinutes min',
      'Localização atual: ${location?.latitude ?? 'sem latitude'}, ${location?.longitude ?? 'sem longitude'}',
      '',
      reason.description.tr,
      '',
      'A Nina deve avaliar o caso primeiro. Se não conseguir resolver com segurança, encaminhar para o setor responsável.',
    ].join('\n');
  }

  static const List<_FoxGoSupportReason> _pickupReasons = [
    _FoxGoSupportReason('pedido_nao_pronto', 'foxgo_reason_order_not_ready', 'foxgo_reason_order_not_ready_description'),
    _FoxGoSupportReason('loja_fechada', 'foxgo_reason_store_closed', 'foxgo_reason_store_closed_description'),
    _FoxGoSupportReason('outro', 'foxgo_reason_other_problem', 'foxgo_reason_other_problem_description'),
  ];

  static const List<_FoxGoSupportReason> _generalReasons = [
    _FoxGoSupportReason('cliente_nao_aparece', 'foxgo_reason_customer_not_found', 'foxgo_reason_customer_not_found_description'),
    _FoxGoSupportReason('endereco_incorreto', 'foxgo_reason_wrong_address', 'foxgo_reason_wrong_address_description'),
    _FoxGoSupportReason('problema_veiculo', 'foxgo_reason_vehicle_problem', 'foxgo_reason_vehicle_problem_description'),
    _FoxGoSupportReason('emergencia', 'foxgo_reason_emergency', 'foxgo_reason_emergency_description'),
    _FoxGoSupportReason('outro', 'foxgo_reason_other_problem', 'foxgo_reason_other_problem_description'),
  ];
}

class _FoxGoSupportReason {
  final String code;
  final String title;
  final String description;

  const _FoxGoSupportReason(this.code, this.title, this.description);
}
