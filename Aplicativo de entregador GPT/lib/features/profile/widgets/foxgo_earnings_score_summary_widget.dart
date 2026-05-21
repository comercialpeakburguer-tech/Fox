import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoEarningsScoreSummaryWidget extends StatelessWidget {
  final int completedOrders;
  final bool isOnline;
  final bool earningsEnabled;
  final bool disbursementEnabled;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onWithdrawTap;
  final VoidCallback? onDisbursementTap;

  const FoxGoEarningsScoreSummaryWidget({
    super.key,
    required this.completedOrders,
    required this.isOnline,
    required this.earningsEnabled,
    required this.disbursementEnabled,
    this.onEarningsTap,
    this.onWithdrawTap,
    this.onDisbursementTap,
  });

  int get _score {
    int value = 70;
    if (isOnline) value += 5;
    if (completedOrders > 0) value += completedOrders > 20 ? 20 : completedOrders;
    if (value > 100) return 100;
    return value;
  }

  String get _scoreLabel {
    if (_score >= 90) return 'foxgo_score_excellent'.tr;
    if (_score >= 80) return 'foxgo_score_good'.tr;
    return 'foxgo_score_building'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color hintColor = Theme.of(context).hintColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: primary, size: 25),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('foxgo_earnings_score_title'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 3),
              Text(
                'foxgo_earnings_score_subtitle'.tr,
                style: robotoRegular.copyWith(color: hintColor, fontSize: Dimensions.fontSizeSmall),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.done_all_rounded,
              title: 'foxgo_completed_deliveries'.tr,
              value: '$completedOrders',
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: _MetricCard(
              icon: Icons.star_rounded,
              title: 'foxgo_score_title'.tr,
              value: '$_score/100',
              subtitle: _scoreLabel,
            ),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        Row(children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.payments_outlined,
              title: 'foxgo_earnings_area'.tr,
              value: earningsEnabled ? 'foxgo_available'.tr : 'foxgo_unavailable'.tr,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: _MetricCard(
              icon: Icons.sync_alt_rounded,
              title: 'foxgo_disbursement_area'.tr,
              value: disbursementEnabled ? 'foxgo_active'.tr : 'foxgo_processing'.tr,
            ),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Text('foxgo_score_tips_title'.tr, style: robotoBold),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        _TipLine(text: 'foxgo_score_tip_accept_fast'.tr),
        _TipLine(text: 'foxgo_score_tip_finish_orders'.tr),
        _TipLine(text: 'foxgo_score_tip_avoid_timeout'.tr),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        Row(children: [
          Expanded(
            child: _ActionButton(
              text: 'my_earning'.tr,
              icon: Icons.bar_chart_rounded,
              onTap: earningsEnabled ? onEarningsTap : null,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: _ActionButton(
              text: 'withdraw'.tr,
              icon: Icons.account_balance_outlined,
              onTap: earningsEnabled ? onWithdrawTap : null,
            ),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        SizedBox(
          width: double.infinity,
          child: _ActionButton(
            text: 'disbursement'.tr,
            icon: Icons.receipt_long_outlined,
            onTap: disbursementEnabled ? onDisbursementTap : null,
          ),
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      minHeight: 104,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: primary, size: 22),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ]),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;

  const _TipLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.10)
              : Theme.of(context).disabledColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? Theme.of(context).primaryColor.withValues(alpha: 0.18)
                : Theme.of(context).disabledColor.withValues(alpha: 0.18),
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            icon,
            size: 19,
            color: enabled ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: robotoBold.copyWith(
                color: enabled ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}
