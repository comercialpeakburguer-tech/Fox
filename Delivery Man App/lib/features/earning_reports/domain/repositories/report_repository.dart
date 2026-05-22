import 'dart:developer';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart_delivery/api/api_client.dart';
import 'package:sixam_mart_delivery/features/earning_reports/domain/models/earning_report_model.dart';
import 'package:sixam_mart_delivery/features/earning_reports/domain/repositories/report_repository_interface.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';

class EarningReportRepository implements EarningReportRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  EarningReportRepository({required this.apiClient, required this.sharedPreferences});

  String _getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  EarningReportModel _fallbackReportFromProfile() {
    final profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>().profileModel : null;
    final double today = profile?.todaysEarning ?? 0;
    final double week = profile?.thisWeekEarning ?? today;
    final double month = profile?.thisMonthEarning ?? week;
    final double total = profile?.totalEarning ?? profile?.totalIncome ?? month;
    final double net = profile?.balance ?? profile?.withDrawableBalance ?? week;

    return EarningReportModel(
      summary: Summary(
        totalEarnings: total,
        totalExpenses: 0,
        netProfit: net,
        breakdown: Breakdown(
          deliveryCharge: profile?.deliveryIncome ?? total,
          dmTips: profile?.totalTips ?? 0,
          adminCommission: 0,
        ),
      ),
      transactions: Transactions(
        totalSize: 0,
        limit: 10,
        offset: 1,
        data: const [],
      ),
    );
  }

  @override
  Future<EarningReportModel?> getEarningReport({required int offset, required String? from, required String? to, required bool isDelivery}) async {
    final filterParam = (from != null && to != null && from.isNotEmpty && to.isNotEmpty) ? '&filter=custom&from=$from&to=$to' : '';
    final token = _getUserToken();
    final String primaryUri = '${isDelivery ? AppConstants.newEarningReportUri : AppConstants.riderEarningReportUri}?limit=10&offset=$offset$filterParam&token=$token';

    Response response = await apiClient.getData(primaryUri, handleError: false);
    if(response.statusCode == 200 && response.body is Map<String, dynamic>) {
      log("earning report response: ${response.body}");
      return EarningReportModel.fromJson(response.body);
    }

    if(isDelivery) {
      final String legacyUri = '${AppConstants.earningReportUri}?limit=10&offset=$offset$filterParam&token=$token';
      Response legacyResponse = await apiClient.getData(legacyUri, handleError: false);
      if(legacyResponse.statusCode == 200 && legacyResponse.body is Map<String, dynamic>) {
        log("legacy earning report response: ${legacyResponse.body}");
        return EarningReportModel.fromJson(legacyResponse.body);
      }
    }

    return _fallbackReportFromProfile();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> get(int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList() {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}
