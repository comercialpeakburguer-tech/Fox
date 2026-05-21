import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoSupportCenterSheet extends StatelessWidget {
  final int? orderId;
  final String? initialReason;

  const FoxGoSupportCenterSheet({super.key, this.orderId, this.initialReason});

  static void show({int? orderId, String? initialReason}) {
    Get.bottomSheet(
      FoxGoSupportCenterSheet(orderId: orderId, initialReason: initialReason),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasons = <_SupportReason>[
      _SupportReason(Icons.person_search_rounded, 'Cliente não localizado', 'Aguardar 5 minutos e falar com suporte.'),
      _SupportReason(Icons.storefront_rounded, 'Problema na loja', 'Pedido atrasado, loja fechada ou retirada com dificuldade.'),
      _SupportReason(Icons.password_rounded, 'Problema com OTP', 'Código incorreto, não recebido ou validação travada.'),
      _SupportReason(Icons.route_rounded, 'Problema na rota', 'Endereço, distância, redispatch ou parada incorreta.'),
      _SupportReason(Icons.account_balance_wallet_rounded, 'Repasses / carteira', 'Saldo, conta Pix/Banco ou pagamento.'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: const Color(0xFFFFF4C6), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.support_agent_rounded, color: Colors.black, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Central Fox GO', style: robotoBold.copyWith(fontSize: 25, color: Colors.black)),
              const SizedBox(height: 4),
              Text('Escolha um motivo para agilizar o atendimento.', style: robotoRegular.copyWith(color: const Color(0xFF666666), fontSize: Dimensions.fontSizeDefault)),
            ])),
          ]),
          const SizedBox(height: 18),
          if(orderId != null || initialReason != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(18)),
              child: Text(
                '${orderId != null ? 'Pedido #$orderId' : 'Atendimento'}${initialReason != null ? ' • $initialReason' : ''}',
                style: robotoMedium.copyWith(color: Colors.black87),
              ),
            ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: reasons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final reason = reasons[index];
                return InkWell(
                  onTap: () => _openChat(reason.title),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFECECEC)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(15)),
                        child: Icon(reason.icon, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(reason.title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black)),
                        const SizedBox(height: 3),
                        Text(reason.subtitle, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF666666))),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9A9A9A)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _openChat('Atendimento geral'),
              icon: const Icon(Icons.chat_rounded),
              label: Text('Abrir chat com suporte', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _openChat(String reason) {
    if(Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(
        orderId: orderId,
        adminId: 0,
        type: AppConstants.admin,
      ),
      user: User(id: 0, fName: 'Suporte Fox GO', lName: reason, imageFullUrl: '', phone: ''),
      conversationId: null,
      fromNotification: false,
      fromSupport: true,
    ));
  }
}

class _SupportReason {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportReason(this.icon, this.title, this.subtitle);
}
