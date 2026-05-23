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
    final Color inactiveColor = Theme.of(context).hintColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(FoxGoDesign.radiusMd),
          onTap: onTap as void Function()?,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.09) : Colors.transparent,
              borderRadius: BorderRadius.circular(FoxGoDesign.radiusMd),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: isSelected ? 31 : 25,
                width: isSelected ? 42 : 25,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.24), blurRadius: 12, offset: const Offset(0, 5))] : null,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  isSelected ? selectedIcon : unSelectedIcon, height: isSelected ? 19 : 20, width: isSelected ? 19 : 20,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (isSelected ? robotoBold : robotoRegular).copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10.8,
                  height: 1.05,
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}
