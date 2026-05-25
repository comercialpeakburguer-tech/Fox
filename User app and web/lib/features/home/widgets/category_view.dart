import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/widgets/category_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();

    return GetBuilder<SplashController>(builder: (splashController) {
      bool isPharmacy = splashController.module != null && splashController.module!.moduleType.toString() == 'pharmacy';
      bool isFood = splashController.module != null && splashController.module!.moduleType.toString() == 'food';

        return GetBuilder<CategoryController>(builder: (categoryController) {
          return (categoryController.categoryList != null && categoryController.categoryList!.isEmpty) ? const SizedBox() : isPharmacy ? PharmacyCategoryView(categoryController: categoryController) : isFood ? FoodCategoryView(categoryController: categoryController) : Column(
            children: [
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 146,
                    child: categoryController.categoryList != null ? ListView.builder(
                      controller: scrollController,
                      itemCount: categoryController.categoryList!.length > 15 ? 15 : categoryController.categoryList!.length,
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
                              categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                              slug: categoryController.categoryList![index].slug??'',
                            )),
                            child: Container(
                              width: 82,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, spreadRadius: 0, offset: const Offset(0, 6))],
                              ),
                              child: Column(children: [
                                Container(
                                  height: 54, width: 54,
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? 0 : Dimensions.paddingSizeExtraSmall,
                                    right: Dimensions.paddingSizeExtraSmall,
                                  ),
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CustomImage(
                                        image: '${categoryController.categoryList![index].imageFullUrl}',
                                        height: 54, width: 54, fit: BoxFit.cover,
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                Padding(
                                  padding: EdgeInsets.only(right: index == 0 ? Dimensions.paddingSizeExtraSmall : 0),
                                  child: Text(
                                    categoryController.categoryList![index].name!,
                                    style: robotoMedium.copyWith(fontSize: 11.5, height: 1.15),
                                    maxLines: Get.find<LocalizationController>().isLtr ? 2 : 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                  ),
                                ),

                              ]),
                            ),
                          ),
                        );
                      },
                    ) : CategoryShimmer(categoryController: categoryController),
                  ),
                ),

                  ResponsiveHelper.isMobile(context) ? const SizedBox() : categoryController.categoryList != null ? Column(
                    children: [
                      InkWell(
                        onTap: (){
                          showDialog(context: context, builder: (con) => Dialog(child: SizedBox(height: 550, width: 600, child: CategoryPopUp(
                            categoryController: categoryController,
                          ))));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                          child: Container(
                            height: 74, width: 74,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            child: Text('view_all'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: Dimensions.paddingSizeDefault, fontWeight: FontWeight.w700, color: Theme.of(context).cardColor)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10,)
                    ],
                  ): CategoryAllShimmer(categoryController: categoryController)
                ],
              ),

            ],
          );
        });
      }
    );
  }
}

class PharmacyCategoryView extends StatelessWidget {
  final CategoryController categoryController;
  const PharmacyCategoryView({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 160,
        child: categoryController.categoryList != null ? ListView.builder(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          itemCount: categoryController.categoryList!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault, right: index == categoryController.categoryList!.length - 1 ? Dimensions.paddingSizeDefault : 0),
              child: InkWell(
                onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
                  categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                  slug: categoryController.categoryList![index].slug??'',
                )),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                child: Container(
                  width: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 6))],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        Theme.of(context).cardColor.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Column(children: [

                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomImage(
                        image: '${categoryController.categoryList![index].imageFullUrl}',
                        height: 60, width: double.infinity, fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Expanded(child: Text(
                      categoryController.categoryList![index].name!,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
                      maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    )),
                  ]),
                ),
              ),
            );
          },
        ) : CategoryShimmer(categoryController: categoryController),
      ),
    ]);
  }
}

class FoodCategoryView extends StatelessWidget {
  final CategoryController categoryController;
  const FoodCategoryView({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 160,
          child: categoryController.categoryList != null ? ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
            itemCount: categoryController.categoryList!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
                child: InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
                    categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                    slug: categoryController.categoryList![index].slug??'',
                  )),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: Container(
                    width: 82,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, spreadRadius: 0, offset: const Offset(0, 6))],
                    ),
                    child: Column(children: [

                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CustomImage(
                          image: '${categoryController.categoryList![index].imageFullUrl}',
                          height: 60, width: double.infinity, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Expanded(child: Text(
                        categoryController.categoryList![index].name!,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
                        maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      )),
                    ]),
                  ),
                ),
              );
            },
          ) : CategoryShimmer(categoryController: categoryController),
        ),
      ]),

    ]);
  }
}

class CategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const CategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        itemCount: 14,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            child: Shimmer(
              duration: const Duration(seconds: 2),
              enabled: categoryController.categoryList == null,
              child: Column(children: [
                Container(
                  height: 62, width: 74,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                const SizedBox(height: 5),
                Container(height: 10, width: 50, color: Colors.grey[300]),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class CategoryAllShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const CategoryAllShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          enabled: categoryController.categoryList == null,
          child: Column(children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            const SizedBox(height: 5),
            Container(height: 10, width: 50, color: Colors.grey[300]),
          ]),
        ),
      ),
    );
  }
}

