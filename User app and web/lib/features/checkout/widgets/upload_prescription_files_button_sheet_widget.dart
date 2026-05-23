import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/checkout/widgets/prescription_preview_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class UploadPrescriptionFilesButtonSheetWidget extends StatelessWidget {
  final bool isReplacement;
  final int replaceIndex;
  final List<XFile>? existingImages;
  final List<String?>? existingSavedImageNames;
  final List<bool>? existingFromMediaLibraryFlags;
  final bool bAddMode;

  const UploadPrescriptionFilesButtonSheetWidget({
    super.key,
    this.isReplacement = false,
    this.replaceIndex = -1,
    this.existingImages,
    this.existingSavedImageNames,
    this.existingFromMediaLibraryFlags,
    this.bAddMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        color: Theme.of(context).cardColor,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 4, width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(children: [
          // Upload files card
          Expanded(child: InkWell(
            onTap: () async {
              Navigator.pop(context);
              CheckoutController checkoutController = Get.find<CheckoutController>();
              final int currentCount = isReplacement && existingImages != null ? existingImages!.length - 1 : checkoutController.pickedPrescriptions.length;
              final int remainingSlots = CheckoutController.maxPrescriptionFileCount - currentCount;
              final int maxSelectable = remainingSlots > CheckoutController.maxPrescriptionSaveBatchCount
                  ? CheckoutController.maxPrescriptionSaveBatchCount
                  : remainingSlots;
              List<XFile>? xFiles = await checkoutController.pickMultiplePrescriptionImages(maxSelectable: maxSelectable);
              if (xFiles != null && xFiles.isNotEmpty) {
                if (isReplacement && existingImages != null) {
                  List<XFile> updatedImages = List.from(existingImages!);
                  List<String?> updatedSavedImageNames = List<String?>.from(existingSavedImageNames ?? List<String?>.filled(existingImages!.length, null));
                  List<bool> updatedFromMediaLibraryFlags = List<bool>.from(existingFromMediaLibraryFlags ?? List<bool>.filled(existingImages!.length, false));
                  updatedImages.removeAt(replaceIndex);
                  updatedSavedImageNames.removeAt(replaceIndex);
                  updatedFromMediaLibraryFlags.removeAt(replaceIndex);
                  updatedImages.insertAll(replaceIndex, xFiles);
                  updatedSavedImageNames.insertAll(replaceIndex, List<String?>.filled(xFiles.length, null));
                  updatedFromMediaLibraryFlags.insertAll(replaceIndex, List<bool>.filled(xFiles.length, false));

                  if (!bAddMode) {
                    checkoutController.updatePrescriptionImages(
                      updatedImages,
                      savedImageNames: updatedSavedImageNames,
                      mediaLibraryFlags: updatedFromMediaLibraryFlags,
                    );
                  }

                  Get.bottomSheet(
                    PrescriptionPreviewWidget(
                      checkoutController: checkoutController,
                      images: !bAddMode ? checkoutController.pickedPrescriptions : updatedImages,
                      savedImageNames: !bAddMode ? checkoutController.pickedPrescriptionSavedImageNames : updatedSavedImageNames,
                      fromMediaLibraryFlags: !bAddMode ? checkoutController.pickedPrescriptionFromMediaLibrary : updatedFromMediaLibraryFlags,
                      initialIndex: replaceIndex, bAddMode: bAddMode,
                    ),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                } else {
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
            },
            child: Container(
              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge * 2),
                  ),
                  child: Icon(Icons.download, color: Colors.green, size: 26),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('upload_files'.tr, textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ]),
            ),
          )),
          // Media Library card
          if(AuthHelper.isLoggedIn())
            Expanded( child: InkWell(
            onTap: () {
              CheckoutController checkoutController = Get.find<CheckoutController>();
              List<int> selectedIndexes = [];
              final int currentCount = isReplacement && existingImages != null ? existingImages!.length - 1 : checkoutController.pickedPrescriptions.length;
              final int remainingSlots = CheckoutController.maxPrescriptionFileCount - currentCount;
              final int maxLimit = remainingSlots > CheckoutController.maxPrescriptionSaveBatchCount
                  ? CheckoutController.maxPrescriptionSaveBatchCount : remainingSlots;

              Navigator.pop(context);
              checkoutController.getSavedPrescriptionImages(reload: true);
              Get.bottomSheet(
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isLimitReached = selectedIndexes.length >= maxLimit;

                    return Container(
                      width: double.infinity,
                      height: context.height * 0.8,
                      padding: const EdgeInsets.symmetric( horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical( top: Radius.circular( Dimensions.radiusExtraLarge)),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Column( mainAxisSize: MainAxisSize.min, children: [
                        Container( height: 4, width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular( Dimensions.radiusDefault),
                            color: checkoutController.savedPrescriptions == null || checkoutController.savedPrescriptions!.isEmpty ?
                            Theme.of(context).disabledColor.withValues(alpha: 0.3) : Theme.of(context).cardColor,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close_sharp, color: Theme.of(context).disabledColor, size: 22),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        // Header Row
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(
                            'saved_prescription'.tr,
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                          ),
                          const Spacer(),

                          InkWell(
                            onTap: () {
                              Get.dialog(ConfirmationDialog(
                                icon: Images.warning,
                                description: 'are_you_sure_to_clear_all_saved_prescription'.tr,
                                onYesPressed: () async {
                                  Get.back();
                                  final bool isDeleted = await checkoutController.clearAllSavedPrescriptionImages();
                                  if (isDeleted) {
                                    for (int i = checkoutController.pickedPrescriptions.length - 1; i >= 0; i--) {
                                      final bool isFromMediaLibrary = i < checkoutController.pickedPrescriptionFromMediaLibrary.length
                                          ? checkoutController.pickedPrescriptionFromMediaLibrary[i] : false;
                                      if (isFromMediaLibrary) {
                                        checkoutController.removePrescriptionImage(i);
                                      }
                                    }
                                    selectedIndexes.clear();
                                    setState(() {});
                                  }
                                },
                              ));
                            },
                            child: Text(
                              checkoutController.isSavedPrescriptionDeleting ? 'loading'.tr : 'clear_all'.tr,
                              style: robotoMedium.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeDefault),
                            ),
                          )
                        ]),
                        const SizedBox( height: Dimensions.paddingSizeDefault),

                        Expanded(child: GetBuilder<CheckoutController>(
                          builder: (checkoutController) {
                            final List<SavedPrescriptionModel>? savedPrescriptions = checkoutController.savedPrescriptions;

                            if (checkoutController.isSavedPrescriptionLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (checkoutController.savedPrescriptionErrorMessage != null && (savedPrescriptions == null || savedPrescriptions.isEmpty)) {
                              return Center(child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                child: Text(
                                  checkoutController.savedPrescriptionErrorMessage!,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
                                  textAlign: TextAlign.center,
                                ),
                              ));
                            }

                            if (savedPrescriptions == null || savedPrescriptions.isEmpty) {
                              return Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(
                                  'you_havent_saved_any_media_yet'.tr,
                                  style: robotoMedium.copyWith( fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).disabledColor),
                                  textAlign: TextAlign.center,
                                ),
                              ]);
                            }

                            return GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, crossAxisSpacing: Dimensions.paddingSizeSmall, mainAxisSpacing: Dimensions.paddingSizeSmall,
                              ),
                              itemCount: savedPrescriptions.length,
                              itemBuilder: (context, index) {
                                final SavedPrescriptionModel
                                savedPrescription = savedPrescriptions[index];
                                final bool isSelected = selectedIndexes.contains(index);

                                return InkWell(
                                  onTap: () {
                                    if (isSelected) {
                                      selectedIndexes.remove(index);
                                    } else if (selectedIndexes.length < maxLimit) {
                                      selectedIndexes.add(index);
                                    }
                                    setState(() {});
                                  },
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      child: CustomImage(
                                        image: savedPrescription.imageFullUrl ?? '',
                                        fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(top: 5, left: 5,
                                        child: Container(
                                          padding:const EdgeInsets.all(2),
                                          decoration:const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                          child: const Icon( Icons.check, color: Colors.white, size: 14),
                                        ),
                                      )
                                    else
                                      Positioned(top: 5, left: 5,
                                        child: Container(height: 18, width: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                        ),
                                      ),
                                  ]),
                                );
                              },
                            );
                          },
                        )),
                        const SizedBox( height: Dimensions.paddingSizeSmall),
                        if (isLimitReached)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            child: Text(
                              'you_have_reached_your_maximum_limit'.tr,
                              style: robotoRegular.copyWith( color: Colors.red, fontSize: Dimensions.fontSizeSmall),
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedIndexes.isNotEmpty ? () async {
                              final NavigatorState navigator = Navigator.of(context);
                              List<XFile> imagesToUpload = await checkoutController.getSelectedSavedPrescriptionFiles(selectedIndexes);
                              List<String> selectedSavedImageNames = checkoutController.getSelectedSavedPrescriptionNames(selectedIndexes);
                              if (imagesToUpload.isEmpty) {return;}
                              if (isReplacement && existingImages != null) {
                                List<XFile> updatedImages = List.from(existingImages!);
                                List<String?> updatedSavedImageNames = List<String?>.from(existingSavedImageNames ?? List<String?>.filled(existingImages!.length, null));
                                List<bool> updatedFromMediaLibraryFlags = List<bool>.from(existingFromMediaLibraryFlags ?? List<bool>.filled(existingImages!.length, false));
                                updatedImages.removeAt(replaceIndex );
                                updatedSavedImageNames.removeAt(replaceIndex);
                                updatedFromMediaLibraryFlags.removeAt(replaceIndex);
                                updatedImages.insertAll(replaceIndex, imagesToUpload);
                                updatedSavedImageNames.insertAll(replaceIndex, selectedSavedImageNames);
                                updatedFromMediaLibraryFlags.insertAll(replaceIndex, List<bool>.filled(imagesToUpload.length, true));

                                await checkoutController.updatePrescriptionImages(
                                  updatedImages,
                                  savedImageNames: updatedSavedImageNames,
                                  mediaLibraryFlags: updatedFromMediaLibraryFlags,
                                );
                              } else {
                                await checkoutController.addPrescriptionImages(
                                  imagesToUpload,
                                  savedImageNames: selectedSavedImageNames,
                                  mediaLibraryFlags: List<bool>.filled(imagesToUpload.length, true),
                                );
                              }
                              navigator.pop();
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                            ),
                            child: Text( 'upload'.tr,
                              style: robotoBold.copyWith( color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                            ),
                          ),
                        ),
                        const SizedBox( height: Dimensions.paddingSizeExtraSmall),
                      ]),
                    );
                  },
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric( vertical: Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge * 2),
                  ),
                  child: Icon(Icons.image, color: Colors.green, size: 26),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('media_library'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: Dimensions.paddingSizeLarge),
      ]),
    );
  }
}
