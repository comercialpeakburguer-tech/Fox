import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressWidget extends StatelessWidget {
  final AddressModel? address;
  final bool fromAddress;
  final bool fromCheckout;
  final Function? onRemovePressed;
  final Function? onEditPressed;
  final Function? onTap;
  final bool isSelected;
  final bool fromDashBoard;
  const AddressWidget({super.key, required this.address, required this.fromAddress, this.onRemovePressed, this.onEditPressed,
    this.onTap, this.fromCheckout = false, this.isSelected = false, this.fromDashBoard = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: fromCheckout ? 0 : Dimensions.paddingSizeSmall),
      child: Container(
        decoration: fromDashBoard ? BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: isSelected ? 1 : 0),
        ) : fromCheckout ? const BoxDecoration() : BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha: 0.07), width: isSelected ? 1 : 1),
          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.065, blur: 16, offset: const Offset(0, 7)),
        ),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: fromDashBoard ? Dimensions.radiusDefault : fromCheckout ? 0 : 24,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeDefault),
            child: Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset(
                        address!.addressType == 'home' ? Images.homeIcon : address!.addressType == 'office' ? Images.workIcon : Images.otherIcon,
                        color: Theme.of(context).primaryColor, height: ResponsiveHelper.isDesktop(context) ? 26 : 22, width: ResponsiveHelper.isDesktop(context) ? 26 : 22,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Text(
                        address!.addressType!.tr,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: FoxGoDesign.graphite),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text(
                      address!.address!,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),

                fromAddress ? IconButton(
                  icon: Icon(Icons.edit_rounded, color: Theme.of(context).primaryColor, size: 23),
                  onPressed: onEditPressed as void Function()?,
                ) : const SizedBox(),

                fromAddress ? IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error, size: 23),
                  onPressed: onRemovePressed as void Function()?,
                ) : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}