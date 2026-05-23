import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap as void Function()?,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: isSelected ? 28 : 25,
                width: isSelected ? 36 : 25,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  isSelected ? selectedIcon : unSelectedIcon, height: 21, width: 21,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (isSelected ? robotoMedium : robotoRegular).copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 11.5,
                ),
              ),

            ]),
          ),
        ),
      ),
    );
  }
}
