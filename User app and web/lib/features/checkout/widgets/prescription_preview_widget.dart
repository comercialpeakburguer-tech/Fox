import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import '../../../helper/responsive_helper.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/checkout_controller.dart';
import 'upload_prescription_files_button_sheet_widget.dart';

class PrescriptionPreviewWidget extends StatefulWidget {
  const PrescriptionPreviewWidget({
    super.key,
    required this.checkoutController,
    required this.images,
    this.savedImageNames,
    this.fromMediaLibraryFlags,
    required this.initialIndex,
    required this.bAddMode,
  });

  final CheckoutController checkoutController;
  final List<XFile> images;
  final List<String?>? savedImageNames;
  final List<bool>? fromMediaLibraryFlags;
  final int initialIndex;
  final bool bAddMode;

  @override
  State<PrescriptionPreviewWidget> createState() => _PrescriptionPreviewWidgetState();
}

class _PrescriptionPreviewWidgetState extends State<PrescriptionPreviewWidget> {
  late PageController pageController;
  late int currentIndex;
  bool isAutoSaved = AuthHelper.isLoggedIn() ? true : false;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
        color: Theme.of(context).cardColor,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
          child: Container(height: 4, width: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), color: Theme.of(context).disabledColor),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Header with title and upload again button
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('prescription_preview'.tr, style: robotoMedium),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                if(Get.context != null){
                  if (ResponsiveHelper.isDesktop(Get.context!) || GetPlatform.isIOS) {
                    final int maxSelectable = (CheckoutController.maxPrescriptionFileCount - (widget.images.length - 1)) > CheckoutController.maxPrescriptionSaveBatchCount
                        ? CheckoutController.maxPrescriptionSaveBatchCount
                        : (CheckoutController.maxPrescriptionFileCount - (widget.images.length - 1));
                    widget.checkoutController.pickMultiplePrescriptionImages(maxSelectable: maxSelectable).then((xFiles) {
                      if (xFiles != null && xFiles.isNotEmpty) {
                        List<XFile> updatedImages = List.from(widget.images);
                        List<String?> updatedSavedImageNames = List<String?>.from(widget.savedImageNames ?? List<String?>.filled(widget.images.length, null));
                        List<bool> updatedFromMediaLibraryFlags = List<bool>.from(widget.fromMediaLibraryFlags ?? List<bool>.filled(widget.images.length, false));
                        updatedImages.removeAt(currentIndex);
                        updatedSavedImageNames.removeAt(currentIndex);
                        updatedFromMediaLibraryFlags.removeAt(currentIndex);
                        updatedImages.insertAll(currentIndex, xFiles);
                        updatedSavedImageNames.insertAll(currentIndex, List<String?>.filled(xFiles.length, null));
                        updatedFromMediaLibraryFlags.insertAll(currentIndex, List<bool>.filled(xFiles.length, false));

                        if (!widget.bAddMode) {
                          widget.checkoutController.updatePrescriptionImages(
                            updatedImages,
                            savedImageNames: updatedSavedImageNames,
                            mediaLibraryFlags: updatedFromMediaLibraryFlags,
                          );
                        }

                        Get.bottomSheet(
                          PrescriptionPreviewWidget(
                            checkoutController: widget.checkoutController, initialIndex: currentIndex, bAddMode: widget.bAddMode,
                            images: !widget.bAddMode ? widget.checkoutController.pickedPrescriptions : updatedImages,
                            savedImageNames: !widget.bAddMode ? widget.checkoutController.pickedPrescriptionSavedImageNames : updatedSavedImageNames,
                            fromMediaLibraryFlags: !widget.bAddMode ? widget.checkoutController.pickedPrescriptionFromMediaLibrary : updatedFromMediaLibraryFlags,
                          ),
                          isScrollControlled: true, backgroundColor: Colors.transparent,
                        );
                      }
                    });
                  } else {
                    Get.bottomSheet(
                      UploadPrescriptionFilesButtonSheetWidget(
                        isReplacement: true,
                        replaceIndex: currentIndex,
                        existingImages: widget.images,
                        existingSavedImageNames: widget.savedImageNames,
                        existingFromMediaLibraryFlags: widget.fromMediaLibraryFlags,
                        bAddMode: widget.bAddMode,
                      ),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Row(children: [
                Text('upload_again'.tr, style: robotoMedium.copyWith( fontSize: Dimensions.fontSizeSmall)),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Icon(Icons.camera_alt, size: 16, color: Theme.of(context).primaryColor),
              ]),
            ),
          ),
        ]),

        SizedBox(height: Dimensions.paddingSizeSmall),

        // Image Slider Custom View
        Flexible(child: Container(
            constraints: BoxConstraints(minHeight: context.mediaQuerySize.height * 0.2, maxHeight: context.mediaQuerySize.height * 0.5),
            color: Theme.of(context).cardColor,
            child: Stack(children: [
              PageView.builder(
                controller: pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  String filePath = widget.images[index].path;
                  return GetPlatform.isWeb ? ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Image.network(filePath, fit: BoxFit.contain, width: context.width),
                  ) : ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Image.file(File(filePath), fit: BoxFit.contain),
                  );
                },
              ),

              // Left/Right Navigation Arrows
              if (widget.images.length > 1)
                Positioned.fill(
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    InkWell(
                      onTap: () {
                        if (currentIndex > 0) {pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);}
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: currentIndex > 0 ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_left, color: currentIndex > 0 ? Colors.black54 : Colors.transparent, size: 18),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (currentIndex < widget.images.length - 1) {
                          pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: currentIndex < widget.images.length - 1 ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right, color: currentIndex < widget.images.length - 1 ? Colors.black54 : Colors.transparent, size: 18),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
        ),

        // Dot Indicators
        if (widget.images.length > 1) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4), width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6,
              decoration: BoxDecoration(
                color: currentIndex == index ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            );
          })),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],

        SizedBox(height: Dimensions.paddingSizeSmall),

        // Footer with checkbox and upload button
        Row(children: [
          AuthHelper.isLoggedIn() ? Row(children: [
            Checkbox(
              value: isAutoSaved,
              onChanged: (value) {
                setState(() {
                  isAutoSaved = value ?? false;
                });
              },
            ),
            Text('enable_auto_saved'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
          ]) : const SizedBox(),
          Spacer(),
          InkWell(
            onTap: () {
              if (widget.bAddMode) {
                widget.checkoutController.addPrescriptionImages(
                  widget.images,
                  isAutoSaved: isAutoSaved,
                  savedImageNames: widget.savedImageNames,
                  mediaLibraryFlags: widget.fromMediaLibraryFlags,
                );
              } else {
                widget.checkoutController.updatePrescriptionImages(
                  widget.images,
                  isAutoSaved: isAutoSaved,
                  savedImageNames: widget.savedImageNames,
                  mediaLibraryFlags: widget.fromMediaLibraryFlags,
                );
              }
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              child: Text('upload'.tr, style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
            ),
          ),
        ]),
      ]),
    );
  }
}
