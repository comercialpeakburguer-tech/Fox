import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ItemMediaDialog extends StatefulWidget {
  final Item item;
  final bool isCampaign;
  final int initialIndex;
  const ItemMediaDialog({super.key, required this.item, this.isCampaign = false, this.initialIndex = 0});

  @override
  State<ItemMediaDialog> createState() => _ItemMediaDialogState();
}

class _ItemMediaDialogState extends State<ItemMediaDialog> {
  late List<String> _mediaList;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _mediaList = _getMediaList(widget.item, isCampaign: widget.isCampaign);
    final int safeInitialIndex = _mediaList.isEmpty ? 0 : widget.initialIndex.clamp(0, _mediaList.length - 1);
    _pageController = PageController(initialPage: safeInitialIndex);
    Get.find<ItemController>().setImageIndex(safeInitialIndex, false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    ItemImageViewWidget.stopFullscreenVideos();
    await WidgetsBinding.instance.endOfFrame;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleClose();
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: 1170,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D21),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3136),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GetBuilder<ItemController>(builder: (itemController) {
                        String title = 'product_images'.tr;
                        if(_mediaList.isNotEmpty && itemController.imageIndex < _mediaList.length) {
                          String url = _mediaList[itemController.imageIndex];
                          if(_isVideoMedia(url)) {
                            title = url.split('/').last.split('?').first;
                          }
                        }
                        return Text(
                          title,
                          style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _handleClose,
                      hoverColor: Colors.white10,
                    ),
                  ],
                ),
              ),

            // Gallery
            Expanded(
              child: GetBuilder<ItemController>(builder: (itemController) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PhotoViewGallery.builder(
                      scrollPhysics: const BouncingScrollPhysics(),
                      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                      itemCount: _mediaList.length,
                      pageController: _pageController,
                      builder: (BuildContext context, int index) {
                        final String mediaUrl = _mediaList[index];
                        final bool isVideo = _isVideoMedia(mediaUrl);

                        if (isVideo) {
                          return PhotoViewGalleryPageOptions.customChild(
                            child: ItemMediaPreviewWidget(
                              mediaUrl: mediaUrl,
                              thumbnailUrl: widget.item.videoThumbnailUrl ?? widget.item.imageFullUrl ?? '',
                              width: double.infinity,
                              height: double.infinity,
                              isDesktop: true,
                              isFullscreen: true,
                            ),
                            initialScale: PhotoViewComputedScale.contained,
                          );
                        }

                        return PhotoViewGalleryPageOptions(
                          imageProvider: kIsWeb ? NetworkImage('${AppConstants.baseUrl}/image-proxy?url=$mediaUrl') : NetworkImage(mediaUrl),
                          initialScale: PhotoViewComputedScale.contained,
                        );
                      },
                      onPageChanged: (int index) => itemController.setImageIndex(index, true),
                    ),

                    // Left Arrow
                    if (itemController.imageIndex != 0)
                      Positioned(
                        left: 20, top: 0, bottom: 0,
                        child: Center(
                          child: PointerInterceptor(
                            intercepting: kIsWeb,
                            child: InkWell(
                              onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              child: Container(
                                height: 44, width: 44,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                                child: const Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Right Arrow
                    if (itemController.imageIndex != _mediaList.length - 1)
                      Positioned(
                        right: 20, top: 0, bottom: 0,
                        child: Center(
                          child: PointerInterceptor(
                            intercepting: kIsWeb,
                            child: InkWell(
                              onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              child: Container(
                                height: 44, width: 44,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                                child: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    ));
  }

  bool _isVideoMedia(String url) {
    final String lowerUrl = url.toLowerCase();
    return url.contains('youtube.com') || url.contains('youtu.be') || url.contains('youtube.com/embed') ||
        lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.m4v') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.mkv');
  }

  List<String> _getMediaList(Item item, {bool isCampaign = false}) {
    final List<String> mediaList = [];
    final String? videoUrl = _getVideoUrl(item);
    if (videoUrl != null && videoUrl.isNotEmpty) {
      mediaList.add(videoUrl);
    }
    if (item.imageFullUrl?.isNotEmpty == true) {
      mediaList.add(item.imageFullUrl!);
    }
    if (!isCampaign && item.imagesFullUrl != null && item.imagesFullUrl!.isNotEmpty) {
      mediaList.addAll(item.imagesFullUrl!.where((url) => url.isNotEmpty));
    }
    return mediaList;
  }

  String? _getVideoUrl(Item item) {
    if (item.videoEmbedUrl?.isNotEmpty == true) {
      return item.videoEmbedUrl;
    }
    if (item.videoLink?.isNotEmpty == true) {
      return item.videoLink;
    }
    if (item.videoFullUrl?.isNotEmpty == true) {
      return item.videoFullUrl;
    }
    if (item.videoPreviewUrl?.isNotEmpty == true) {
      return item.videoPreviewUrl;
    }
    return null;
  }
}
