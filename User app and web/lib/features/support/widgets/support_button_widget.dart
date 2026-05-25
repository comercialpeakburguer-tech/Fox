import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

class SupportButtonWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? info;
  final Color color;
  final Function onTap;
  const SupportButtonWidget({super.key, required this.icon, required this.title, required this.info, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap as void Function()?,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07)),
          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.065, blur: 16, offset: const Offset(0, 7)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [

          Container(
            height: 46, width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(info!, style: robotoMedium.copyWith(color: Theme.of(context).hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),

        ]),
      ),
    );
  }
}
