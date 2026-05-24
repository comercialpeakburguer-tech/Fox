import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
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
    final Color inactiveColor = Theme.of(context).textTheme.bodyMedium!.color!.withValues(alpha: 0.62);
    final IconData icon = _foxIconData(selectedIcon, unSelectedIcon, title);

    return Expanded(
      child: InkWell(
        onTap: onTap as void Function()?,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 34,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.10) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 25,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Text(
            _foxTitle(title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),

        ]),
      ),
    );
  }

  IconData _foxIconData(String selectedIcon, String unSelectedIcon, String title) {
    final String value = '$selectedIcon $unSelectedIcon $title'.toLowerCase();

    if (selectedIcon == Images.homeSelect || value.contains('home') || value.contains('início') || value.contains('inicio')) {
      return isSelected ? Icons.home_rounded : Icons.home_outlined;
    }
    if (value.contains('search') || value.contains('buscar')) {
      return Icons.search_rounded;
    }
    if (selectedIcon == Images.orderSelect || value.contains('order') || value.contains('pedido') || value.contains('trips')) {
      return isSelected ? Icons.receipt_long_rounded : Icons.receipt_long_outlined;
    }
    if (selectedIcon == Images.menu || value.contains('menu') || value.contains('perfil') || value.contains('profile')) {
      return isSelected ? Icons.person_rounded : Icons.person_outline_rounded;
    }
    if (selectedIcon == Images.addressSelect || value.contains('address') || value.contains('endereço')) {
      return isSelected ? Icons.location_on_rounded : Icons.location_on_outlined;
    }
    if (selectedIcon == Images.favouriteSelect || value.contains('favourite') || value.contains('favorito')) {
      return isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded;
    }

    return Icons.circle_outlined;
  }

  String _foxTitle(String currentTitle) {
    final String value = currentTitle.toLowerCase();
    if(value.contains('home') || value.contains('início') || value.contains('inicio')) return 'Início';
    if(value.contains('search') || value.contains('buscar')) return 'Buscar';
    if(value.contains('order') || value.contains('pedido')) return 'Pedidos';
    if(value.contains('menu') || value.contains('profile') || value.contains('perfil')) return 'Perfil';
    return currentTitle;
  }
}
