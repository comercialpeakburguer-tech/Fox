import 'package:country_code_picker/country_code_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sixam_mart/api/api_checker.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/payment_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/saved_prescription_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/surge_price_model.dart';
import 'package:sixam_mart/features/coupon/controllers/coupon_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/timeslote_model.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/features/checkout/widgets/order_successfull_dialog.dart';
import 'package:sixam_mart/features/checkout/widgets/partial_pay_dialog_widget.dart';
import 'package:sixam_mart/features/home/screens/home_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/file_validation_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:universal_html/html.dart' as html;

class CheckoutController extends GetxController implements GetxService {
  final CheckoutServiceInterface checkoutServiceInterface;
  CheckoutController({required this.checkoutServiceInterface});

  static const int maxPrescriptionFileCount = 5;
  static const int maxPrescriptionSaveBatchCount = 5;
  final int fileSize = Get.find<SplashController>().configModel?.validationConfig?.maxFileSize??2;
  late int maxPrescriptionFileSizeInBytes = (fileSize * 1024 * 1024);

  final TextEditingController couponController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController houseController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  final TextEditingController contactPersonNameController = TextEditingController();
  final TextEditingController contactPersonNumberController = TextEditingController();
  final TextEditingController contactPersonAddressController = TextEditingController();
  final FocusNode nameNode = FocusNode();
  final FocusNode phoneNode = FocusNode();
  final FocusNode streetNode = FocusNode();
  final FocusNode houseNode = FocusNode();
  final FocusNode floorNode = FocusNode();

  String? countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty ? Get.find<AuthController>().getUserCountryCode()
      : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode ?? Get.find<LocalizationController>().locale.countryCode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AddressModel? _address;
  AddressModel? get address => _address;

  AddressModel? _guestAddress;
  AddressModel? get guestAddress => _guestAddress;

  int? _mostDmTipAmount;
  int? get mostDmTipAmount => _mostDmTipAmount;

  String _preferableTime = '';
  String get preferableTime => _preferableTime;

  List<OfflineMethodModel>? _offlineMethodList;
  List<OfflineMethodModel>? get offlineMethodList => _offlineMethodList;

  bool _isPartialPay = false;
  bool get isPartialPay => _isPartialPay;

  double _tips = 0.0;
  double get tips => _tips;

  int _selectedTips = 0;
  int get selectedTips => _selectedTips;

  Store? _store;
  Store? get store => _store;

  int? _addressIndex = 0;
  int? get addressIndex => _addressIndex;

  XFile? _orderAttachment;
  XFile? get orderAttachment => _orderAttachment;

  Uint8List? _rawAttachment;
  Uint8List? get rawAttachment => _rawAttachment;

  bool _acceptTerms = true;
  bool get acceptTerms => _acceptTerms;

  int _paymentMethodIndex = -1;
  int get paymentMethodIndex => _paymentMethodIndex;

  int _selectedDateSlot = 0;
  int get selectedDateSlot => _selectedDateSlot;

  int _selectedTimeSlot = 0;
  int get selectedTimeSlot => _selectedTimeSlot;

  double? _distance;
  double? get distance => _distance;

  List<TimeSlotModel>? _timeSlots;
  List<TimeSlotModel>? get timeSlots => _timeSlots;

  List<TimeSlotModel>? _allTimeSlots;
  List<TimeSlotModel>? get allTimeSlots => _allTimeSlots;

  List<XFile> _pickedPrescriptions = [];
  List<XFile> get pickedPrescriptions => _pickedPrescriptions;

  List<String?> _pickedPrescriptionSavedImageNames = [];
  List<String?> get pickedPrescriptionSavedImageNames =>
      _pickedPrescriptionSavedImageNames;

  List<bool> _pickedPrescriptionFromMediaLibrary = [];
  List<bool> get pickedPrescriptionFromMediaLibrary => _pickedPrescriptionFromMediaLibrary;

  double? _extraCharge;
  double? get extraCharge => _extraCharge;

  String? _orderType = 'delivery';
  String? get orderType => _orderType;

  double _viewTotalPrice = 0;
  double? get viewTotalPrice => _viewTotalPrice;

  int _selectedOfflineBankIndex = 0;
  int get selectedOfflineBankIndex => _selectedOfflineBankIndex;

  int _selectedInstruction = -1;
  int get selectedInstruction => _selectedInstruction;

  bool _isDmTipSave = false;
  bool get isDmTipSave => _isDmTipSave;

  String? _digitalPaymentName;
  String? get digitalPaymentName => _digitalPaymentName;

  List<SavedPrescriptionModel>? _savedPrescriptions;
  List<SavedPrescriptionModel>? get savedPrescriptions => _savedPrescriptions;

  bool _isSavedPrescriptionLoading = false;
  bool get isSavedPrescriptionLoading => _isSavedPrescriptionLoading;

  bool _isSavedPrescriptionDeleting = false;
  bool get isSavedPrescriptionDeleting => _isSavedPrescriptionDeleting;

  String? _savedPrescriptionErrorMessage;
  String? get savedPrescriptionErrorMessage => _savedPrescriptionErrorMessage;

  bool _isPrescriptionUploading = false;
  bool get isPrescriptionUploading => _isPrescriptionUploading;

  int _prescriptionUploadingCount = 0;
  int get prescriptionUploadingCount => _prescriptionUploadingCount;

  bool _canShowTipsField = false;
  bool get canShowTipsField => _canShowTipsField;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isExpand = false;
  bool get isExpand => _isExpand;

  double _exchangeAmount = 0;
  double get exchangeAmount => _exchangeAmount;

  bool _isCreateAccount = false;
  bool get isCreateAccount => _isCreateAccount;

  bool _isFirstTime = true;
  bool get isFirstTime => _isFirstTime;

  double? _orderTax = 0.0;
  double? get orderTax => _orderTax;

