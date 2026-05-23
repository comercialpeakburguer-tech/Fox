part of './upload_prescription_widget.dart';

class _DesktopUploadPrescriptionDialog extends StatefulWidget {
  final CheckoutController checkoutController;
  const _DesktopUploadPrescriptionDialog({required this.checkoutController});

  @override
  State<_DesktopUploadPrescriptionDialog> createState() => _DesktopUploadPrescriptionDialogState();
}

class _DesktopUploadPrescriptionDialogState extends State<_DesktopUploadPrescriptionDialog> {
  int _selectedTab = 0;
  final List<XFile> _selectedFiles = [];
  final List<int> _selectedIndexes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        _loadSavedPrescriptionImages();
      }
    });
  }

  Future<void> _loadSavedPrescriptionImages({bool reload = true}) async {
    final Future<void> loadFuture = widget.checkoutController.getSavedPrescriptionImages(reload: reload);
    if(mounted) {
      setState(() {});
    }
    await loadFuture;
    if(mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(builder: (checkoutController) {
      final List<SavedPrescriptionModel>? savedPrescriptions = checkoutController.savedPrescriptions;
      final bool hasSavedPrescriptions = savedPrescriptions != null && savedPrescriptions.isNotEmpty;
      return Container(
        width: 720,
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('upload_prescription'.tr, style: robotoBold.copyWith(fontSize: 18)),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(height: 36, width: 36,
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.close, color: Theme.of(context).disabledColor),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          AuthHelper.isLoggedIn() ? Row(children: [
            _DesktopPrescriptionTabWidget(title: 'upload_files'.tr, isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
            const SizedBox(width: Dimensions.paddingSizeLarge),
            _DesktopPrescriptionTabWidget(title: 'media_library'.tr, isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
            const Spacer(),
            if (_selectedTab == 1 && hasSavedPrescriptions)
              InkWell(
                onTap: () {
                  Get.dialog(ConfirmationDialog(
                    icon: Images.warning,
                    description: 'Are you sure you want to clear all saved prescriptions?',
                    onYesPressed: () async {
                      Get.back();
                      final bool isDeleted = await checkoutController.clearAllSavedPrescriptionImages();
                      if (isDeleted) {
                        for (int i = checkoutController.pickedPrescriptions.length - 1; i >= 0; i--) {
                          final bool isFromMediaLibrary = i < checkoutController.pickedPrescriptionFromMediaLibrary.length
                              ? checkoutController.pickedPrescriptionFromMediaLibrary[i]
                              : false;
                          if (isFromMediaLibrary) {
                            checkoutController.removePrescriptionImage(i);
                          }
                        }
                        _selectedIndexes.clear();
                      }
                      if(mounted) {
                        setState(() {});
                      }
                    },
                  ));
                },
                child: Text(checkoutController.isSavedPrescriptionDeleting ? 'loading'.tr : 'clear_all'.tr,
                  style: robotoMedium.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeDefault),
                ),
              ),
          ]) : const SizedBox(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
            decoration: BoxDecoration(
              color: _selectedTab == 0 ? Theme.of(context).disabledColor.withValues(alpha: 0.06) :
              (hasSavedPrescriptions ? Theme.of(context).cardColor : Theme.of(context).disabledColor.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            ),
            child: _selectedTab == 0 ? _buildUploadFilesView(context) : _buildMediaLibraryView(context),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: _canUpload() ? () async {
                  final NavigatorState navigator = Navigator.of(context);
                  if (_selectedTab == 0) {
                    navigator.pop();
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: DesktopPrescriptionPreviewDialog(
                          checkoutController: widget.checkoutController,
                          images: _selectedFiles,
                          savedImageNames: List<String?>.filled(_selectedFiles.length, null),
                          initialIndex: 0,
                          bAddMode: true,
                        ),
                      ),
                    );
                  } else {
                    List<XFile> imagesToUpload = await widget.checkoutController.getSelectedSavedPrescriptionFiles(_selectedIndexes);
                    List<String> selectedSavedImageNames = widget.checkoutController.getSelectedSavedPrescriptionNames(_selectedIndexes);
                    if (imagesToUpload.isEmpty) {
                      return;
                    }
                    await widget.checkoutController.addPrescriptionImages(imagesToUpload, savedImageNames: selectedSavedImageNames,
                      mediaLibraryFlags: List<bool>.filled(imagesToUpload.length, true),
                    );
                    if(mounted) {
                      navigator.pop();
                    }
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: _canUpload() ? 1 : 0.4),
                  disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                ),
                child: Text('upload'.tr, style: robotoBold.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildUploadFilesView(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.07) ,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: InkWell(
          onTap: () async {
            final int remainingSlots = CheckoutController.maxPrescriptionFileCount - widget.checkoutController.pickedPrescriptions.length;
            final int maxSelectable = remainingSlots > CheckoutController.maxPrescriptionSaveBatchCount
                ? CheckoutController.maxPrescriptionSaveBatchCount : remainingSlots;
            List<XFile>? xFiles = await widget.checkoutController.pickMultiplePrescriptionImages(maxSelectable: maxSelectable);
            if (xFiles != null && xFiles.isNotEmpty) {
              if(!context.mounted) {
                return;
              }
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: DesktopPrescriptionPreviewDialog(checkoutController: widget.checkoutController, images: xFiles,
                    savedImageNames: List<String?>.filled(xFiles.length, null), initialIndex: 0, bAddMode: true,
                  ),
                ),
              );
            }
          },
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5), strokeWidth: 1,
              dashPattern: const [5, 5], radius: const Radius.circular(Dimensions.radiusDefault), padding: const EdgeInsets.all(0),
            ),
            child: Container(width: 240, height: 120, alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(Images.image, height: 28, width: 28, color: Theme.of(context).disabledColor),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(_selectedFiles.isEmpty ? 'click_to_upload'.tr : '${_selectedFiles.length} ${'upload_files'.tr.toLowerCase()}', style: robotoRegular.copyWith(color: Colors.indigo)),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeDefault),
      Text('jpg_jpeg_png_image_size_max_2_mb'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
    ]);
  }

  Widget _buildMediaLibraryView(BuildContext context) {
    final CheckoutController checkoutController = widget.checkoutController;
    final List<SavedPrescriptionModel>? savedPrescriptions = checkoutController.savedPrescriptions;
    final bool hasSavedPrescriptions = savedPrescriptions != null && savedPrescriptions.isNotEmpty;
    final int remainingSlots = CheckoutController.maxPrescriptionFileCount - widget.checkoutController.pickedPrescriptions.length;
    final int maxSelectable = remainingSlots > CheckoutController.maxPrescriptionSaveBatchCount
        ? CheckoutController.maxPrescriptionSaveBatchCount : remainingSlots;
    final bool isLimitReached = _selectedIndexes.length >= maxSelectable;

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (checkoutController.isSavedPrescriptionLoading)
        const SizedBox(height: 140, width: double.infinity,
          child: Center(child: CircularProgressIndicator()),
        )
      else
        SizedBox(height: hasSavedPrescriptions ? 260 : 140, width: double.infinity,
          child: hasSavedPrescriptions ? GridView.builder(
          itemCount: savedPrescriptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5,
            crossAxisSpacing: Dimensions.paddingSizeDefault, mainAxisSpacing: Dimensions.paddingSizeDefault, childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final SavedPrescriptionModel item = savedPrescriptions[index];
            final bool isSelected = _selectedIndexes.contains(index);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIndexes.remove(index);
                  } else if (_selectedIndexes.length < maxSelectable) {
                    _selectedIndexes.add(index);
                  } else {
                    showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
                  }
                });
              },
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: CustomImage(image: item.imageFullUrl ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(top: 5, left: 5,
                  child: isSelected ? Container(padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ) : Container(height: 18, width: 18,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                  ),
                ),
              ]),
            );
          },
        ) : Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.image, size: 42, color: Theme.of(context).disabledColor),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text('no_data_available'.tr,
              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
            ),
          ]),
        ),
        ),
      const SizedBox(height: Dimensions.paddingSizeSmall),
      if (isLimitReached)
        Text('you_have_reached_your_maximum_limit'.tr,
          style: robotoRegular.copyWith(color: Colors.red, fontSize: Dimensions.fontSizeSmall),
        ),
    ]);
  }

  bool _canUpload() {
    return _selectedTab == 0 ? false : _selectedIndexes.isNotEmpty;
  }
}
