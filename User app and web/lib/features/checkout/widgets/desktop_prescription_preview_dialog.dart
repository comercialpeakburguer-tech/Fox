import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/helper/auth_helper.dart';

import '../../../helper/responsive_helper.dart';
import '../../../util/app_constants.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/checkout_controller.dart';

class DesktopPrescriptionPreviewDialog extends StatefulWidget {
  final CheckoutController checkoutController;
  final List<XFile> images;
  final List<String?>? savedImageNames;
  final List<bool>? fromMediaLibraryFlags;
  final int initialIndex;
  final bool bAddMode;

  const DesktopPrescriptionPreviewDialog({
    super.key,
    required this.checkoutController,
    required this.images,
    required this.savedImageNames,
    this.fromMediaLibraryFlags,
    required this.initialIndex,
    required this.bAddMode,
  });

  @override
  State<DesktopPrescriptionPreviewDialog> createState() => _DesktopPrescriptionPreviewDialogState();
}

class _DesktopPrescriptionPreviewDialogState extends State<DesktopPrescriptionPreviewDialog> {
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
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width * 0.6,
      height: context.height * 0.8,
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('prescription_preview'.tr, style: robotoBold.copyWith(fontSize: 20)),
          const Spacer(),
          AuthHelper.isLoggedIn() ? Row(children: [
            Checkbox(
              value: isAutoSaved,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                setState(() {
                  isAutoSaved = value ?? false;
                });
              },
            ),
            Text('enable_auto_saved'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
          ]) : const SizedBox(),
          const SizedBox(width: Dimensions.paddingSizeLarge),
          InkWell(
            onTap: () async {
              final int maxSelectable = (CheckoutController.maxPrescriptionFileCount - (widget.images.length - 1)) > CheckoutController.maxPrescriptionSaveBatchCount
                  ? CheckoutController.maxPrescriptionSaveBatchCount
                  : (CheckoutController.maxPrescriptionFileCount - (widget.images.length - 1));
              List<XFile>? xFiles = await widget.checkoutController.pickMultiplePrescriptionImages(maxSelectable: maxSelectable);
              if (xFiles == null || xFiles.isEmpty || !context.mounted) {
                return;
              }
              List<XFile> updatedImages = List<XFile>.from(widget.images);
              List<String?> updatedSavedImageNames = List<String?>.from(widget.savedImageNames ?? List<String?>.filled(widget.images.length, null));
              List<bool> updatedFromMediaLibraryFlags = List<bool>.from(widget.fromMediaLibraryFlags ?? List<bool>.filled(widget.images.length, false));
              updatedImages.removeAt(currentIndex);
              updatedSavedImageNames.removeAt(currentIndex);
              updatedFromMediaLibraryFlags.removeAt(currentIndex);
              updatedImages.insertAll(currentIndex, xFiles);
              updatedSavedImageNames.insertAll(currentIndex, List<String?>.filled(xFiles.length, null));
              updatedFromMediaLibraryFlags.insertAll(currentIndex, List<bool>.filled(xFiles.length, false));
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: DesktopPrescriptionPreviewDialog(
                    checkoutController: widget.checkoutController,
                    images: updatedImages,
                    savedImageNames: updatedSavedImageNames,
                    fromMediaLibraryFlags: updatedFromMediaLibraryFlags,
                    initialIndex: currentIndex,
                    bAddMode: widget.bAddMode,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Row(children: [
                Text('upload_again'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Icon(Icons.camera_alt, size: 18, color: Theme.of(context).primaryColor),
              ]),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeLarge),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(height: 40, width: 40,
              decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.close, color: Theme.of(context).disabledColor),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Text(_imageName(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Stack(children: [
          SizedBox(
            height: context.height * 0.47,
            child: PageView.builder(
              controller: pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final String filePath = widget.images[index].path;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: ResponsiveHelper.isDesktop(context) ? SizedBox( height: context.height * 0.2,
                    child: Image.network(
                      filePath.startsWith('http') ? '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeComponent(filePath)}' : filePath,
                      fit: BoxFit.contain, width: double.infinity, height: context.height * 0.2,
                    ),
                  ) : Image.file(
                    File(filePath), fit: BoxFit.contain, width: double.infinity, height: context.height * 0.5,
                  ),
                );
              },
            ),
          ),
          if (widget.images.length > 1)
            Positioned.fill(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _DesktopPreviewArrowButton(
                  icon: Icons.chevron_left,
                  isEnabled: currentIndex > 0,
                  onTap: () {
                    if (currentIndex > 0) {
                      pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                ),
                _DesktopPreviewArrowButton(
                  icon: Icons.chevron_right,
                  isEnabled: currentIndex < widget.images.length - 1,
                  onTap: () {
                    if (currentIndex < widget.images.length - 1) {
                      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                ),
              ]),
            ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(children: [
          Padding(
            padding: const EdgeInsets.only(left: 80),
            child: Text('${currentIndex + 1}/${widget.images.length}', style: robotoBold.copyWith(fontSize: 18)),
          ),
          const Spacer(),
          SizedBox(width: 190,
            child: ElevatedButton(
              onPressed: () async {
                if (widget.bAddMode) {
                  await widget.checkoutController.addPrescriptionImages(
                    widget.images,
                    isAutoSaved: isAutoSaved,
                    savedImageNames: widget.savedImageNames,
                    mediaLibraryFlags: widget.fromMediaLibraryFlags,
                  );
                } else {
                  await widget.checkoutController.updatePrescriptionImages(
                    widget.images,
                    isAutoSaved: isAutoSaved,
                    savedImageNames: widget.savedImageNames,
                    mediaLibraryFlags: widget.fromMediaLibraryFlags,
                  );
                }
                if(context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              ),
              child: Text('upload'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
            ),
          ),
          const SizedBox(width: 80),
        ]),
      ]),
    );
  }

  String _imageName() {
    final String path = widget.images[currentIndex].path;
    if (path.contains('/')) {
      return path.split('/').last;
    }
    return path;
  }
}

class _DesktopPreviewArrowButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DesktopPreviewArrowButton({required this.icon, required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Container(height: 56, width: 56,
        decoration: BoxDecoration(
          color: isEnabled ? Theme.of(context).cardColor : Theme.of(context).disabledColor.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          boxShadow: isEnabled ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: Icon(icon, color: isEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor, size: 34),
      ),
    );
  }
}
