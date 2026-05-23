import 'package:flutter/cupertino.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';

class ProfileButtonWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final bool? isButtonActive;
  final Function onTap;
  final Color? color;
  final String? iconImage;
  final String? languageName;
  const ProfileButtonWidget({super.key, this.icon, required this.title, required this.onTap, this.isButtonActive, this.color, this.iconImage, this.languageName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap as void Function()?,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: isButtonActive != null ? 12 : languageName != null ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.07), width: 1),
          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.055, blur: 14, offset: const Offset(0, 6)),
        ),
        child: Row(children: [
          Container(height: 42, width: 42, decoration: BoxDecoration(color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: iconImage != null ? Image.asset(iconImage!, height: 18, width: 25) : Icon(icon, size: 22, color: color ?? Theme.of(context).primaryColor)),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite))),

          isButtonActive != null ? Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              value: isButtonActive!,
              activeTrackColor: Theme.of(context).primaryColor,
              onChanged: (bool? value) => onTap(),
              inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
          ) : languageName != null ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            child: Row(
              children: [
                Text(languageName!, style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Icon(Icons.keyboard_arrow_down, size: 15),
              ],
            ),
          ) : const SizedBox(),
        ]),
      ),
    );
  }
}
