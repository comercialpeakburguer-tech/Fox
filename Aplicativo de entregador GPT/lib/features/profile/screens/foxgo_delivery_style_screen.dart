import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoDeliveryStyleScreen extends StatelessWidget {
  const FoxGoDeliveryStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('foxgo_delivery_style_title'.tr),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          children: [
            _HeroCard(primary: primary),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            _SectionCard(
              icon: Icons.check_circle_outline,
              title: 'foxgo_delivery_style_ready_title'.tr,
              items: [
                'foxgo_delivery_style_ready_battery'.tr,
                'foxgo_delivery_style_ready_internet'.tr,
                'foxgo_delivery_style_ready_gps'.tr,
                'foxgo_delivery_style_ready_permissions'.tr,
                'foxgo_delivery_style_ready_online'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.notifications_active_outlined,
              title: 'foxgo_delivery_style_calls_title'.tr,
              items: [
                'foxgo_delivery_style_calls_accept_fast'.tr,
                'foxgo_delivery_style_calls_check_value'.tr,
                'foxgo_delivery_style_calls_no_timeout'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.storefront_outlined,
              title: 'foxgo_delivery_style_pickup_title'.tr,
              items: [
                'foxgo_delivery_style_pickup_confirm_order'.tr,
                'foxgo_delivery_style_pickup_code'.tr,
                'foxgo_delivery_style_pickup_not_ready'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.delivery_dining_outlined,
              title: 'foxgo_delivery_style_delivery_title'.tr,
              items: [
                'foxgo_delivery_style_delivery_route'.tr,
                'foxgo_delivery_style_delivery_otp'.tr,
                'foxgo_delivery_style_delivery_proof'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.workspace_premium_outlined,
              title: 'foxgo_delivery_style_score_title'.tr,
              items: [
                'foxgo_delivery_style_score_finish'.tr,
                'foxgo_delivery_style_score_support'.tr,
                'foxgo_delivery_style_score_safety'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.payments_outlined,
              title: 'foxgo_delivery_style_earnings_title'.tr,
              items: [
                'foxgo_delivery_style_earnings_value'.tr,
                'foxgo_delivery_style_earnings_wallet'.tr,
                'foxgo_delivery_style_earnings_disbursement'.tr,
              ],
            ),

            _SectionCard(
              icon: Icons.support_agent_outlined,
              title: 'foxgo_delivery_style_nina_title'.tr,
              items: [
                'foxgo_delivery_style_nina_first'.tr,
                'foxgo_delivery_style_nina_evidence'.tr,
                'foxgo_delivery_style_nina_route'.tr,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color primary;

  const _HeroCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.route_outlined, color: primary, size: 32),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          'foxgo_delivery_style_title'.tr,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: primary),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          'foxgo_delivery_style_intro'.tr,
          style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: Get.isDarkMode ? null : [
          BoxShadow(color: Colors.grey[200]!, spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: primary, size: 24),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.check, color: primary, size: 18),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Text(item, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
          ]),
        )),
      ]),
    );
  }
}
