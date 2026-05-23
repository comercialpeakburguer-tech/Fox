import 'package:sixam_mart/features/search/controllers/search_controller.dart' as search;
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/search/widgets/filter_widget.dart';
import 'package:sixam_mart/features/search/widgets/item_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchResultWidget extends StatefulWidget {
  final String searchText;
  final TabController? tabController;
  const SearchResultWidget({super.key, required this.searchText, this.tabController});

  @override
  SearchResultWidgetState createState() => SearchResultWidgetState();
}

class SearchResultWidgetState extends State<SearchResultWidget> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if(widget.tabController != null){
      _tabController = widget.tabController;
    } else {
      _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      GetBuilder<search.SearchController>(builder: (searchController) {
        bool isNull = true;
        int length = 0;
        if(searchController.isStore) {
          isNull = searchController.searchStoreList == null;
          if(!isNull) {
            length = searchController.searchStoreList!.length;
          }
        }else {
          isNull = searchController.searchItemList == null;
          if(!isNull) {
            length = searchController.searchItemList!.length;
          }
        }
        return isNull ? const SizedBox() : Center(child: SizedBox(width: Dimensions.webMaxWidth, child: Padding(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
          child: Row(children: [
            Text(
              length.toString(),
              style: robotoBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Text(
              'results_found'.tr,
              style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
            )),
            ( ResponsiveHelper.isMobile(context)  && widget.searchText.isNotEmpty) ? InkWell(
              onTap: () {
                List<double?> prices = [];
                if(!Get.find<search.SearchController>().isStore) {
                  for (var product in Get.find<search.SearchController>().allItemList!) {
                    prices.add(product.price);
                  }
                  prices.sort();
                }
                double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;
                Get.dialog(FilterWidget(maxValue: maxValue, isStore: Get.find<search.SearchController>().isStore));
              },
              child: const Icon(Icons.filter_list),
            ) : const SizedBox(),
          ]),
        )));
      }),

      ResponsiveHelper.isDesktop(context) ? const SizedBox() :
      Center(child: Container(
        width: Dimensions.webMaxWidth,
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: FoxGoDesign.premiumShadow(opacity: 0.06, blur: 16, offset: const Offset(0, 7)),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.transparent,
          indicatorWeight: 0,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).disabledColor,
          unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
          labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),

          tabs: [
            Tab(text: 'item'.tr),
            Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                ? 'restaurants'.tr : 'stores'.tr),
          ],
        ),
      )),

      Expanded(child: NotificationListener(
        onNotification: (dynamic scrollNotification) {
          if (scrollNotification is ScrollEndNotification) {
            Get.find<search.SearchController>().setStore(_tabController!.index == 1);
            Get.find<search.SearchController>().searchData(widget.searchText, false);
          }
          return false;
        },
        child: TabBarView(
          controller: _tabController,
          children: const [
            ItemViewWidget(isItem: false),
            ItemViewWidget(isItem: true),
          ],
        ),
      )),

    ]);
  }
}
