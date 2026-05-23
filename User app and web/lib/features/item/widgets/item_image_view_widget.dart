import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/discount_tag.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as web_youtube;
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/item/widgets/item_media_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class ItemImageViewWidget extends StatelessWidget {
  final Item? item;
  final bool isCampaign;
  ItemImageViewWidget({super.key, required this.item, this.isCampaign = false});

  static void stopAllVideo() {
    _ItemMediaVideoViewState.disposeAll();
  }

  static void stopFullscreenVideos() {
    _ItemMediaVideoViewState.disposeFullscreenOnly();
  }

  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final List<String> mediaList = _getMediaList(item!, isCampaign: isCampaign);

    double? discount = Get.find<ItemController>().item!.discount;
    String? discountType = Get.find<ItemController>().item!.discountType;

    return GetBuilder<ItemController>(builder: (itemController) {
      final bool isDesktop = ResponsiveHelper.isDesktop(context);
      final int currentIndex = mediaList.isNotEmpty && itemController.imageSliderIndex < mediaList.length ? itemController.imageSliderIndex : 0;
      final String? currentMedia = mediaList.isNotEmpty ? mediaList[currentIndex] : null;
      final bool letYoutubeHandleTap = isDesktop && currentMedia != null && _isYoutubeUrl(currentMedia);

      return InkWell(
        onTap: isCampaign || letYoutubeHandleTap ? null : () {
          if(!isCampaign) {
            if(isDesktop) {
              Get.dialog(ItemMediaDialog(item: item!, isCampaign: isCampaign, initialIndex: currentIndex));
            } else {
              if (currentMedia != null && !_isVideoMedia(currentMedia)) {
                Navigator.of(context).pushNamed(
                  RouteHelper.getItemImagesRoute(item!, initialIndex: currentIndex),
                  arguments: ItemImageViewWidget(item: item, isCampaign: isCampaign),
                );
              }
            }
          }
        },
        child: Stack(children: [
          SizedBox(
            height: ResponsiveHelper.isDesktop(context)? 350 : MediaQuery.of(context).size.width * 0.7,
            child: mediaList.isNotEmpty ? PageView.builder(
              controller: _controller,
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final String mediaUrl = mediaList[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isVideoMedia(mediaUrl) ? _ItemMediaVideoView(
                    mediaUrl: mediaUrl,
                    thumbnailUrl: _thumbnailUrl(item!, mediaUrl, mediaList),
                    isDesktop: ResponsiveHelper.isDesktop(context),
                    onFullscreenTap: _isYoutubeUrl(mediaUrl) ? null : () {
                      if (ResponsiveHelper.isDesktop(context)) {
                        Get.dialog(ItemMediaDialog(item: item!, isCampaign: isCampaign, initialIndex: index));
                      } else if (ResponsiveHelper.isMobile(context)) {
                        Get.toNamed(
                          RouteHelper.getItemImagesRoute(item!, initialIndex: index),
                          arguments: ItemImageViewWidget(item: item, isCampaign: isCampaign),
                        );
                      }
                    },

                    // onFullscreenTap: _isYoutubeUrl(mediaUrl) ? null : () => Get.dialog(ItemMediaDialog(item: item!, isCampaign: isCampaign)),
                  ) : CustomImage(image: mediaUrl, height: 200, width: MediaQuery.of(context).size.width),
                );
              },
              onPageChanged: (index) {
                itemController.setImageSliderIndex(index);
              },
            ) : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomImage(image: '', height: 200, width: MediaQuery.of(context).size.width),
            ),
          ),

          DiscountTag(discount: discount, discountType: discountType, fromTop: 20),

          mediaList.length > 1 ? Positioned(
            left: 10,
            top: (ResponsiveHelper.isDesktop(context)? 350 : MediaQuery.of(context).size.width * 0.7) / 2 - 15,
            child: InkWell(
              onTap: () {
                final int newIndex = itemController.imageSliderIndex == 0 ? mediaList.length - 1 : itemController.imageSliderIndex - 1;
                _controller.animateToPage(newIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                itemController.setImageSliderIndex(newIndex);
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
            ),
          ) : const SizedBox(),

          mediaList.length > 1 ? Positioned(
            right: 5,
            top: (ResponsiveHelper.isDesktop(context)? 350 : MediaQuery.of(context).size.width * 0.7) / 2 - 15,
            child: InkWell(
              onTap: () {
                final int newIndex = itemController.imageSliderIndex == mediaList.length - 1 ? 0 : itemController.imageSliderIndex + 1;
                _controller.animateToPage(newIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                itemController.setImageSliderIndex(newIndex);
              },
              child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
            ),
          ) : const SizedBox(),

          Positioned(
            right: 10, top: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(50),
              ),
              child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                return InkWell(
                  onTap: () {
                    if(AuthHelper.isLoggedIn()){
                      if(favouriteController.wishItemIdList.contains(item!.id)) {
                        favouriteController.removeFromFavouriteList(item!.id, false);
                      }else {
                        favouriteController.addToFavouriteList(item, null, false);
                      }
                    }else {
                      showCustomSnackBar('you_are_not_logged_in'.tr);
                    }
                  },
                  child: Icon(
                    favouriteController.wishItemIdList.contains(item!.id) ? Icons.favorite : Icons.favorite_border, size: 25,
                    color: favouriteController.wishItemIdList.contains(item!.id) ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
                  ),
                );
              }),
            ),
          ),

          mediaList.isNotEmpty ? Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: _indicators(context, itemController, mediaList.cast<String?>()),
            ),
          ) : SizedBox.shrink(),

        ]),
      );
    });
  }

  Widget _indicators(BuildContext context, ItemController itemController, List<String?> imageList) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: 2),
          child: Text('${itemController.imageSliderIndex + 1}/${imageList.length}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),),
        ),
      ),
    );
  }

  bool _isVideoMedia(String url) {
    final String lowerUrl = url.toLowerCase();
    return _isYoutubeUrl(lowerUrl) || lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.m4v') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.mkv');
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
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

  String _thumbnailUrl(Item item, String mediaUrl, List<String> mediaList) {
    if (item.videoThumbnailUrl?.isNotEmpty == true && _isVideoMedia(mediaUrl)) {
      return item.videoThumbnailUrl!;
    }
    if (_isYoutubeUrl(mediaUrl)) {
      final String? videoId = YoutubePlayer.convertUrlToId(mediaUrl);
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }
    if (!_isVideoMedia(mediaUrl)) {
      return mediaUrl;
    }
    for (final String media in mediaList) {
      if (media.isNotEmpty && !_isVideoMedia(media)) {
        return media;
      }
    }
    return item.imageFullUrl ?? '';
  }
}

