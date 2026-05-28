import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/disbursement/controllers/disbursement_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/features/disbursement/widgets/withdraw_method_attention_dialog_widget.dart';

class DisbursementHelper {

  Future<bool> enableDisbursementWarningMessage(bool fromDashboard, {bool canShowDialog = true}) async {

    bool showWarning = false;

    final bool automatedDisbursement = Get.find<SplashController>().configModel!.disbursementType == 'automated';
    final bool eligibleDeliveryMan = Get.find<ProfileController>().profileModel!.type! != 'store_wise'
        && Get.find<ProfileController>().profileModel!.earnings != 0;

    if(automatedDisbursement && eligibleDeliveryMan){
      await Get.find<DisbursementController>().getDisbursementMethodList().then((success) {
        if(success){
          final methods = Get.find<DisbursementController>().disbursementMethodBody?.methods ?? [];
          // Fox GO: se já existe qualquer conta Pix/Banco cadastrada, não mostra alerta na home.
          // A escolha/edição do método padrão fica nas telas de repasses/carteira já existentes.
          showWarning = methods.isEmpty;
        }
      });
    } else {
      showWarning = false;
    }

    if(showWarning && canShowDialog) {
      Get.dialog(
        Dialog(
          alignment: Alignment.bottomCenter,
          backgroundColor: const Color(0xfffff1f1),
          insetPadding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          child: WithdrawMethodAttentionDialogWidget(isFromDashboard: fromDashboard),
        ),
      );
    }
    return showWarning;
  }

}