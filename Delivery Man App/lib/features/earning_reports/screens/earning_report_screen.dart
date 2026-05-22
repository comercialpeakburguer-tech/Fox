import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/features/earning_reports/controllers/earning_report_controller.dart';
import 'package:sixam_mart_delivery/features/earning_reports/domain/emun/filter_type.dart';
import 'package:sixam_mart_delivery/features/earning_reports/widgets/earning_card_widget.dart';
import 'package:sixam_mart_delivery/features/earning_reports/widgets/transaction_card_widget.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class EarningReportScreen extends StatefulWidget {
  const EarningReportScreen({super.key});

  @override
  State<EarningReportScreen> createState() => _EarningReportScreenState();
}

class _EarningReportScreenState extends State<EarningReportScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final reportController = Get.find<EarningReportController>();
    reportController.initSetDate();
    reportController.getEarningReport(offset: '1', from: reportController.from, to: reportController.to);
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 120 && !reportController.isLoading) {
        final pageSize = reportController.pageSize ?? 0;
        final currentCount = reportController.transactions?.length ?? 0;
        if (pageSize == 0 || currentCount < pageSize) {
          reportController.getEarningReport(offset: '${reportController.offset + 1}', from: reportController.from, to: reportController.to);
        }
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  String _formatTransactionDate(String? rawDate) {
    if(rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      return DateConverterHelper.dateTimeStringToDateTime(
        DateConverterHelper.isoStringToLocalDateTime(rawDate).toString().substring(0, 19),
      );
    } catch (_) {
      try {
        return DateConverterHelper.isoStringToLocalDateAnTime(rawDate);
      } catch (_) {
        return rawDate;
      }
    }
  }

  Future<void> _refreshReport(EarningReportController reportController) async {
    reportController.initSetDate();
    await reportController.getEarningReport(offset: '1', from: reportController.from, to: reportController.to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'earning_report'.tr),
      body: SafeArea(
        child: GetBuilder<EarningReportController>(builder: (reportController) {
          return RefreshIndicator(
            onRefresh: () async => _refreshReport(reportController),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      reportController.getEarningReportModel == null ?
                      const Center(child: Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: CircularProgressIndicator(),
                      )) :
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'earning_overview'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        EarningCardWidget(earningReportModel: reportController.getEarningReportModel!),
                      ]),

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Row(children: [
                        Expanded(
                          child: _FilterButton(
                            title: 'all'.tr,
                            isSelected: reportController.selectedFilter == FilterType.all,
                            onTap: () => reportController.setFilter(FilterType.all.name),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: _FilterButton(
                            title: 'this_week'.tr,
                            isSelected: reportController.selectedFilter == FilterType.thisWeek,
                            onTap: () => reportController.setFilter(FilterType.thisWeek.name),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: _FilterButton(
                            title: 'this_month'.tr,
                            isSelected: reportController.selectedFilter == FilterType.thisMonth,
                            onTap: () => reportController.setFilter(FilterType.thisMonth.name),
                          ),
                        ),
                      ]),

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Text(
                        AppConstants.appMode == AppMode.delivery ? "recent_transactions".tr : 'ride'.tr,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ]),
                  ),
                ),

                if(reportController.transactions == null)
                  const SliverToBoxAdapter(child: Center(child: Padding(
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: CircularProgressIndicator(),
                  )))
                else if(reportController.transactions!.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: context.height * 0.2),
                      child: Center(child: Text(
                        'no_transaction_found'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.6),
                        ),
                      )),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final txn = reportController.transactions![index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                          child: OrderCard(
                            orderId: txn.orderId ?? txn.rideId ?? '',
                            dateTime: _formatTransactionDate(txn.date),
                            rows: [
                              if ((txn.deliveryCharge ?? 0) > 0) OrderRow(label: 'delivery_charge', value: txn.deliveryCharge!),
                              if ((txn.incentive ?? 0) > 0) OrderRow(label: 'incentive', value: txn.incentive!),
                              if ((txn.rideCost ?? 0) > 0) OrderRow(label: 'ride_cost', value: txn.rideCost!),
                              if ((txn.commissionPaid ?? 0) > 0) OrderRow(label: 'commission_paid', value: txn.commissionPaid!),
                              if ((txn.vatTex ?? 0) > 0) OrderRow(label: 'vat_tax', value: txn.vatTex!),
                              if ((txn.tips ?? 0) > 0) OrderRow(label: 'tips', value: txn.tips!),
                            ],
                            netProfitLabel: 'net_income',
                            netProfitValue: txn.netProfit ?? 0,
                          ),
                        );
                      },
                      childCount: reportController.transactions!.length,
                    ),
                  ),

                if (reportController.isLoading && reportController.transactions != null)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeLarge)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Center(
          child: Text(
            title,
            style: robotoMedium.copyWith(
              color: isSelected ? Theme.of(context).cardColor : Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
      ),
    );
  }
}