class ItemMediaPreviewWidget extends StatelessWidget {
  final String mediaUrl;
  final String thumbnailUrl;
  final double width;
  final double height;
  final bool isDesktop;
  final bool showPlayer;
  final bool isFullscreen;
  final VoidCallback? onFullscreenTap;
  const ItemMediaPreviewWidget({
    super.key,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.isDesktop,
    this.showPlayer = true,
    this.isFullscreen = false,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    final String lowerUrl = mediaUrl.toLowerCase();
    final bool isYoutubeVideo = lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be') || lowerUrl.contains('youtube.com/embed');
    final bool isVideo = isYoutubeVideo || lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || lowerUrl.endsWith('.m4v') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.mkv');
    final double playIconSize = width.isFinite ? width * 0.4 : 54;

    if (!isVideo || !showPlayer) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(image: isVideo ? thumbnailUrl : mediaUrl, width: width, height: height, fit: BoxFit.cover),
          ),
          if(isVideo) Container(
            width: width, height: height,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Icon(Icons.play_circle_outline, color: Colors.white, size: playIconSize),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: _ItemMediaVideoView(
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        isDesktop: isDesktop,
        isFullscreen: isFullscreen,
        onFullscreenTap: onFullscreenTap,
      ),
    );
  }
}

class _ItemMediaVideoView extends StatefulWidget {
  final String mediaUrl;
  final String thumbnailUrl;
  final bool isDesktop;
  final bool isFullscreen;
  final VoidCallback? onFullscreenTap;
  const _ItemMediaVideoView({required this.mediaUrl, required this.thumbnailUrl, required this.isDesktop, this.isFullscreen = false, this.onFullscreenTap});

