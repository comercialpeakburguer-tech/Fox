import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoPickupFlowCardWidget extends StatelessWidget {
  final VoidCallback? onPickupCodeTap;
  final OrderModel order;
  final bool parcel;

  const FoxGoPickupFlowCardWidget({
    super.key,
    this.onPickupCodeTap,
    required this.order,
    required this.parcel,
  });

  bool get _isPickupStage {
    final status = order.orderStatus?.toLowerCase();
    return status == 'accepted'
        || status == 'confirmed'
        || status == 'processing'
        || status == AppConstants.handover;
  }

  bool get _isHandover {
    return order.orderStatus?.toLowerCase() == AppConstants.handover;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPickupStage) {
      return const SizedBox();
    }

    final Color primary = Theme.of(context).primaryColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color hintColor = Theme.of(context).hintColor;

    final String pickupName = (order.storeName ?? '').trim();
    final String pickupAddress = ((order.storeAddress ?? '').trim().isNotEmpty
        ? order.storeAddress
        : order.deliveryAddress?.address) ?? '';
    final String phone = (order.storePhone ?? '').trim();
    final int detailsCount = order.detailsCount ?? 0;
    final double? earning = order.foxgoDriverEarningAmount;
    final String instruction = (order.deliveryInstruction ?? '').trim();

    final String title = _isHandover
        ? (parcel ? 'foxgo_pickup_collect_card_title'.tr : 'foxgo_pickup_card_title'.tr)
        : (parcel ? 'foxgo_pickup_on_the_way_collect'.tr : 'foxgo_pickup_on_the_way_store'.tr);

    final String subtitle = _isHandover
        ? (parcel ? 'foxgo_pickup_collect_check_order'.tr : 'foxgo_pickup_check_order'.tr)
        : 'foxgo_pickup_route_instruction'.tr;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeDefault,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Icon(
              _isHandover ? Icons.inventory_2_outlined : Icons.store_mall_directory_outlined,
              color: primary,
              size: 23,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: robotoRegular.copyWith(
                  color: hintColor,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: Dimensions.paddingSizeDefault),

        if (pickupName.isNotEmpty)
          _InfoLine(
            icon: Icons.storefront_outlined,
            label: 'foxgo_pickup_origin_label'.tr,
            value: pickupName,
          ),

        if (pickupAddress.trim().isNotEmpty)
          _InfoLine(
            icon: Icons.location_on_outlined,
            label: 'foxgo_pickup_address_label'.tr,
            value: pickupAddress.trim(),
          ),

        if (phone.isNotEmpty)
          _InfoLine(
            icon: Icons.phone_outlined,
            label: 'foxgo_pickup_phone_label'.tr,
            value: phone,
          ),

        _InfoLine(
          icon: Icons.shopping_bag_outlined,
          label: 'foxgo_pickup_items_label'.tr,
          value: detailsCount > 0
              ? '$detailsCount ${detailsCount == 1 ? 'item'.tr : 'items'.tr}'
              : 'foxgo_pickup_no_items'.tr,
        ),

        if (earning != null && earning > 0)
          _InfoLine(
            icon: Icons.payments_outlined,
            label: 'foxgo_pickup_earning_label'.tr,
            value: PriceConverterHelper.convertPrice(earning),
            highlight: true,
          ),

        if (instruction.isNotEmpty)
          _InfoLine(
            icon: Icons.notes_outlined,
            label: 'delivery_instruction'.tr,
            value: instruction,
          ),

        if (_isHandover) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('foxgo_pickup_enter_code_button'),
              onPressed: onPickupCodeTap,
              icon: const Icon(Icons.pin_outlined, size: 20),
              label: Text(
                'foxgo_pickup_enter_code_button'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    final Color hintColor = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: highlight ? primary : hintColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              label,
              style: robotoRegular.copyWith(
                color: hintColor,
                fontSize: Dimensions.fontSizeExtraSmall,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: (highlight ? robotoBold : robotoMedium).copyWith(
                color: highlight ? primary : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
