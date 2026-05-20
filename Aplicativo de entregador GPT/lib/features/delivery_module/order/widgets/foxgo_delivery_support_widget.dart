import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoDeliverySupportWidget extends StatelessWidget {
  final OrderModel order;
  final bool parcel;

  const FoxGoDeliverySupportWidget({
    super.key,
    required this.order,
    required this.parcel,
  });

  static const List<_FoxGoSupportReason> _regularReasons = [
    _FoxGoSupportReason('loja_demora', 'Loja demorando', 'A loja está demorando para liberar o pedido.'),
    _FoxGoSupportReason('pedido_errado', 'Pedido errado ou incompleto', 'O pedido parece errado, incompleto ou com divergência.'),
    _FoxGoSupportReason('cliente_nao_aparece', 'Cliente não aparece', 'Cheguei no destino, mas o cliente não aparece ou não responde.'),
    _FoxGoSupportReason('endereco_incorreto', 'Endereço incorreto', 'O endereço parece incorreto ou não consigo localizar o destino.'),
    _FoxGoSupportReason('problema_moto', 'Problema na moto', 'Tive um problema com a moto/veículo durante a entrega.'),
    _FoxGoSupportReason('acidente', 'Acidente ou emergência', 'Sofri um acidente ou estou em situação de emergência.'),
    _FoxGoSupportReason('outro', 'Outro problema', 'Preciso de ajuda do suporte com esta entrega.'),
  ];

  static const List<_FoxGoSupportReason> _parcelReasons = [
    _FoxGoSupportReason('coleta_demora', 'Coleta demorando', 'A coleta está demorando ou o remetente não liberou o pacote.'),
    _FoxGoSupportReason('pacote_errado', 'Pacote errado ou danificado', 'O pacote está errado, danificado ou com divergência.'),
    _FoxGoSupportReason('destinatario_nao_aparece', 'Destinatário não aparece', 'Cheguei no destino, mas o destinatário não aparece ou não responde.'),
    _FoxGoSupportReason('endereco_incorreto', 'Endereço incorreto', 'O endereço parece incorreto ou não consigo localizar o destino.'),
    _FoxGoSupportReason('problema_moto', 'Problema na moto', 'Tive um problema com a moto/veículo durante a entrega.'),
    _FoxGoSupportReason('acidente', 'Acidente ou emergência', 'Sofri um acidente ou estou em situação de emergência.'),
    _FoxGoSupportReason('outro', 'Outro problema', 'Preciso de ajuda do suporte com esta entrega.'),
  ];

  List<_FoxGoSupportReason> get _reasons => parcel ? _parcelReasons : _regularReasons;

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
        Text('Precisa de ajuda?', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'Escolha um motivo e fale com o suporte Fox GO.',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        CustomButtonWidget(
          buttonText: 'Falar com suporte',
          onPressed: () => _openReasonSheet(context),
        ),
      ]),
    );
  }

  void _openReasonSheet(BuildContext context) {
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
            Text('Motivo do suporte', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              'A mensagem será aberta no chat com o suporte.',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _reasons.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final reason = _reasons[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason.title, style: robotoMedium),
                    subtitle: Text(reason.description, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openSupportChat(reason),
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

  void _openSupportChat(_FoxGoSupportReason reason) {
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
        fName: 'Suporte',
        lName: 'Fox GO',
      ),
      fromSupport: true,
      initialMessage: _buildInitialMessage(reason),
    ));
  }

  String _buildInitialMessage(_FoxGoSupportReason reason) {
    return [
      '[Suporte Fox GO Entregador]',
      'Motivo: ${reason.title}',
      'Pedido: #${order.id ?? 'não informado'}',
      'Status atual: ${order.orderStatus ?? 'não informado'}',
      'Tipo: ${parcel ? 'Entrega/Parcel' : 'Pedido/Delivery'}',
      '',
      reason.description,
    ].join('\n');
  }
}

class _FoxGoSupportReason {
  final String code;
  final String title;
  final String description;

  const _FoxGoSupportReason(this.code, this.title, this.description);
}