  @override
  State<_ItemMediaVideoView> createState() => _ItemMediaVideoViewState();
}

class _ItemMediaVideoViewState extends State<_ItemMediaVideoView> {
  static _ItemMediaVideoViewState? _activeState;
  static final Set<_ItemMediaVideoViewState> _allStates = <_ItemMediaVideoViewState>{};
  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubeController;
  web_youtube.YoutubePlayerController? _webYoutubeController;
  bool _isYoutubeVideo = false;
  bool _hasError = false;
  bool _hideForPop = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _isFullscreen = widget.isFullscreen || (Get.isDialogOpen ?? false);
    _activeState = this;
    _allStates.add(this);
    _initializePlayer();
  }

  static void disposeAll() {
    for (final s in _allStates.toList()) {
      s._disposeAndHide();
    }
  }

  static void disposeFullscreenOnly() {
    for (final s in _allStates.toList()) {
      if (s._isFullscreen) {
        s._disposeAndHide();
      }
    }
  }

  void _disposeAndHide() {
    _disposePlayers();
    if (mounted) {
      setState(() {
        _hideForPop = true;
      });
    }
  }

  void _disposePlayers() {
    _youtubeController?.dispose();
    _youtubeController = null;
    _webYoutubeController?.close();
    _webYoutubeController = null;
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  Future<void> _initializePlayer() async {
    final String url = widget.mediaUrl;
    final String? videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId != null && videoId.isNotEmpty) {
      _isYoutubeVideo = true;
      if (kIsWeb) {
        _webYoutubeController = web_youtube.YoutubePlayerController.fromVideoId(videoId: videoId, autoPlay: true,
          params: const web_youtube.YoutubePlayerParams(mute: true, showControls: true, showFullscreenButton: true,),
        );
      } else {
        _youtubeController = YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: true, mute: true));
      }
      if (mounted) {
        setState(() {});
      }
      return;
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.play();
      _videoPlayerController!.addListener(_videoListener);
    } catch (_) {
      _hasError = true;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (_activeState == this) {
      _activeState = null;
    }
    _allStates.remove(this);
    _disposePlayers();
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      alignment: Alignment.center,
      child: _hasError ? _fallbackThumbnail() : _playerView(),
    );
  }

  Widget _playerView() {
    if (_hideForPop) {
      return _fallbackThumbnail();
    }
    if (_isYoutubeVideo) {
      if (kIsWeb && _webYoutubeController != null) {
        return web_youtube.YoutubePlayer(
          controller: _webYoutubeController!,
          aspectRatio: 16 / 9,
        );
      } else if (!kIsWeb && _youtubeController != null) {
        return YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          progressColors: const ProgressBarColors(
            playedColor: Colors.amber,
            handleColor: Colors.amberAccent,
          ),
        );
      }
    }
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return _nonYoutubePlayer();
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _nonYoutubePlayer() {
    final VideoPlayerController controller = _videoPlayerController!;
    final Duration position = controller.value.position;
    final Duration duration = controller.value.duration;

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio * (widget.isDesktop ? 1 : 1.3),
            child: VideoPlayer(controller),
          ),
        ),

        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white.withValues(alpha: 0.45),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        if (controller.value.isPlaying) {
                          await controller.pause();
                        } else {
                          await controller.play();
                        }
                      },
                      child: Icon(
                        controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onFullscreenTap != null)
                      InkWell(
                        onTap: widget.onFullscreenTap,
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _fallbackThumbnail() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.thumbnailUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: CustomImage(image: widget.thumbnailUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
          )
        else
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
        Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 54),
        ),
      ],
    );
  }
}
