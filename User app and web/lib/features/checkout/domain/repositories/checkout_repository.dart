import 'dart:convert';
import 'dart:developer';
import 'package:get/get_connect/connect.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../../../../common/widgets/custom_snackbar.dart';

class CheckoutRepository implements CheckoutRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  CheckoutRepository({ required this.apiClient, required this.sharedPreferences});

  @override
  Future<int> getDmTipMostTapped() async {
    int mostDmTipAmount = 0;
    Response response = await apiClient.getData(AppConstants.mostTipsUri);
    if (response.statusCode == 200) {
      mostDmTipAmount = response.body['most_tips_amount'];
    }
    return mostDmTipAmount;
  }

  @override
  Future<bool> saveSharedPrefDmTipIndex(String index) async {
    return await sharedPreferences.setString(AppConstants.dmTipIndex, index);
  }

  @override
  String getSharedPrefDmTipIndex() {
    return sharedPreferences.getString(AppConstants.dmTipIndex) ?? "";
  }

  @override
  Future<Response> getDistanceInMeter(LatLng originLatLng, LatLng destinationLatLng) async {
    return await apiClient.getData(
      '${AppConstants.distanceMatrixUri}?origin_lat=${originLatLng.latitude}&origin_lng=${originLatLng.longitude}'
          '&destination_lat=${destinationLatLng.latitude}&destination_lng=${destinationLatLng.longitude}&mode=WALK',
      handleError: false,
    );
  }

  @override
  Future<double> getExtraCharge(double? distance) async {
    double extraCharge = 0;
    Response response = await apiClient.getData('${AppConstants.vehicleChargeUri}?distance=$distance', handleError: false);
    if (response.statusCode == 200) {
      extraCharge = double.parse(response.body.toString());
    }
    return extraCharge;
  }

  @override
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody, List<MultipartBody>? orderAttachment, List<String>? savedImages) async {
    Map<String, String> body = orderBody.toJson();
    if(savedImages != null && savedImages.isNotEmpty) {
      final List<String> cleanedSavedImages = savedImages.map((image) => image.trim()).where((image) => image.isNotEmpty).toList();
      if(cleanedSavedImages.isNotEmpty) {
        body['saved_images'] = jsonEncode(cleanedSavedImages);
        for(int index = 0; index < cleanedSavedImages.length; index++) {
          body['saved_images[$index]'] = cleanedSavedImages[index];
        }
      }
    }
    log("order Attachment: ${orderAttachment?.map((e) => e.file?.name).toList()}");
    log("Order Body: $body");
    return await apiClient.postMultipartData(AppConstants.placeOrderUri, body, orderAttachment ?? [], handleError: false);
  }

  @override
  Future<Response> placePrescriptionOrder(int? storeId, double? distance, String address, String longitude, String latitude, String note,
      List<MultipartBody> orderAttachment, List<String> savedImages, String dmTips, String deliveryInstruction) async {

    Map<String, String> body = {
      'store_id': storeId.toString(),
      'distance': distance.toString(),
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'order_note': note,
      'dm_tips': dmTips,
      'delivery_instruction': deliveryInstruction,
      'payment_method': 'cash_on_delivery',
      'order_type': 'delivery',
    };
    if(savedImages.isNotEmpty) {
      final List<String> cleanedSavedImages = savedImages.map((image) => image.trim()).where((image) => image.isNotEmpty).toList();
      if(cleanedSavedImages.isNotEmpty) {
        body['saved_images'] = jsonEncode(cleanedSavedImages);
        for(int index = 0; index < cleanedSavedImages.length; index++) {
          body['saved_images[$index]'] = cleanedSavedImages[index];
        }
      }
    }
    return await apiClient.postMultipartData(AppConstants.placePrescriptionOrderUri, body, orderAttachment, handleError: false);
  }

  @override
  Future<List<SavedPrescriptionModel>?> getSavedPrescriptionImages() async {
    List<SavedPrescriptionModel>? savedFiles;
    Response response = await apiClient.getData(AppConstants.savedFilesUri, handleError: false);
    if (response.statusCode == 200 && response.body != null && response.body['saved_files'] is List) {
      savedFiles = [];
      for (final savedFile in response.body['saved_files']) {
        if (savedFile is Map) {
          savedFiles.add(SavedPrescriptionModel.fromJson( Map<String, dynamic>.from(savedFile)));
        }
      }
    }
    return savedFiles;
  }

  @override
  Future<Response> storeSavedPrescriptionImages(List<MultipartBody> images) async {
    final response = await apiClient.postMultipartData(AppConstants.storeSavedFilesUri, {}, images, handleError: false);

    if (response.statusCode == 400 && response.statusText == 'connection_to_api_server_failed'.tr) {
      showCustomSnackBar('max_file_size_2mb'.tr);
      return response;
    }
    return response;
  }

  @override
  Future<Response> deleteSavedPrescriptionImages() async {
    return await apiClient.deleteData(AppConstants.deleteSavedFilesUri, handleError: false);
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
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async{
    return await _getOfflineMethodList();
  }

  Future<List<OfflineMethodModel>?> _getOfflineMethodList() async {
    List<OfflineMethodModel>? offlineMethodList;
    Response response = await apiClient.getData(AppConstants.offlineMethodListUri);
    if (response.statusCode == 200) {
      offlineMethodList = [];
      response.body.forEach((method) => offlineMethodList!.add(OfflineMethodModel.fromJson(method)));
    }
    return offlineMethodList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> getOrderTax(PlaceOrderBodyModel orderBody) async {
    Response response = await apiClient.postData(AppConstants.getOrderTaxUri, orderBody.toJson());
    return response;
  }

  @override
  Future<SurgePriceModel?> getSurgePrice({required String zoneId, required String moduleId, required String dateTime, String? guestId}) async {
    SurgePriceModel? surgePrice;
    Map<String, dynamic> body = {
      'zone_id': zoneId,
      'module_id': moduleId,
      'date_time': dateTime,
      'guest_id': guestId ?? '',
    };
    Response response = await apiClient.postData(AppConstants.getSurgePriceUri, body);
    if (response.statusCode == 200) {
      surgePrice = SurgePriceModel.fromJson(response.body);
    }
    return surgePrice;
  }
}
