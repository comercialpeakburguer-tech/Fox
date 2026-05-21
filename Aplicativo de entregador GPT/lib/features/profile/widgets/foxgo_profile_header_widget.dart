import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoProfileHeaderWidget extends StatelessWidget {
  final ProfileController profileController;

  const FoxGoProfileHeaderWidget({
    super.key,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    final profile = profileController.profileModel;
    final bool isOnline = profile?.active == 1;
    final String name = [
      profile?.fName ?? '',
      profile?.lName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    final String displayName = name.isEmpty ? 'foxgo_profile_delivery_partner'.tr : name;
    final String phone = (profile?.phone ?? '').trim();
    final String email = (profile?.email ?? '').trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delivery_dining_rounded,
              color: Theme.of(context).primaryColor,
              size: 34,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                displayName,
                style: robotoBold.copyWith(fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'foxgo_profile_delivery_partner'.tr,
                style: robotoRegular.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                Icons.circle,
                size: 9,
                color: isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'online'.tr : 'offline'.tr,
                style: robotoBold.copyWith(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(children: [
          Expanded(
            child: _ProfileMiniCard(
              icon: Icons.verified_user_outlined,
              title: 'foxgo_profile_status'.tr,
              value: isOnline ? 'foxgo_profile_ready_to_receive'.tr : 'foxgo_profile_go_online_to_receive'.tr,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: _ProfileMiniCard(
              icon: Icons.receipt_long_outlined,
              title: 'foxgo_profile_completed_orders'.tr,
              value: '${profile?.orderCount ?? 0}',
            ),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        if (phone.isNotEmpty)
          _InfoRow(icon: Icons.phone_outlined, label: 'phone'.tr, value: phone),

        if (email.isNotEmpty)
          _InfoRow(icon: Icons.email_outlined, label: 'email'.tr, value: email),
      ]),
    );
  }
}

class _ProfileMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileMiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        const SizedBox(height: 8),
        Text(
          title,
          style: robotoRegular.copyWith(
            color: Theme.of(context).hintColor,
            fontSize: Dimensions.fontSizeExtraSmall,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          '$label: ',
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
        ),
        Expanded(
          child: Text(
            value,
            style: robotoMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
