import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/util/dimensions.dart';

class ReelsShimmerWidget extends StatelessWidget {
  const ReelsShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(
              children: <Widget>[
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 180,
            child: Shimmer(
              duration: const Duration(seconds: 2),
              enabled: true,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                itemCount: 4,
                separatorBuilder: (BuildContext context, int index) => const SizedBox(width: Dimensions.paddingSizeSmall),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width: 118,
                    decoration: BoxDecoration(
                      color: Theme.of(context).shadowColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
