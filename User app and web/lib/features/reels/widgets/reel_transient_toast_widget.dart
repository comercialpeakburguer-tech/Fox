import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/reels/controllers/reels_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

// Toast rendered inside the reel dialog's own Stack. Must be a later sibling
// than the reel pager so it composites above the HTML <video> platform view
// on Flutter web — any root overlay or Get.showSnackbar sits behind the
// video and stays invisible. Drive it via ReelsController.showTransientToast.
class ReelTransientToastWidget extends StatelessWidget {
  final double bottomOffset;
  const ReelTransientToastWidget({super.key, this.bottomOffset = 24});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: Dimensions.paddingSizeSmall,
      right: Dimensions.paddingSizeSmall,
      bottom: bottomOffset,
      child: IgnorePointer(
        child: GetBuilder<ReelsController>(
          id: ReelsController.transientToastGetId,
          builder: (ReelsController controller) {
            final String? message = controller.transientToastMessage;
            if(message == null || message.isEmpty) {
              return const SizedBox.shrink();
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _ToastPill(
                  message: message,
                  isError: controller.transientToastIsError,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToastPill extends StatelessWidget {
  final String message;
  final bool isError;
  const _ToastPill({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF334257),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isError ? Icons.cancel : Icons.check_circle,
              color: isError
                  ? const Color(0xffFF9090).withValues(alpha: 0.8)
                  : const Color(0xff039D55),
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Flexible(
              child: Text(
                message,
                style: robotoRegular.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
