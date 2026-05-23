import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

class ProfileCardWidget extends StatelessWidget {
  final String image;
  final String title;
  final String data;
  const ProfileCardWidget({super.key, required this.data, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveHelper.isDesktop(context) ? 130 : 118,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08), width: 1),
        boxShadow: FoxGoDesign.premiumShadow(opacity: 0.065, blur: 16, offset: const Offset(0, 7)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(height: 44, width: 44, padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: FoxGoDesign.softRed, borderRadius: BorderRadius.circular(16)), child: Image.asset(image, height: 26, width: 26)),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(
          data, textDirection: TextDirection.ltr,
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault + 1, color: FoxGoDesign.graphite),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(title, style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor,
        )),
      ]),
    );
  }
}
