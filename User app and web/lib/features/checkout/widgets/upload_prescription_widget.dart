import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

import '../../../util/app_constants.dart';
import 'desktop_prescription_preview_dialog.dart';
import 'prescription_preview_widget.dart';
import 'upload_prescription_files_button_sheet_widget.dart';
part './desktop_prescription_tab_widget.dart';
part './desktop_upload_prescription_dialog.dart';

class UploadPrescriptionWidget extends StatelessWidget {
  final CheckoutController checkoutController;
  final int? storeId;
  final bool isPrescriptionRequired;
  final JustTheController tooltipController1;
  final JustTheController tooltipController2;
  const UploadPrescriptionWidget({super.key, required this.checkoutController, this.storeId, required this.isPrescriptionRequired, required this.tooltipController1, required this.tooltipController2});

  @override
  Widget build(BuildContext context) {
    return (storeId != null || Get.find<SplashController>().configModel!.moduleConfig!.module!.orderAttachment!)
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

          Row(children: [
            Text('upload_prescription'.tr, style: robotoMedium),
            Text(' ${'max_2mb'.tr}', style: robotoRegular.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            JustTheTooltip(
              backgroundColor: Colors.black87,
              controller: tooltipController1,
              preferredDirection: AxisDirection.right,
              tailLength: 14,
              tailBaseWidth: 20,
              content: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('prescription_tool_tip'.tr, style: robotoRegular.copyWith(color: Colors.white)),
              ),
              child: InkWell(
                onTap: () => tooltipController1.showTooltip(),
                child: const Icon(Icons.info_outline, size: 16),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: checkoutController.pickedPrescriptions.length + checkoutController.prescriptionUploadingCount
                  + ((checkoutController.pickedPrescriptions.length + checkoutController.prescriptionUploadingCount) < CheckoutController.maxPrescriptionFileCount ? 1 : 0),
              itemBuilder: (context, index) {
                int uploadingStartIndex = checkoutController.pickedPrescriptions.length;
                int addButtonIndex = checkoutController.pickedPrescriptions.length + checkoutController.prescriptionUploadingCount;

                if(index >= uploadingStartIndex && index < addButtonIndex) {
                  return Container(
                    margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                        strokeWidth: 1,
                        strokeCap: StrokeCap.butt,
                        dashPattern: const [5, 5],
                        padding: const EdgeInsets.all(0.5),
                        radius: const Radius.circular(Dimensions.radiusDefault),
                      ),
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: true,
                        child: Container(
                          height: 98, width: 98,
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                XFile? file = index == addButtonIndex ? null : checkoutController.pickedPrescriptions[index];
                if(index == addButtonIndex && addButtonIndex < CheckoutController.maxPrescriptionFileCount) {
                  return InkWell(
                    onTap: () {
                      if (ResponsiveHelper.isDesktop(context)){
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            child: _DesktopUploadPrescriptionDialog(checkoutController: checkoutController),
                          ),
                        );
                      } else if (GetPlatform.isIOS){
                        checkoutController.pickPrescriptionImage(isRemove: false, isCamera: false);
                      } else {
                        if(AuthHelper.isLoggedIn()) {
                          Get.bottomSheet(const UploadPrescriptionFilesButtonSheetWidget());
                        } else {
                          _onClickFunction();
                        }
                      }
                    },
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Theme.of(context).disabledColor,
                        strokeWidth: 1,
                        strokeCap: StrokeCap.butt,
                        dashPattern: const [5, 5],
                        padding: const EdgeInsets.all(0),
                        radius: const Radius.circular(Dimensions.radiusDefault),
                      ),
                      child: Container(
                        height: 98, width: 98, alignment: Alignment.center, decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                      child:  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.upload_file_rounded, color: Theme.of(context).disabledColor, size: 32),
                        Text('click_to_add'.tr, style: robotoRegular.copyWith(color: Colors.indigo, fontSize: Dimensions.fontSizeSmall), textAlign: TextAlign.center,),
                      ]),
                      ),
                    ),
                  );
                }
                return file != null ? Container(
                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 1,
                      strokeCap: StrokeCap.butt,
                      dashPattern: const [5, 5],
                      padding: const EdgeInsets.all(0),
                      radius: const Radius.circular(Dimensions.radiusDefault),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Stack(children: [
                        InkWell(
                          onTap: () {
                            if (ResponsiveHelper.isDesktop(context)) {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (_) => Dialog(
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  child: DesktopPrescriptionPreviewDialog(
                                    checkoutController: checkoutController,
                                    images: checkoutController.pickedPrescriptions,
                                    savedImageNames: checkoutController.pickedPrescriptionSavedImageNames,
                                    fromMediaLibraryFlags: checkoutController.pickedPrescriptionFromMediaLibrary,
                                    initialIndex: index,
                                    bAddMode: false,
                                  ),
                                ),
                              );
                            } else {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (BuildContext context) => PrescriptionPreviewWidget(
                                  checkoutController: checkoutController,
                                  images: checkoutController.pickedPrescriptions,
                                  savedImageNames: checkoutController.pickedPrescriptionSavedImageNames,
                                  fromMediaLibraryFlags: checkoutController.pickedPrescriptionFromMediaLibrary,
                                  initialIndex: index,
                                  bAddMode: false,
                                ),
                              );
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            child: GetPlatform.isWeb ? Image.network(
                              file.path.startsWith('http') ? '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeComponent(file.path)}' : file.path,
                              width: 98, height: 98, fit: BoxFit.cover,
                            ) : Image.file(
                              File(file.path), width: 98, height: 98, fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 5, top: 5,
                          child: InkWell(
                            onTap: () => checkoutController.removePrescriptionImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ) : const SizedBox();
              },
            ),
          ),

      isPrescriptionRequired ? SizedBox(height: Dimensions.paddingSizeDefault) : const SizedBox(),

          isPrescriptionRequired ? Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: ResponsiveHelper.isDesktop(context) ? Theme.of(context).colorScheme.error.withValues(alpha: 0.05) : Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Text(
              'prescription_required_for_this_order_because_you_have_a_item_that_need_prescription'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ) : const SizedBox(height: Dimensions.paddingSizeLarge),
        ]) : const SizedBox();
  }

  Future<void> _onClickFunction() async {
    CheckoutController checkoutController = Get.find<CheckoutController>();
    final int currentCount = checkoutController.pickedPrescriptions.length;
    final int remainingSlots = CheckoutController.maxPrescriptionFileCount - currentCount;
    final int maxSelectable = remainingSlots > CheckoutController.maxPrescriptionSaveBatchCount
        ? CheckoutController.maxPrescriptionSaveBatchCount
        : remainingSlots;
    List<XFile>? xFiles = await checkoutController.pickMultiplePrescriptionImages(maxSelectable: maxSelectable);
    if (xFiles != null && xFiles.isNotEmpty) {

        Get.bottomSheet(
          PrescriptionPreviewWidget(
            checkoutController: checkoutController, savedImageNames: List<String?>.filled(xFiles.length, null),
            fromMediaLibraryFlags: List<bool>.filled(xFiles.length, false),
            images: xFiles, initialIndex: 0, bAddMode: true,
          ),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
    }
  }
}
