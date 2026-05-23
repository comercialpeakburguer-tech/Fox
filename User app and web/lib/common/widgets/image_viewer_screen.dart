import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ImageViewerScreen extends StatelessWidget {
  final Item item;
  final bool isCampaign;
  final int initialIndex;
  const ImageViewerScreen({super.key, required this.item, this.isCampaign = false, this.initialIndex = 0});

  Future<void> _handleBack() async {
    ItemImageViewWidget.stopFullscreenVideos();
    await WidgetsBinding.instance.endOfFrame;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> mediaList = _getMediaList(item, isCampaign: isCampaign);
    final int safeInitialIndex = mediaList.isEmpty ? 0 : initialIndex.clamp(0, mediaList.length - 1);
    Get.find<ItemController>().setImageIndex(safeInitialIndex, false);
    final PageController pageController = PageController(initialPage: safeInitialIndex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: CustomAppBar(title: 'product_images'.tr, onBackPressed: _handleBack),
      body: GetBuilder<ItemController>(builder: (itemController) {

        return Column(children: [

          Expanded(child: Stack(children: [

            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(color: Theme.of(context).cardColor),
              itemCount: mediaList.length,
              pageController: pageController,
              builder: (BuildContext context, int index) {
                final String mediaUrl = mediaList[index];
                final bool isVideo = _isVideoMedia(mediaUrl);

                if (isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: ItemMediaPreviewWidget(
                      mediaUrl: mediaUrl,
                      thumbnailUrl: item.videoThumbnailUrl ?? item.imageFullUrl ?? '',
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      isDesktop: false,
                      isFullscreen: true,
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    heroAttributes: PhotoViewHeroAttributes(tag: index.toString()),
                  );
                }

                return PhotoViewGalleryPageOptions(
                  imageProvider: kIsWeb ? NetworkImage('${AppConstants.baseUrl}/image-proxy?url=$mediaUrl') : NetworkImage(mediaUrl),
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: index.toString()),
                );
              },
              loadingBuilder: (context, event) {
                final int? expectedTotalBytes = event?.expectedTotalBytes;
                final double? progress = (event != null && expectedTotalBytes != null && expectedTotalBytes > 0)
                    ? event.cumulativeBytesLoaded / expectedTotalBytes : null;

                return Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(value: progress)));
              },
              onPageChanged: (int index) => itemController.setImageIndex(index, true),
            ),

            itemController.imageIndex != 0 ? Positioned(
              left: 5, top: 0, bottom: 0,
              child: Container(
                alignment: Alignment.center,
                decoration:  BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 60), shape: BoxShape.circle),
                child: InkWell(
                  onTap: () {
                    if(itemController.imageIndex > 0) {
                      pageController.animateToPage(
                        itemController.imageIndex-1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: const Icon(Icons.chevron_left_outlined, size: 40),
                ),
              ),
            ) : const SizedBox(),

            itemController.imageIndex != mediaList.length-1 ? Positioned(
              right: 5, top: 0, bottom: 0,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Theme.of(context).disabledColor.withValues(alpha: 60), shape: BoxShape.circle),
                child: InkWell(
                  onTap: () {
                    if(itemController.imageIndex < mediaList.length - 1) {
                      pageController.animateToPage(
                        itemController.imageIndex+1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: const Icon(Icons.chevron_right_outlined, size: 40),
                ),
              ),
            ) : const SizedBox(),

          ])),

        ]);
      }),
    ));
  }

  bool _isVideoMedia(String url) {
    final String lowerUrl = url.toLowerCase();
    return _isYoutubeUrl(lowerUrl) || lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.m4v') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.mkv');
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be') || url.contains('youtube.com/embed');
  }

  List<String> _getMediaList(Item item, {bool isCampaign = false}) {
    final List<String> mediaList = [];
    final String? videoUrl = item.videoEmbedUrl?.isNotEmpty == true ? item.videoEmbedUrl
        : item.videoLink?.isNotEmpty == true ? item.videoLink
        : item.videoFullUrl?.isNotEmpty == true ? item.videoFullUrl
        : item.videoPreviewUrl?.isNotEmpty == true ? item.videoPreviewUrl
        : null;
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
}
