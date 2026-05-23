import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/widgets/web/widgets/arrow_icon_button.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/features/reels/domain/models/reel_model.dart';
import 'package:sixam_mart/features/reels/domain/repositories/reels_repository.dart';
import 'package:sixam_mart/features/reels/domain/services/reels_service.dart';
import 'package:sixam_mart/features/reels/widgets/reels_details_dialog_widget.dart';
import 'package:sixam_mart/features/reels/widgets/reels_shimmer_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class ReelsSectionWidget extends StatefulWidget {
  final String? title;
  final ValueChanged<ReelModel>? onReelTap;
  const ReelsSectionWidget({super.key, this.title, this.onReelTap});

  @override
  State<ReelsSectionWidget> createState() => _ReelsSectionWidgetState();
}

class _ReelsSectionWidgetState extends State<ReelsSectionWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackButton = false;
  bool _showForwardButton = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if(!_scrollController.hasClients) return;
    final bool back = _scrollController.position.pixels > 0;
    final bool forward = _scrollController.position.pixels < _scrollController.position.maxScrollExtent;
    if(back != _showBackButton || forward != _showForwardButton) {
      setState(() {
        _showBackButton = back;
        _showForwardButton = forward;
      });
    }
  }

  String _resolveTitle() {
    if(widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    final String? moduleType = Get.find<SplashController>().module?.moduleType?.toString();
    switch(moduleType) {
      case AppConstants.food:
        return 'trending_bites'.tr;
      case AppConstants.grocery:
        return 'fresh_finds'.tr;
      case AppConstants.ecommerce:
        return 'trending_now'.tr;
      case AppConstants.pharmacy:
        return 'health_highlights'.tr;
      case AppConstants.taxi:
        return 'quick_picks'.tr;
      default:
        return 'trending_bites'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!Get.isRegistered<ReelsController>()) {
      Get.lazyPut<ReelsController>(() => ReelsController(
        reelsServiceInterface: ReelsService(
          reelsRepositoryInterface: ReelsRepository(apiClient: Get.find<ApiClient>()),
        ),
      ));
    }

    return GetBuilder<ReelsController>(
      builder: (ReelsController reelsController) {
        if(reelsController.reelsList == null && reelsController.isLoading) {
          return const ReelsShimmerWidget();
        }

        final List<ReelModel> reels = reelsController.reelsList ?? <ReelModel>[];
        if(reels.isEmpty) {
          return const SizedBox.shrink();
        }

        final bool isDesktop = ResponsiveHelper.isDesktop(context);
        final double cardWidth = isDesktop ? 160 : 118;
        final double cardHeight = isDesktop ? 280 : 180;
        final String resolvedTitle = _resolveTitle();

        const int maxVisibleReels = 9;
        final bool showViewAll = reels.length > maxVisibleReels;
        final int reelItemCount = showViewAll ? maxVisibleReels : reels.length;
        final int itemCount = showViewAll ? reelItemCount + 1 : reelItemCount;

        if(isDesktop && _isFirstTime && itemCount > 5) {
          _showForwardButton = true;
          _isFirstTime = false;
        }

        void openDialog(int initialIndex) {
          reelsController.setCurrentIndex(initialIndex);
          Get.dialog(
            ReelsDetailsDialogWidget(
              reels: reels,
              initialIndex: initialIndex,
              title: resolvedTitle,
            ),
            barrierDismissible: true,
            barrierColor: Colors.black.withValues(alpha: 0.82),
            useSafeArea: false,
          );
        }

        final Widget reelsList = ListView.separated(
          controller: isDesktop ? _scrollController : null,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          itemCount: itemCount,
          separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
          itemBuilder: (BuildContext context, int index) {
            if(showViewAll && index == reelItemCount) {
              return SizedBox(
                width: cardWidth,
                child: _ViewAllCardWidget(
                  onTap: () => openDialog(0),
                ),
              );
            }

            return SizedBox(
              width: cardWidth,
              child: _ReelCardWidget(
                reel: reels[index],
                isActive: index == reelsController.currentIndex,
                isDesktop: isDesktop,
                onTap: () {
                  reelsController.setCurrentIndex(index);
                  if(widget.onReelTap != null) {
                    widget.onReelTap!(reels[index]);
                    return;
                  }
                  openDialog(index);
                },
              ),
            );
          },
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  children: <Widget>[
                    const CustomAssetImageWidget(Images.reelTitleIcon, height: 24, width: 24),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text(resolvedTitle, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              SizedBox(
                height: cardHeight,
                child: isDesktop
                    ? Stack(
                        children: <Widget>[
                          reelsList,
                          if(_showBackButton)
                            Positioned(
                              left: Dimensions.paddingSizeSmall,
                              top: (cardHeight - 40) / 2,
                              child: ArrowIconButton(
                                isRight: false,
                                onTap: () => _scrollController.animateTo(
                                  _scrollController.offset - (cardWidth * 3),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          if(_showForwardButton)
                            Positioned(
                              right: Dimensions.paddingSizeSmall,
                              top: (cardHeight - 40) / 2,
                              child: ArrowIconButton(
                                onTap: () => _scrollController.animateTo(
                                  _scrollController.offset + (cardWidth * 3),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                        ],
                      )
                    : reelsList,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViewAllCardWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllCardWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                offset: const Offset(0, 10),
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'view_all'.tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReelCardWidget extends StatelessWidget {
  final ReelModel reel;
  final bool isActive;
  final bool isDesktop;
  final VoidCallback onTap;
  const _ReelCardWidget({required this.reel, required this.isActive, required this.onTap, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  offset: const Offset(0, 10),
                  blurRadius: 20,
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned.fill(
                    child: reel.resolvedThumbnailUrl.isNotEmpty
                        ? CustomImage(image: reel.resolvedThumbnailUrl, fit: BoxFit.cover)
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Theme.of(context).primaryColor.withValues(alpha: 0.22),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.72),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if(!isDesktop) Positioned(
                    top: Dimensions.paddingSizeSmall,
                    left: Dimensions.paddingSizeSmall,
                    child: Container(
                      height: 30,
                      width: 30,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
                      ),
                      child: ClipOval(
                        child: CustomImage(image: reel.resolvedLogoUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    left: Dimensions.paddingSizeSmall,
                    right: Dimensions.paddingSizeSmall,
                    bottom: Dimensions.paddingSizeSmall,
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                height: 22,
                                width: 22,
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1),
                                ),
                                child: ClipOval(
                                  child: CustomImage(image: reel.resolvedLogoUrl, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            reel.resolvedSubtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: robotoBold.copyWith(
                                              color: Colors.white,
                                              fontSize: Dimensions.fontSizeExtraSmall,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                        if(reel.verifiedSeller == 1) ...<Widget>[
                                          const SizedBox(width: 4),
                                          Image.asset(Images.verifiedBadge, width: 12, height: 12),
                                        ],
                                      ],
                                    ),
                                    if(reel.resolvedDescription.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Text(
                                          reel.resolvedDescription,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: robotoRegular.copyWith(
                                            color: Colors.white.withValues(alpha: 0.88),
                                            fontSize: Dimensions.fontSizeOverSmall,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            reel.resolvedTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoMedium.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeExtraSmall,
                              height: 1.15,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
