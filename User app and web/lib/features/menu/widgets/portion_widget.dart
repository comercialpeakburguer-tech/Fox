import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';

class PortionWidget extends StatelessWidget {
  final String icon;
  final String title;
  final bool hideDivider;
  final String route;
  final String? suffix;
  final Function()? onTap;
  const PortionWidget({super.key, required this.icon, required this.title, required this.route, this.hideDivider = false, this.suffix, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap ?? () => Get.toNamed(route),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FoxGoDesign.softRed,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset(icon, height: 18, width: 18, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Expanded(
              child: Text(
                title,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            suffix != null ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
              child: Text(suffix!, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor), textDirection: TextDirection.ltr),
            ) : Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor, size: 22),
          ]),
        ),
        hideDivider ? const SizedBox() : Divider(height: 1, color: Theme.of(context).primaryColor.withValues(alpha: 0.06)),
      ]),
    );
  }
}
