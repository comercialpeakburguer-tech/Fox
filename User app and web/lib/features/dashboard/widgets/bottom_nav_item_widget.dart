import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';

class BottomNavItemWidget extends StatelessWidget {
  final String selectedIcon;
  final String unSelectedIcon;
  final String title;
  final Function? onTap;
  final bool isSelected;
  const BottomNavItemWidget({super.key, this.onTap, this.isSelected = false, required this.title, required this.selectedIcon, required this.unSelectedIcon});

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).primaryColor;
    const Color inactiveColor = FoxGoDesign.textMuted;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap as void Function()?,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? FoxGoDesign.softRed : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: isSelected ? 36 : 28,
                width: isSelected ? 48 : 28,
                decoration: BoxDecoration(
                  gradient: isSelected ? FoxGoDesign.redGradient() : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected ? FoxGoDesign.premiumShadow(opacity: 0.18, blur: 16, offset: const Offset(0, 7)) : null,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  isSelected ? selectedIcon : unSelectedIcon,
                  height: isSelected ? 19 : 20,
                  width: isSelected ? 19 : 20,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: (isSelected ? robotoBold : robotoMedium).copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10.5,
                  height: 1,
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}
