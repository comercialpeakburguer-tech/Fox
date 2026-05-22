import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart_delivery/features/disbursement/controllers/disbursement_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/disbursement/domain/models/disbursement_report_model.dart';
import 'package:sixam_mart_delivery/helper/date_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_image_widget.dart';
import 'package:sixam_mart_delivery/features/disbursement/widgets/disbursement_status_card_widget.dart';
import 'package:sixam_mart_delivery/features/disbursement/widgets/payment_information_dialog_widget.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class DisbursementScreen extends StatefulWidget {
  const DisbursementScreen({super.key});

  @override
  State<DisbursementScreen> createState() => _DisbursementScreenState();
}

class _DisbursementScreenState extends State<DisbursementScreen> with WidgetsBindingObserver {

  final JustTheController pendingToolTip = JustTheController();
  final JustTheController completedToolTip = JustTheController();
  final JustTheController cancelToolTip = JustTheController();
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshRepasses();
    _startRealtimeRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeTimer?.cancel();
    pendingToolTip.dispose();
    completedToolTip.dispose();
    cancelToolTip.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRepasses();
      _startRealtimeRefresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _realtimeTimer?.cancel();
    }
  }

  void _startRealtimeRefresh() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshRepasses());
  }

  Future<void> _refreshRepasses() async {
    final profileController = Get.find<ProfileController>();
    final disbursementController = Get.find<DisbursementController>();
    if(Get.find<AuthController>().isLoggedIn()) {
      await Future.wait([
        profileController.getProfile(),
        disbursementController.getDisbursementReport(1),
        disbursementController.getDisbursementMethodList(),
      ]);
    }
  }

  double _pendingAmount(DisbursementController controller, ProfileController profileController) {
    final double reportPending = controller.disbursementReportModel?.pending ?? 0;
    final double profilePending = profileController.profileModel?.pendingWithdraw ?? 0;
    return reportPending > 0 ? reportPending : profilePending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'Repasse',
        isBackButtonExist: true,
        actionWidget: GetBuilder<ProfileController>(builder: (profileController) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(200), border: Border.all(width: 1.5, color: Theme.of(context).primaryColor)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: CustomImageWidget(
                image: (profileController.profileModel != null && Get.find<AuthController>().isLoggedIn()) ? profileController.profileModel!.imageFullUrl ?? '' : '',
                width: 35, height: 35, fit: BoxFit.cover,
              ),
            ),
          );
        }),
      ),

      body: GetBuilder<ProfileController>(builder: (profileController) {
        return GetBuilder<DisbursementController>(builder: (disbursementController) {
          final report = disbursementController.disbursementReportModel;
          final bool isFirstLoading = report == null;
          return RefreshIndicator(
            onRefresh: _refreshRepasses,
            child: isFirstLoading ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 260),
                Center(child: CircularProgressIndicator()),
              ],
            ) : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Padding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, 0),
                  child: Row(children: [
                    Icon(Icons.sync_rounded, size: 16, color: Theme.of(context).primaryColor),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      'Atualiza automaticamente. Puxe para atualizar agora.',
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                    ),
                  ]),
                ),

                SizedBox(
                  height: 160,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [

                      DisbursementStatusCardWidget(
                        amount: _pendingAmount(disbursementController, profileController),
                        text: 'Repasses pendentes',
                        isPending: true,
                        pendingToolTip: pendingToolTip,
                      ),

                      DisbursementStatusCardWidget(
                        amount: report.completed ?? 0,
                        text: 'Repasses concluídos',
                        isCompleted: true,
                        completeToolTip: completedToolTip,
                      ),

                      DisbursementStatusCardWidget(
                        amount: report.canceled ?? 0,
                        text: 'Repasses cancelados',
                        isCanceled: true,
                        canceledToolTip: cancelToolTip,
                      ),

                    ]),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    'Histórico de repasses',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ),

                (report.disbursements != null  && report.disbursements!.isNotEmpty)? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.disbursements!.length,
                  itemBuilder: (context, index) {
                    Disbursements disbursement = report.disbursements![index];
                    return Column(children: [

                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                insetPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                                child: PaymentInformationDialogWidget(disbursement: disbursement),
                              );
                            }
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(PriceConverterHelper.convertPrice(disbursement.disbursementAmount), style: robotoMedium),
                          subtitle: Text(disbursement.withdrawMethod != null ? 'Método de pagamento: ${disbursement.withdrawMethod!.methodName}' : 'Método de pagamento removido',
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [

                            Text(
                              DateConverterHelper.dateTimeStringForDisbursement(disbursement.createdAt!),
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                color: disbursement.status == 'pending' ? Colors.blue.withValues(alpha: 0.1) : disbursement.status == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                disbursement.status == 'pending' ? 'Pendente' : disbursement.status == 'completed' ? 'Concluído' : 'Cancelado',
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: disbursement.status == 'pending' ? Colors.blue : disbursement.status == 'completed' ? Colors.green : Colors.red),
                              ),
                            ),

                          ]),
                        ),
                      ),

                      Divider(height: 2, thickness: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.5)),
                    ]);
                  },
                ) : Padding(
                  padding: const EdgeInsets.only(top: 200, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
                  child: Center(child: Text('Nenhum histórico disponível', textAlign: TextAlign.center, style: robotoMedium)),
                ),

              ]),
            ),
          );
        });
      }),
    );
  }
}