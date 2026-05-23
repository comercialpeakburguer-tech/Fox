import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
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
      bool isPharmacy = splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.pharmacy;
      bool isFood = splashController.module != null && splashController.module!.moduleType.toString() == AppConstants.food;

      return GetBuilder<CategoryController>(builder: (categoryController) {
        return (categoryController.categoryList != null && categoryController.categoryList!.isEmpty)
        ? const SizedBox() : isPharmacy ? PharmacyCategoryView(categoryController: categoryController)
          : isFood ? FoodCategoryView(categoryController: categoryController) : Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 142,
                    child: categoryController.categoryList != null ? ListView.builder(
                      controller: scrollController,
                      itemCount: categoryController.categoryList!.length > 10 ? 10 : categoryController.categoryList!.length,
                      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap: () {
                              if(index == 9 && categoryController.categoryList!.length > 10) {
                                Get.toNamed(RouteHelper.getCategoryRoute());
                              } else {
                                Get.toNamed(RouteHelper.getCategoryItemRoute(
                                  categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                                  slug: categoryController.categoryList![index].slug??'',
                                ));
                              }
                            },
                            child: Container(
                              width: 88,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, spreadRadius: 0, offset: const Offset(0, 6))],
                              ),
                              child: Column(children: [
                                SizedBox(
                                  height: 56, width: 56,
                                  child: Stack(children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CustomImage(
                                        image: '${categoryController.categoryList![index].imageFullUrl}',
                                        height: 56, width: 56, fit: BoxFit.cover,
                                      ),
                                    ),

                                    (index == 9 && categoryController.categoryList!.length > 10) ? Positioned(
                                      right: 0, left: 0, top: 0, bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(18),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                              Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                              Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '+${categoryController.categoryList!.length - 10}',
                                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                            maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                          ),
                                        )
                                      ),
                                    ) : const SizedBox(),

                                  ]),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                Padding(
                                  padding: EdgeInsets.only(right: index == 0 ? Dimensions.paddingSizeExtraSmall : 0),
                                  child: Text(
                                    (index == 9 && categoryController.categoryList!.length > 10) ? 'see_all'.tr : categoryController.categoryList![index].name!,
                                    style: robotoBold.copyWith(fontSize: 11.5, height: 1.12, color: (index == 9 && categoryController.categoryList!.length > 10) ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium!.color),
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
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text('view_all'.tr, style: TextStyle(fontSize: Dimensions.paddingSizeDefault, color: Theme.of(context).cardColor)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10,)
                  ],
                ): CategoryShimmer(categoryController: categoryController),
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
    final ScrollController scrollController = ScrollController();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 142,
        child: categoryController.categoryList != null ? ListView.builder(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
          itemCount: categoryController.categoryList!.length > 10 ? 10 : categoryController.categoryList!.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
              child: InkWell(
                onTap: () {
                  if(index == 9 && categoryController.categoryList!.length > 10) {
                    Get.toNamed(RouteHelper.getCategoryRoute());
                  } else {
                    Get.toNamed(RouteHelper.getCategoryItemRoute(
                      categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                      slug: categoryController.categoryList![index].slug??'',
                    ));
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
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

                    Stack(
                      children: [

                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: CustomImage(
                            image: '${categoryController.categoryList![index].imageFullUrl}',
                            height: 54, width: double.infinity, fit: BoxFit.cover,
                          ),
                        ),

                        (index == 9 && categoryController.categoryList!.length > 10) ? Positioned(
                          right: 0, left: 0, top: 0, bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${categoryController.categoryList!.length - 10}',
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                              ),
                            )
                          ),
                        ) : const SizedBox(),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        (index == 9 && categoryController.categoryList!.length > 10) ? 'see_all'.tr :  categoryController.categoryList![index].name!,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall,
                        color: (index == 9 && categoryController.categoryList!.length > 10) ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium!.color),
                        maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      ),
                    )),
                  ]),
                ),
              ),
            );
          },
        ) : PharmacyCategoryShimmer(categoryController: categoryController),
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
          height: 142,
          child: categoryController.categoryList != null ? ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
            itemCount: categoryController.categoryList!.length > 10 ? 10 : categoryController.categoryList!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
                child: InkWell(
                  onTap: () {
                    if(index == 9 && categoryController.categoryList!.length > 10) {
                      Get.toNamed(RouteHelper.getCategoryRoute());
                    } else {
                      Get.toNamed(RouteHelper.getCategoryItemRoute(
                        categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                        slug: categoryController.categoryList![index].slug??'',
                      ));
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 88,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, spreadRadius: 0, offset: const Offset(0, 6))],
                    ),
                    child: Column(children: [

                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CustomImage(
                              image: '${categoryController.categoryList![index].imageFullUrl}',
                              height: 54, width: double.infinity, fit: BoxFit.cover,
                            ),
                          ),

                          (index == 9 && categoryController.categoryList!.length > 10) ? Positioned(
                            right: 0, left: 0, top: 0, bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                    Theme.of(context).primaryColor.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${categoryController.categoryList!.length - 10}',
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                                ),
                              )
                            ),
                          ) : const SizedBox(),
                        ],
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Expanded(child: Text(
                        (index == 9 && categoryController.categoryList!.length > 10) ?  'see_all'.tr : categoryController.categoryList![index].name ?? '',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, height: 1.12, color: (index == 9 && categoryController.categoryList!.length > 10) ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium!.color),
                        maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      )),
                    ]),
                  ),
                ),
              );
            },
          ) : FoodCategoryShimmer(categoryController: categoryController),
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
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: SizedBox(
              width: 80,
              child: Column(children: [
                Container(
                  height: 56, width: 56,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : Dimensions.paddingSizeExtraSmall,
                    right: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey[300],
                  )
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Padding(
                  padding: EdgeInsets.only(right: index == 0 ? Dimensions.paddingSizeExtraSmall : 0),
                  child: Container(
                    height: 10, width: 50,
                    color: Colors.grey[300],
                  ),
                ),

              ]),
            ),
          ),
        );
      },
    );
  }
}

class FoodCategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const FoodCategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
          child: SizedBox(
            width: 60,
            child: Column(children: [

              ClipOval(
                child: Shimmer(
                  child: Container(
                    height: 60, width: double.infinity,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).shadowColor,
                    )
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              Expanded(
                child: Shimmer(
                  child: Container(
                    height: 10, width: 50,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class PharmacyCategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const PharmacyCategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault, left: Dimensions.paddingSizeDefault, top: Dimensions.paddingSizeDefault),
          child: Shimmer(
            duration: const Duration(seconds: 2),
            enabled: true,
            child: Container(
              width: 70,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(100), topRight: Radius.circular(100)),
              ),
              child: Column(children: [

                Container(
                  height: 60, width: double.infinity,
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.grey[300],
                  )
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Expanded(
                  child: Container(
                    height: 10, width: 50,
                    color: Colors.grey[300],
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}