  int? _taxIncluded;
  int? get taxIncluded => _taxIncluded;

  SurgePriceModel? _surgePrice;
  SurgePriceModel? get surgePrice => _surgePrice;

  bool  _isFirstTimeCodActive = true;
  bool get isFirstTimeCodActive => _isFirstTimeCodActive;

  void updateFirstTimeCodActive({bool isActive = true}) {
    _isFirstTimeCodActive = isActive;
    update();
  }

  void updateFirstTime() {
    _isFirstTime = true;
    update();
  }

  void resetOrderTax() {
    _orderTax = 0.0;
    _taxIncluded = null;
  }

  void setExchangeAmount(double value) {
    _exchangeAmount = value;
  }

  void initAdditionData(){
    noteController.clear();
    _selectedInstruction = -1;
  }

  Future<void> initCheckoutData(int? storeId) async {
    Get.find<CouponController>().removeCouponData(false);

    _store = await Get.find<StoreController>().getStoreDetails(Store(id: storeId), false);

    if (_store != null) {
      await getSurgePrice(
        zoneId: _store!.zoneId.toString(),
        moduleId: _store!.moduleId.toString(),
        dateTime: DateConverter.dateToDateTime(DateTime.now()),
        guestId: AuthHelper.getGuestId(),
      );

      if(Get.find<SplashController>().module == null) {
        await Get.find<SplashController>().getModules();

        int i = 0;
        for(i = 0; i < Get.find<SplashController>().moduleList!.length; i++){
          if(_store!.moduleId == Get.find<SplashController>().moduleList![i].id){
            break;
          }
        }
        Get.find<SplashController>().setModule(Get.find<SplashController>().moduleList![i]);
      }

      initializeTimeSlot(_store!);
    }
  }

  void showTipsField(){
    _canShowTipsField = !_canShowTipsField;
    update();
  }

  Future<void> addTips(double tips)async {
    _tips = tips;
    update();
  }

  void expandedUpdate(bool status){
    _isExpanded = status;
    update();
  }

  void setPaymentMethod(int index, {bool isUpdate = true}) {
    _paymentMethodIndex = index;
    if(_isFirstTimeCodActive) updateFirstTimeCodActive(isActive: false);
    if(isUpdate){
      update();
    }
  }

  void changeDigitalPaymentName(String name, {bool willUpdate = true}){
    _digitalPaymentName = name;
    if(willUpdate) {
      update();
    }
  }

  void setOrderType(String? type, {bool notify = true}) {
    _orderType = type;
    if(notify) {
      update();
    }
  }

  void changePartialPayment({bool isUpdate = true}){
    _isPartialPay = !_isPartialPay;
    if(isUpdate) {
      update();
    }
  }

  void setAddressIndex(int? index) {
    _addressIndex = index;
    update();
  }

  void setGuestAddress(AddressModel? address, {bool isUpdate = true}){
    _guestAddress = address;
    contactPersonAddressController.text = address?.address ?? '';
    if(isUpdate) {
      update();
    }
  }

  Future<void> getDmTipMostTapped()async {
    _mostDmTipAmount = await checkoutServiceInterface.getDmTipMostTapped();
    update();
  }

  void setPreferenceTimeForView(String time, {bool isUpdate = true}){
    _preferableTime = time;
    if(isUpdate) {
      update();
    }
  }

  Future<List<OfflineMethodModel>?> getOfflineMethodList()async {
    _offlineMethodList = null;
    _offlineMethodList = await checkoutServiceInterface.getOfflineMethodList();
    update();
    return _offlineMethodList;
  }

  void updateTips(int index, {bool notify = true}) {
    _selectedTips = index;
    if(_selectedTips == 0 || _selectedTips == 5) {
      _tips = 0;
    }else {
      _tips = double.parse(AppConstants.tips[index]);
    }
    if(notify) {
      update();
    }
  }

  void saveSharedPrefDmTipIndex(String i){
    checkoutServiceInterface.saveSharedPrefDmTipIndex(i);
  }

  String getSharedPrefDmTipIndex() {
    return checkoutServiceInterface.getSharedPrefDmTipIndex();
  }

  void setTotalAmount(double amount){
    _viewTotalPrice = amount;
  }

  void clearPrevData() {
    _distance = null;
    _addressIndex = 0;
    _acceptTerms = true;
    _paymentMethodIndex = -1;
    _selectedDateSlot = 0;
    _selectedTimeSlot = 0;
    _orderAttachment = null;
    _rawAttachment = null;
  }

  Future<void> initializeTimeSlot(Store store) async {
    _timeSlots = await checkoutServiceInterface.initializeTimeSlot(store, Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);
    _allTimeSlots = await checkoutServiceInterface.initializeTimeSlot(store, Get.find<SplashController>().configModel!.scheduleOrderSlotDuration!);

    _validateSlot(_allTimeSlots!, 0, store.orderPlaceToScheduleInterval, notify: false);
  }

