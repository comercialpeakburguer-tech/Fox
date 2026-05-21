import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  void _openNinaChat(String reasonKey) {
    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: NotificationBodyModel(
        adminId: 0,
        type: AppConstants.admin,
      ),
      user: User(
        id: 0,
        fName: 'Nina',
        lName: 'Fox GO',
      ),
      fromSupport: true,
      initialMessage: [
        '[Nina - Ajuda Fox GO Entregador]',
        'Assunto: ${reasonKey.tr}',
        '',
        'Preciso de orientação sobre este tema.',
        '',
        'A Nina deve avaliar primeiro. Se não resolver com segurança, encaminhar para o setor responsável.',
      ].join('\n'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'foxgo_help_center_title'.tr),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('foxgo_help_nina_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'foxgo_help_nina_subtitle'.tr,
                style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              CustomButtonWidget(
                buttonText: 'foxgo_talk_to_nina'.tr,
                onPressed: () => _openNinaChat('foxgo_help_general_support'),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _HelpTile(
            icon: Icons.notifications_active_outlined,
            title: 'foxgo_help_new_call_title'.tr,
            description: 'foxgo_help_new_call_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_new_call_title'),
          ),
          _HelpTile(
            icon: Icons.storefront_outlined,
            title: 'foxgo_help_pickup_title'.tr,
            description: 'foxgo_help_pickup_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_pickup_title'),
          ),
          _HelpTile(
            icon: Icons.delivery_dining_outlined,
            title: 'foxgo_help_delivery_title'.tr,
            description: 'foxgo_help_delivery_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_delivery_title'),
          ),
          _HelpTile(
            icon: Icons.payments_outlined,
            title: 'foxgo_help_earnings_title'.tr,
            description: 'foxgo_help_earnings_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_earnings_title'),
          ),
          _HelpTile(
            icon: Icons.verified_user_outlined,
            title: 'foxgo_help_safety_title'.tr,
            description: 'foxgo_help_safety_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_safety_title'),
          ),
          _HelpTile(
            icon: Icons.workspace_premium_outlined,
            title: 'foxgo_help_delivery_style_title'.tr,
            description: 'foxgo_help_delivery_style_desc'.tr,
            onTap: () => _openNinaChat('foxgo_help_delivery_style_title'),
          ),
          _HelpTile(
            icon: Icons.chat_outlined,
            title: 'conversation'.tr,
            description: 'foxgo_help_conversation_desc'.tr,
            onTap: () => Get.toNamed(RouteHelper.getConversationListRoute()),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.10),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: robotoBold),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