  void _validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval, {bool notify = true}) {
    _timeSlots = checkoutServiceInterface.validateTimeSlot(slots, dateIndex, interval, Get.find<SplashController>().configModel!.moduleConfig!.module!.orderPlaceToScheduleInterval!);

    if(notify) {
      update();
    }
  }

  void pickPrescriptionImage({required bool isRemove, required bool isCamera}) async {
    if(isRemove) {
      _pickedPrescriptions = [];
      _pickedPrescriptionSavedImageNames = [];
      _pickedPrescriptionFromMediaLibrary = [];
    }else {
      final fileValidator = FileValidationHelper();
      XFile? xFile = await ImagePicker().pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery, imageQuality: 50);
      if(xFile != null) {

        final bool isValid = await fileValidator.isFileUnder2MB(xFile);

        if(isValid == false) {
          showCustomSnackBar('please_upload_lower_size_file'.tr);
          update();
          return;
        }
        if(_pickedPrescriptions.length >= maxPrescriptionFileCount) {
          showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
          update();
          return;
        }

        final String signature = await _getPrescriptionSignature(xFile);
        final Set<String> existingSignatures = await _getPrescriptionSignatureSet(_pickedPrescriptions, _pickedPrescriptionSavedImageNames);

        if(existingSignatures.contains(signature)) {
          showCustomSnackBar('This prescription image is already added.');
        } else {
          _pickedPrescriptions.add(xFile);
          _pickedPrescriptionSavedImageNames.add(null);
          _pickedPrescriptionFromMediaLibrary.add(false);
        }
      }
      update();
    }
  }

  Future<List<XFile>?> pickMultiplePrescriptionImages({int? maxSelectable}) async {
    final int effectiveLimit = (maxSelectable ?? maxPrescriptionSaveBatchCount) <= maxPrescriptionSaveBatchCount
        ? (maxSelectable ?? maxPrescriptionSaveBatchCount)
        : maxPrescriptionSaveBatchCount;

    if(effectiveLimit <= 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
      return [];
    }

    List<XFile> xFiles;
    if(effectiveLimit == 1) {
      final XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
      xFiles = file != null ? [file] : [];
    } else {
      xFiles = await ImagePicker().pickMultiImage(imageQuality: 100, limit: effectiveLimit);
    }

    if(xFiles.isEmpty) return xFiles;

    final fileValidator = FileValidationHelper();

    final List<XFile> validFiles = [];
    bool hasOversizeFile = false;
    for(final XFile file in xFiles) {
      final bool isValid = await fileValidator.isFileUnder2MB(file);
      if (isValid) {
        validFiles.add(file);
      } else {
        hasOversizeFile = true;
      }
    }


    print("hasOversizeFile: $hasOversizeFile");

    if(hasOversizeFile) {
      showCustomSnackBar('max_file_size_2mb'.tr);
    }
    return validFiles;
  }

  Future<void> addPrescriptionImages(List<XFile> xFiles, {bool isAutoSaved = false, List<String?>? savedImageNames, List<bool>? mediaLibraryFlags}) async {
    if(xFiles.isEmpty) {
      return;
    }

    final List<String?> incomingSavedNames = savedImageNames != null && savedImageNames.length == xFiles.length
        ? List<String?>.from(savedImageNames) : List<String?>.filled(xFiles.length, null);
    final List<bool> incomingMediaLibraryFlags = mediaLibraryFlags != null && mediaLibraryFlags.length == xFiles.length
        ? List<bool>.from(mediaLibraryFlags) : List<bool>.filled(xFiles.length, false);

    final Set<String> existingSignatures = await _getPrescriptionSignatureSet(_pickedPrescriptions, _pickedPrescriptionSavedImageNames);

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount}) uniquePayload = await _getUniquePrescriptionPayload(
      xFiles, incomingSavedNames, incomingMediaLibraryFlags, existingSignatures: existingSignatures,
    );

    if(uniquePayload.files.isEmpty) {
      showCustomSnackBar('This prescription image is already added.');
      return;
    }

    // Apply global count limits
    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) limitedPayload = _limitPrescriptionPayload(
        uniquePayload.files, uniquePayload.savedNames, uniquePayload.mediaLibraryFlags, availableSlots: maxPrescriptionFileCount - _pickedPrescriptions.length);

    if(limitedPayload.files.isEmpty) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
      return;
    }

    if(uniquePayload.skippedCount > 0) {
      showCustomSnackBar('Duplicate prescription image skipped.', isError: false);
    }
    if(limitedPayload.trimmedCount > 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
    }

    // Identify which files need to be uploaded to the server
    final List<XFile> filesToSave = await _getFilesNeedingMediaSave(limitedPayload.files, limitedPayload.savedNames);

    List<String> newlySavedNames = [];
    if(isAutoSaved && filesToSave.isNotEmpty) {
      _isPrescriptionUploading = true;
      _prescriptionUploadingCount = filesToSave.length;
      update();

      newlySavedNames = await _saveToMediaLibrary(filesToSave);

      _isPrescriptionUploading = false;
      _prescriptionUploadingCount = 0;
    }

    _pickedPrescriptions.addAll(limitedPayload.files);
    _pickedPrescriptionSavedImageNames.addAll(
      _mergeSavedImageNames(limitedPayload.savedNames, newlySavedNames),
    );
    _pickedPrescriptionFromMediaLibrary.addAll(limitedPayload.mediaLibraryFlags);
    update();
  }

  Future<void> updatePrescriptionImages(List<XFile> xFiles, {bool isAutoSaved = false, List<String?>? savedImageNames, List<bool>? mediaLibraryFlags}) async {
    final List<String?> incomingSavedNames = savedImageNames != null && savedImageNames.length == xFiles.length
        ? List<String?>.from(savedImageNames) : List<String?>.filled(xFiles.length, null);
    final List<bool> incomingMediaLibraryFlags = mediaLibraryFlags != null && mediaLibraryFlags.length == xFiles.length
        ? List<bool>.from(mediaLibraryFlags) : List<bool>.filled(xFiles.length, false);

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount}) uniquePayload = await _getUniquePrescriptionPayload(
      xFiles, incomingSavedNames, incomingMediaLibraryFlags,
    );

    if(uniquePayload.files.isEmpty) {
      showCustomSnackBar('At least one prescription image is required.');
      return;
    }

    final ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) limitedPayload = _limitPrescriptionPayload(
        uniquePayload.files, uniquePayload.savedNames, uniquePayload.mediaLibraryFlags);

    if(uniquePayload.skippedCount > 0) {
      showCustomSnackBar('Duplicate prescription image skipped.', isError: false);
    }
    if(limitedPayload.trimmedCount > 0) {
      showCustomSnackBar('you_have_reached_your_maximum_limit'.tr);
    }

    final List<XFile> filesToSave = await _getFilesNeedingMediaSave(limitedPayload.files, limitedPayload.savedNames);

    List<String> newlySavedNames = [];
    if(isAutoSaved && filesToSave.isNotEmpty) {
      _isPrescriptionUploading = true;
      _prescriptionUploadingCount = filesToSave.length;
      update();

      newlySavedNames = await _saveToMediaLibrary(filesToSave);

      _isPrescriptionUploading = false;
      _prescriptionUploadingCount = 0;
    }

    _pickedPrescriptions.clear();
    _pickedPrescriptionSavedImageNames.clear();
    _pickedPrescriptionFromMediaLibrary.clear();
    _pickedPrescriptions.addAll(limitedPayload.files);
    _pickedPrescriptionSavedImageNames.addAll(
      _mergeSavedImageNames(limitedPayload.savedNames, newlySavedNames),
    );
    _pickedPrescriptionFromMediaLibrary.addAll(limitedPayload.mediaLibraryFlags);
    update();
  }

  ({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int trimmedCount}) _limitPrescriptionPayload(
      List<XFile> files, List<String?> savedImageNames, List<bool> mediaLibraryFlags, {int availableSlots = maxPrescriptionFileCount}) {
    final int sanitizedAvailableSlots = availableSlots < 0 ? 0 : availableSlots;
    if(files.length <= sanitizedAvailableSlots) {
      return (files: files, savedNames: savedImageNames, mediaLibraryFlags: mediaLibraryFlags, trimmedCount: 0);
    }

    return (
    files: files.take(sanitizedAvailableSlots).toList(),
    savedNames: savedImageNames.take(sanitizedAvailableSlots).toList(),
    mediaLibraryFlags: mediaLibraryFlags.take(sanitizedAvailableSlots).toList(),
    trimmedCount: files.length - sanitizedAvailableSlots,
    );
  }

  Future<({List<XFile> files, List<String?> savedNames, List<bool> mediaLibraryFlags, int skippedCount})> _getUniquePrescriptionPayload(
      List<XFile> xFiles,
      List<String?> savedImageNames,
      List<bool> mediaLibraryFlags, {
        Set<String>? existingSignatures,
      }) async {
    final Set<String> signatures = existingSignatures != null ? <String>{...existingSignatures} : <String>{};
    final List<XFile> uniqueFiles = [];
    final List<String?> uniqueSavedNames = [];
    final List<bool> uniqueMediaLibraryFlags = [];
    int skippedCount = 0;

    for(int index = 0; index < xFiles.length; index++) {
      final XFile file = xFiles[index];
      final String? savedName = savedImageNames[index];
      final bool isFromMediaLibrary = mediaLibraryFlags[index];

      final String localSignature = await _getPrescriptionSignature(file);
      final String? savedSignature = (savedName?.trim().isNotEmpty ?? false) ? await _getPrescriptionSignature(file, savedImageName: savedName) : null;

      if (signatures.contains(localSignature) || (savedSignature != null && signatures.contains(savedSignature))) {
        skippedCount++;
      } else {
        signatures.add(localSignature);
        if(savedSignature != null) {
          signatures.add(savedSignature);
        }
        uniqueFiles.add(file);
        uniqueSavedNames.add(savedName);
        uniqueMediaLibraryFlags.add(isFromMediaLibrary);
      }
    }

    return (files: uniqueFiles, savedNames: uniqueSavedNames, mediaLibraryFlags: uniqueMediaLibraryFlags, skippedCount: skippedCount);
  }

  Future<Set<String>> _getPrescriptionSignatureSet(List<XFile> files, List<String?> savedImageNames) async {
    final Set<String> signatures = <String>{};
    for(int index = 0; index < files.length; index++) {
      signatures.add(await _getPrescriptionSignature(files[index]));

      if(index < savedImageNames.length && (savedImageNames[index]?.trim().isNotEmpty ?? false)) {
        signatures.add(await _getPrescriptionSignature(
          files[index],
          savedImageName: savedImageNames[index],
        ));
      }
    }
    return signatures;
  }

  Future<String> _getPrescriptionSignature(XFile file, {String? savedImageName}) async {
    final String normalizedSavedImageName = savedImageName?.trim() ?? '';
    if(normalizedSavedImageName.isNotEmpty) {
      return 'saved:${normalizedSavedImageName.toLowerCase()}';
    }

    final String fileName = file.name.isNotEmpty ? file.name : path.basename(file.path);
    final int fileLength = await file.length();
    final String extension = path.extension(fileName).toLowerCase();

    if (fileName.contains('image_picker') || fileName.contains('scaled_') || fileName.length > 40) {
      return 'local-size:$fileLength$extension';
    }

    return 'local:${fileName.toLowerCase()}:$fileLength';
  }

  Future<List<XFile>> _getFilesNeedingMediaSave(List<XFile> files, List<String?> savedImageNames) async {
    final List<XFile> filesToSave = [];
    for(int index = 0; index < files.length; index++) {
      final String savedImageName = index < savedImageNames.length ? savedImageNames[index]?.trim() ?? '' : '';
      if(savedImageName.isNotEmpty) {
        continue;
      }
      filesToSave.add(files[index]);
    }
    return filesToSave;
  }

  Future<List<String>> _saveToMediaLibrary(List<XFile> xFiles) async {
    if(xFiles.isEmpty) {
      return [];
    }

    final Map<String, int> previousSavedNameCounts = _getSavedFileNameCounts(_savedPrescriptions);
    List<MultipartBody> savedImages = [];
    for(XFile file in xFiles) {
      savedImages.add(MultipartBody('saved_images[]', file));
    }

    Response response = await checkoutServiceInterface.storeSavedPrescriptionImages(savedImages);

    if(response.statusCode == 200){
      await getSavedPrescriptionImages(reload: true);
      return _getNewlySavedFileNames(previousSavedNameCounts, _savedPrescriptions);
    }else{
      showCustomSnackBar(response.body?['message'] ?? response.statusText);
      return [];
    }
  }

  List<String?> _mergeSavedImageNames(List<String?> savedNames, List<String> newlySavedNames) {
    if(newlySavedNames.isEmpty) {
      return List<String?>.from(savedNames);
    }

    final List<String?> mergedNames = List<String?>.from(savedNames);
    int newSavedIndex = 0;
    for(int index = 0; index < mergedNames.length && newSavedIndex < newlySavedNames.length; index++) {
      if(mergedNames[index]?.trim().isEmpty ?? true) {
        mergedNames[index] = newlySavedNames[newSavedIndex];
        newSavedIndex++;
      }
    }
    return mergedNames;
  }

  Map<String, int> _getSavedFileNameCounts(List<SavedPrescriptionModel>? savedPrescriptions) {
    final Map<String, int> counts = <String, int>{};
    if(savedPrescriptions == null) {
      return counts;
    }

    for(final SavedPrescriptionModel savedPrescription in savedPrescriptions) {
      final String fileName = savedPrescription.fileName?.trim() ?? '';
      if(fileName.isNotEmpty) {
        counts[fileName] = (counts[fileName] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<String> _getNewlySavedFileNames(Map<String, int> previousCounts, List<SavedPrescriptionModel>? currentSavedPrescriptions) {
    final Map<String, int> remainingCounts = <String, int>{...previousCounts};
    final List<String> newFileNames = [];

    if(currentSavedPrescriptions == null) {
      return newFileNames;
    }

    for(final SavedPrescriptionModel savedPrescription in currentSavedPrescriptions) {
      final String fileName = savedPrescription.fileName?.trim() ?? '';
      if(fileName.isEmpty) {
        continue;
      }

      final int existingCount = remainingCounts[fileName] ?? 0;
      if(existingCount > 0) {
        remainingCounts[fileName] = existingCount - 1;
      } else {
        newFileNames.add(fileName);
      }
    }

    return newFileNames;
  }

  Future<void> getSavedPrescriptionImages({bool reload = false})async {
    if(_isSavedPrescriptionLoading) {
      return;
    }

    if(!reload && _savedPrescriptions != null) {
      return;
    }

    _isSavedPrescriptionLoading = true;
    _savedPrescriptionErrorMessage = null;
    if(reload){
      _savedPrescriptions = null;
    }
    update();

    final List<SavedPrescriptionModel>? savedFiles = await checkoutServiceInterface.getSavedPrescriptionImages();
    if(savedFiles != null) {
      _savedPrescriptions = savedFiles;
    }else {
      _savedPrescriptions ??= [];
      _savedPrescriptionErrorMessage = 'unable_to_load_data'.tr;
    }
    _isSavedPrescriptionLoading = false;
    update();
  }

  Future<bool> clearAllSavedPrescriptionImages() async {
    if (_isSavedPrescriptionDeleting || _savedPrescriptions == null || _savedPrescriptions!.isEmpty) {
      return false;
    }

    _isSavedPrescriptionDeleting = true;
    update();

    final Response response = await checkoutServiceInterface.deleteSavedPrescriptionImages();
    _isSavedPrescriptionDeleting = false;

    if (response.statusCode == 200) {
      _savedPrescriptions!.clear();
      update();
      return true;
    } else {
      showCustomSnackBar(response.body?['message'] ?? response.statusText);
      update();
      return false;
    }
  }

  Future<List<XFile>> getSelectedSavedPrescriptionFiles(List<int> indexes) async {
    if (_savedPrescriptions == null || _savedPrescriptions!.isEmpty || indexes.isEmpty) {
      return [];
    }

    final List<XFile> files = [];
    for (final int index in indexes) {
      if (index < 0 || index >= _savedPrescriptions!.length) {continue;}

      final XFile? file = await _downloadSavedPrescriptionFile(_savedPrescriptions![index]);
      if (file != null) {files.add(file);}
    }

    return files;
  }

  List<String> getSelectedSavedPrescriptionNames(List<int> indexes) {
    if (_savedPrescriptions == null || _savedPrescriptions!.isEmpty || indexes.isEmpty) {
      return [];
    }

    return indexes.where((index) => index >= 0 && index < _savedPrescriptions!.length).map((index)
    => _savedPrescriptions![index].fileName ?? '').where((fileName) => fileName.isNotEmpty).toList();
  }

  Future<XFile?> _downloadSavedPrescriptionFile(SavedPrescriptionModel savedPrescription) async {
    final String imageUrl = savedPrescription.imageFullUrl ?? '';
    if (imageUrl.isEmpty) {
      return null;
    }

    final String fileName =
    savedPrescription.fileName?.trim().isNotEmpty == true ? savedPrescription.fileName!.trim()
        : 'saved_prescription_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageUrl)}';
    final String requestUrl = kIsWeb && imageUrl.startsWith('http')
        ? '${AppConstants.baseUrl}/image-proxy?url=${Uri.encodeComponent(imageUrl)}'
        : imageUrl;

    try {
      final http.Response response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode != 200) {
        return null;
      }

      if (kIsWeb) {
        final Uint8List bytes = response.bodyBytes;
        final String extension = path.extension(fileName).toLowerCase();

        String mimeType = 'image/jpeg';
        if (extension == '.png') {
          mimeType = 'image/png';
        } else if (extension == '.webp') {
          mimeType = 'image/webp';
        } else if (extension == '.gif') {
          mimeType = 'image/gif';
        }

        return XFile.fromData(
          bytes,
          name: fileName,
          mimeType: mimeType,
        );
      }

      final Directory directory = await getTemporaryDirectory();
      final String filePath = path.join( directory.path, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return XFile(file.path);
    } catch (_) {
      return null;
    }
  }

  void removePrescriptionImage(int index) {
    _pickedPrescriptions.removeAt(index);
    if (_pickedPrescriptionSavedImageNames.length > index) {
      _pickedPrescriptionSavedImageNames.removeAt(index);
    }
    if (_pickedPrescriptionFromMediaLibrary.length > index) {
      _pickedPrescriptionFromMediaLibrary.removeAt(index);
    }
    update();
  }

  bool isStoreClosed(bool today, bool active, List<Schedules>? schedules) {
    return Get.find<StoreController>().isStoreClosed(today, active, schedules);
  }

  bool isStoreOpenNow(bool active, List<Schedules>? schedules) {
    return Get.find<StoreController>().isStoreOpenNow(active, schedules);
  }

  Future<double?> getDistanceInKM(LatLng originLatLng, LatLng destinationLatLng) async {
    _distance = -1;
    Response response = await checkoutServiceInterface.getDistanceInMeter(originLatLng, destinationLatLng);
    try {
      if (response.statusCode == 200) {
        final double distanceMater = response.body['distanceMeters']?.toDouble();
        _distance = distanceMater / 1000;
      } else {
        _distance = Geolocator.distanceBetween(originLatLng.latitude, originLatLng.longitude, destinationLatLng.latitude, destinationLatLng.longitude) / 1000;
      }
    } catch (e) {
      _distance = Geolocator.distanceBetween(originLatLng.latitude, originLatLng.longitude, destinationLatLng.latitude, destinationLatLng.longitude) / 1000;
    }

    await _getExtraCharge(_distance);

    update();
    return _distance;
  }

  double parseDuration(String duration) {
    return double.tryParse(duration.replaceAll('s', '')) ?? 0.0;
  }

  Future<double?> _getExtraCharge(double? distance) async {
    _extraCharge = null;
    _extraCharge = await checkoutServiceInterface.getExtraCharge(distance);
    return _extraCharge;
  }

  Future<bool> checkBalanceStatus(double totalPrice, double discount) async {
    totalPrice = (totalPrice - discount);
    if(isPartialPay){
      changePartialPayment();
    }
    setPaymentMethod(-1);
    if((Get.find<ProfileController>().userInfoModel!.walletBalance! < totalPrice) && (Get.find<ProfileController>().userInfoModel!.walletBalance! != 0.0)){
      Get.dialog(PartialPayDialogWidget(isPartialPay: true, totalPrice: totalPrice), useSafeArea: false,);
    }else{
      Get.dialog(PartialPayDialogWidget(isPartialPay: false, totalPrice: totalPrice), useSafeArea: false,);
    }
    update();
    return true;
  }

  void selectOfflineBank(int index, {bool canUpdate = true}){
    _selectedOfflineBankIndex = index;
    if(canUpdate) {
      update();
    }
  }

  void setInstruction(int index){
    if(_selectedInstruction == index){
      _selectedInstruction = -1;
    }else {
      _selectedInstruction = index;
    }
    update();
  }

  void toggleDmTipSave() {
    _isDmTipSave = !_isDmTipSave;
    update();
  }

  void stopLoader({bool canUpdate = true}) {
    _isLoading = false;
    if(canUpdate) {
      update();
    }
  }

  Future<String> placeOrder(PlaceOrderBodyModel placeOrderBody, int? zoneID, double amount, double? maximumCodOrderAmount, bool fromCart,
      bool isCashOnDeliveryActive, List<XFile>? orderAttachment, {bool isOfflinePay = false}) async {
    List<MultipartBody>? multiParts = [];
    List<String> savedImages = [];
    final List<XFile> attachments = orderAttachment ?? [];
    for(int index = 0; index < attachments.length; index++) {
      final bool fromMediaLibrary = index < _pickedPrescriptionFromMediaLibrary.length && _pickedPrescriptionFromMediaLibrary[index];
      final String savedImageName = index < _pickedPrescriptionSavedImageNames.length ? _pickedPrescriptionSavedImageNames[index]?.trim() ?? '' : '';
      if (fromMediaLibrary && savedImageName.isNotEmpty) {
        savedImages.add(savedImageName);
        continue;
      }
      XFile file = attachments[index];
      multiParts.add(MultipartBody('order_attachment[]', file));
    }
    _isLoading = true;
    update();
    String orderID = '';
    String userID = '';
    Response response = await checkoutServiceInterface.placeOrder(placeOrderBody, multiParts, savedImages);
    _isLoading = false;
    if (response.statusCode == 200) {
      String? message = response.body['message'];
      orderID = response.body['order_id'].toString();
      if(response.body['user_id'] != null) {
        userID = response.body['user_id'].toString();
      }
      Get.find<ItemController>().cartIndexSet();

      if(!isOfflinePay) {
        callback(true, message, orderID, zoneID, amount, maximumCodOrderAmount, fromCart, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber!, userID);
      } else {
        showCustomSnackBar('order_placed_successfully'.tr, isError: false);
        Get.find<CartController>().getCartDataOnline();
        Get.offNamed(RouteHelper.getOfflinePaymentScreen(
          zoneId: zoneID, total: amount, orderId: orderID, contactNumber: placeOrderBody.contactPersonNumber??'',
          maxCodOrderAmount: maximumCodOrderAmount, fromCart: fromCart, isCodActive: isCashOnDeliveryActive, forParcel: false,
        ));
      }
      _orderAttachment = null;
      _rawAttachment = null;
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      if(!isOfflinePay) {
        callback(false, response.statusText, '-1', zoneID, amount, maximumCodOrderAmount, fromCart, isCashOnDeliveryActive, placeOrderBody.contactPersonNumber, userID);
      } else {
        showCustomSnackBar(response.statusText);
      }
    }
    update();

    return orderID;
  }

  Future<void> placePrescriptionOrder({required int? storeId, required int? zoneID, required double? distance, required String address, required String longitude,
    required String latitude, required String note, required List<XFile> orderAttachment, required List<String> savedImages, required String dmTips,
    required String deliveryInstruction, required double orderAmount, required double maxCodAmount, required bool fromCart, required bool isCashOnDeliveryActive,
  }) async {
    List<MultipartBody> multiParts = [];
    List<String> resolvedSavedImages = [];
    for(int index = 0; index < orderAttachment.length; index++) {
      final bool fromMediaLibrary = index < _pickedPrescriptionFromMediaLibrary.length && _pickedPrescriptionFromMediaLibrary[index];
      final String savedImageName = index < _pickedPrescriptionSavedImageNames.length ? _pickedPrescriptionSavedImageNames[index]?.trim() ?? '' : '';
      if (fromMediaLibrary && savedImageName.isNotEmpty) {
        resolvedSavedImages.add(savedImageName);
        continue;
      }
      XFile file = orderAttachment[index];
      multiParts.add(MultipartBody('order_attachment[]', file));
    }
    _isLoading = true;
    update();
    Response response = await checkoutServiceInterface.placePrescriptionOrder(storeId, distance, address,longitude, latitude, note, multiParts, resolvedSavedImages, dmTips, deliveryInstruction);
    _isLoading = false;
    if (response.statusCode == 200) {
      String? message = response.body['message'];
      String orderID = response.body['order_id'].toString();
      callback(true, message, orderID, zoneID, orderAmount, maxCodAmount, fromCart, isCashOnDeliveryActive, null, '');
      _orderAttachment = null;
      _rawAttachment = null;
      if (kDebugMode) {
        print('-------- Order placed successfully $orderID ----------');
      }
    } else {
      callback(false, response.statusText, '-1', zoneID, orderAmount, maxCodAmount, fromCart, isCashOnDeliveryActive, null, '');
    }
    update();
  }

  void callback(
      bool isSuccess, String? message, String orderID, int? zoneID, double amount,
      double? maximumCodOrderAmount, bool fromCart, bool isCashOnDeliveryActive, String? contactNumber,
      String userID) async {

    if(isSuccess) {
      if(fromCart) {
        Get.find<CartController>().clearCartList();
      }
      setGuestAddress(null);
      if(!Get.find<OrderController>().showBottomSheet){
        Get.find<OrderController>().showRunningOrders(canUpdate: false);
      }
      if(isDmTipSave){
        saveSharedPrefDmTipIndex(selectedTips.toString());
      }
      stopLoader(canUpdate: false);
      HomeScreen.loadData(true);
      if(paymentMethodIndex == 2) {
        if(GetPlatform.isWeb) {
          // Get.back();
          await Get.find<AuthController>().saveGuestNumber(contactNumber ?? '');
          String? hostname = html.window.location.hostname;
          String protocol = html.window.location.protocol;
          String selectedUrl;
          selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=$orderID&&customer_id=${Get.find<ProfileController>().userInfoModel?.id ?? (userID.isNotEmpty ? userID : AuthHelper.getGuestId())}'
              '&payment_method=$digitalPaymentName&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=$orderID&status=';

          html.window.open(selectedUrl,"_self");
        } else{
          Get.offNamed(RouteHelper.getPaymentRoute(
            orderID, Get.find<ProfileController>().userInfoModel?.id ?? (userID.isNotEmpty ? int.parse(userID) : 0), orderType, amount,
            isCashOnDeliveryActive, digitalPaymentName, guestId: userID.isNotEmpty ? userID : AuthHelper.getGuestId(),
            contactNumber: contactNumber, createAccount: _isCreateAccount,
          ));
        }
      } else {
        double total = ((amount / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
        if(AuthHelper.isLoggedIn()) {
          Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
        }
        if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()){
          Get.offNamed(RouteHelper.getInitialRoute());
          Future.delayed(const Duration(seconds: 2) , () => Get.dialog(Center(child: SizedBox(height: 350, width : 500, child: OrderSuccessfulDialog(orderID: orderID)))));
        } else {
          Get.offNamed(RouteHelper.getOrderSuccessRoute(orderID, contactNumber, createAccount: _isCreateAccount));
        }
      }
      clearPrevData();
      Get.find<CouponController>().removeCouponData(false);
      updateTips(
        getSharedPrefDmTipIndex().isNotEmpty ? int.parse(getSharedPrefDmTipIndex()) : 0,
        notify: false,
      );
    }else {
      showCustomSnackBar(message);
    }
  }

  Future<void> paymentAfterDigitalCancel(PaymentModel paymentData, bool fromHome) async {
    Get.find<SplashController>().togglePaymentIncompleteBottomSheet(false);
    if(paymentMethodIndex == 0) {
      bool isSuccess = await Get.find<OrderController>().switchToCOD(paymentData.orderID, guestId: paymentData.guestId);
      if(isSuccess) {
        _redirection(paymentData, fromHome);
      }
    } else if(paymentMethodIndex == 1) {
      debugPrint('------wallet selected');
      bool isSuccess = await Get.find<OrderController>().switchToWalletPayment(paymentData.orderID);
      if(isSuccess) {
        _redirection(paymentData, fromHome);
      }
    } else if(paymentMethodIndex == 2) {
      if(GetPlatform.isWeb) {
        String? hostname = html.window.location.hostname;
        String protocol = html.window.location.protocol;
        String selectedUrl;
        selectedUrl = '${AppConstants.baseUrl}/payment-mobile?order_id=${paymentData.orderID}&&customer_id=${paymentData.userId ?? AuthHelper.getGuestId()}'
            '&payment_method=$digitalPaymentName&payment_platform=web&&callback=$protocol//$hostname${RouteHelper.orderSuccess}?id=${paymentData.orderID}&status=';

        html.window.open(selectedUrl,"_self");
      } else{
        Get.offNamed(RouteHelper.getPaymentRoute(
          paymentData.orderID!, Get.find<ProfileController>().userInfoModel?.id ?? 0, paymentData.orderType, paymentData.orderAmount!,
          paymentData.isCashOnDeliveryActive, digitalPaymentName, guestId: AuthHelper.getGuestId(),
          contactNumber: paymentData.contactNumber,
        ));
      }
    } else if(paymentMethodIndex == 3) {
      debugPrint('------offline selected');
      if(Get.isBottomSheetOpen!) {
        Get.back();
      }
      Get.toNamed(RouteHelper.getOfflinePaymentScreen(
        zoneId: paymentData.zoneId, total: paymentData.orderAmount!, orderId: paymentData.orderID!, contactNumber: paymentData.contactNumber??'',
        maxCodOrderAmount: paymentData.maxCodOrderAmount, fromCart: false, isCodActive: paymentData.isCashOnDeliveryActive, forParcel: paymentData.orderType == 'parcel',
      ));
    }
    clearPrevData();
    Get.find<CouponController>().removeCouponData(false);
  }

  void _redirection(PaymentModel paymentData, bool fromHome) {
    Get.find<SplashController>().savePaymentIncompleteSheetStatus(false);
    double total = ((paymentData.orderAmount! / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
    if(AuthHelper.isLoggedIn()) {
      Get.find<AuthController>().saveEarningPoint(total.toStringAsFixed(0));
    }
    if(Get.currentRoute.contains(RouteHelper.orderDetails)) {
      Get.back();
    } else if (ResponsiveHelper.isDesktop(Get.context) && AuthHelper.isLoggedIn()){
      if(fromHome && Get.isDialogOpen!) {
        Get.back();
      } else {
        Get.offNamed(RouteHelper.getInitialRoute());
        Future.delayed(const Duration(seconds: 2) , () => Get.dialog(Center(child: SizedBox(height: 350, width : 500, child: OrderSuccessfulDialog(orderID: paymentData.orderID)))));
      }
    } else {
      Get.offNamed(RouteHelper.getOrderSuccessRoute(paymentData.orderID!, paymentData.contactNumber, createAccount: _isCreateAccount));
    }
  }

  void toggleExpand() {
    _isExpand = !_isExpand;
    update();
  }

  void updateTimeSlot(int index) {
    _selectedTimeSlot = index;
    update();
  }

  void updateDateSlot(int index, int? interval) {
    _selectedDateSlot = index;
    if(_allTimeSlots != null) {
      validateSlot(_allTimeSlots!, index, interval);
    }
    update();
  }

  void validateSlot(List<TimeSlotModel> slots, int dateIndex, int? interval, {bool notify = true}) {
    _timeSlots = [];
    DateTime now = DateTime.now();
    if(Get.find<SplashController>().configModel!.moduleConfig!.module!.orderPlaceToScheduleInterval!) {
      now = now.add(Duration(minutes: interval!));
    }
    int day = 0;
    if(dateIndex == 0) {
      day = DateTime.now().weekday;
    }else {
      day = DateTime.now().add(const Duration(days: 1)).weekday;
    }
    if(day == 7) {
      day = 0;
    }
    for (var slot in slots) {
      if (day == slot.day && (dateIndex == 0 ? slot.endTime!.isAfter(now) : true)) {
        _timeSlots!.add(slot);
      }
    }
    if(notify) {
      update();
    }
  }

  void toggleCreateAccount({bool willUpdate = true}){
    _isCreateAccount = !_isCreateAccount;
    if(willUpdate) {
      update();
    }
  }

  Future<void> getOrderTax(PlaceOrderBodyModel placeOrderBody) async {
    Response response = await checkoutServiceInterface.getOrderTax(placeOrderBody);
    if(response.statusCode == 200) {
      _isFirstTime = false;
      _orderTax = double.tryParse(response.body['tax_amount'].toString()) ?? 0.0;
      _taxIncluded = response.body['tax_included'];
    } else {
      _isFirstTime = false;
      ApiChecker.checkApi(response);
    }
    update();
  }

  Future<void> getSurgePrice({required String zoneId, required String moduleId, required String dateTime, String? guestId}) async {
    SurgePriceModel? surgePriceModel = await checkoutServiceInterface.getSurgePrice(zoneId: zoneId, moduleId: moduleId, dateTime: dateTime, guestId: guestId);
    if(surgePriceModel != null) {
      _surgePrice = surgePriceModel;
    }
    update();
  }

  Future<void> insertAddresses(AddressModel? addressModel, {bool notify = false})async {
    _address = addressModel;

    String phone = '';
    String name = '';

    print('======addressModel: ${addressModel?.toJson()}');

    if(AuthHelper.isLoggedIn()) {
      if(Get.find<ProfileController>().userInfoModel == null) {
        await Get.find<ProfileController>().getUserInfo();
      }
      phone = Get.find<ProfileController>().userInfoModel!.phone ?? '';
      name ='${Get.find<ProfileController>().userInfoModel!.fName ?? ''} ${Get.find<ProfileController>().userInfoModel!.lName ?? ''}';
      print('======addressModel 2 : ${addressModel?.toJson()}');
    }

    try {

      String processPhone = (addressModel != null && addressModel.contactPersonNumber != null && addressModel.contactPersonNumber != 'null') ? addressModel.contactPersonNumber??'' : phone;

      PhoneNumber phoneNumber = PhoneNumber.parse(processPhone);
      countryDialCode = '+${phoneNumber.countryCode}';
      contactPersonNumberController.text = phoneNumber.international.substring(
        countryDialCode!.length,
      );
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
    contactPersonAddressController.text = _address?.address ?? '';
    contactPersonNameController.text = _address?.contactPersonName ?? name;
    streetNumberController.text = _address?.streetNumber ?? '';
    houseController.text = _address?.house ?? '';
    floorController.text = _address?.floor ?? '';
    print('======addressModel 3: ${addressModel?.toJson()}');
    if (notify) update();
  }
}
