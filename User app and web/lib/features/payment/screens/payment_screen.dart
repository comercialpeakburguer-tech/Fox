import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/wallet/widgets/fund_payment_dialog_widget.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel orderModel;
  final bool isCashOnDelivery;
  final String? addFundUrl;
  final String paymentMethod;
  final String guestId;
  final String contactNumber;
  final String? subscriptionUrl;
  final int? storeId;
  final bool createAccount;
  final int? createUserId;

  const PaymentScreen({
    super.key,
    required this.orderModel,
    required this.isCashOnDelivery,
    this.addFundUrl,
    required this.paymentMethod,
    required this.guestId,
    required this.contactNumber,
    this.storeId,
    this.subscriptionUrl,
    this.createAccount = false,
    this.createUserId,
  });

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  late final String selectedUrl;
  bool _isLoading = true;
  bool _canRedirect = true;
  double _progress = 0;
  double? _maximumCodOrderAmount;
  PullToRefreshController? pullToRefreshController;
  InAppWebViewController? webViewController;
  final GlobalKey webViewKey = GlobalKey();

  static const Color _foxOrange = Color(0xFFFF6A00);
  static const Color _foxRed = Color(0xFFFF3B30);
  static const Color _foxDark = Color(0xFF0F1621);
  static const Color _foxDarkCard = Color(0xFF1A212C);
  static const Color _foxCream = Color(0xFFFFF6F0);

  @override
  void initState() {
    super.initState();

    final bool hasAddFund = widget.addFundUrl != null && widget.addFundUrl!.isNotEmpty;
    final bool hasSubscription = widget.subscriptionUrl != null && widget.subscriptionUrl!.isNotEmpty;

    if (!hasAddFund && !hasSubscription) {
      selectedUrl = '${AppConstants.baseUrl}/payment-mobile?customer_id=${widget.orderModel.userId == 0 ? widget.guestId : widget.orderModel.userId}&order_id=${widget.orderModel.id}&payment_method=${widget.paymentMethod}';
    } else if (hasSubscription) {
      selectedUrl = widget.subscriptionUrl!;
    } else {
      selectedUrl = widget.addFundUrl!;
    }

    if (kDebugMode) {
      print('==========url=======> $selectedUrl');
    }

    _initData();
  }

  void _initData() async {
    final bool hasAddFund = widget.addFundUrl != null && widget.addFundUrl!.isNotEmpty;
    final bool hasSubscription = widget.subscriptionUrl != null && widget.subscriptionUrl!.isNotEmpty;

    if(!hasAddFund && !hasSubscription && AddressHelper.getUserAddressFromSharedPref()?.zoneData != null) {
      for(ZoneData zData in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
        for(Modules m in zData.modules!) {
          if(m.id == Get.find<SplashController>().module?.id) {
            _maximumCodOrderAmount = m.pivot!.maximumCodOrderAmount;
            break;
          }
        }
      }
    }

    pullToRefreshController = GetPlatform.isWeb || ![TargetPlatform.iOS, TargetPlatform.android].contains(defaultTargetPlatform) ? null : PullToRefreshController(
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );

    if(GetPlatform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitApp().then((value) => value!);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? _foxDark : _foxCream,
        appBar: CustomAppBar(title: 'payment'.tr, onBackPressed: () => _exitApp()),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? _foxDarkCard : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _foxOrange.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        InAppWebView(
                          key: webViewKey,
                          initialUrlRequest: URLRequest(url: WebUri(selectedUrl)),
                          initialUserScripts: UnmodifiableListView<UserScript>([]),
                          pullToRefreshController: pullToRefreshController,
                          initialSettings: InAppWebViewSettings(
                            isInspectable: kDebugMode,
                            useShouldOverrideUrlLoading: true,
                            useOnLoadResource: true,
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            iframeAllow: 'camera; microphone; payment',
                            iframeAllowFullscreen: true,
                            javaScriptEnabled: true,
                            transparentBackground: false,
                            supportMultipleWindows: false,
                          ),
                          onWebViewCreated: (controller) async {
                            webViewController = controller;
                          },
                          onLoadStart: (controller, url) async {
                            _handlePaymentRedirect(url?.toString() ?? '');
                            if(mounted) {
                              setState(() => _isLoading = true);
                            }
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            final Uri? uri = navigationAction.request.url;
                            if(uri == null) {
                              return NavigationActionPolicy.ALLOW;
                            }

                            if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                              showCustomSnackBar('O pagamento deve ser concluído dentro do Fox GO.', isError: false);
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStop: (controller, url) async {
                            pullToRefreshController?.endRefreshing();
                            _handlePaymentRedirect(url?.toString() ?? '');
                            if(mounted) {
                              setState(() => _isLoading = false);
                            }
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              pullToRefreshController?.endRefreshing();
                            }
                            if(mounted) {
                              setState(() => _progress = progress / 100);
                            }
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            if (kDebugMode) {
                              debugPrint(consoleMessage.message);
                            }
                          },
                        ),

                        if(_progress > 0 && _progress < 1)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 3,
                              valueColor: const AlwaysStoppedAnimation<Color>(_foxOrange),
                              backgroundColor: _foxOrange.withValues(alpha: 0.12),
                            ),
                          ),

                        if(_isLoading)
                          Container(
                            color: (isDark ? _foxDark : Colors.white).withValues(alpha: 0.78),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [_foxOrange, _foxRed],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [BoxShadow(color: _foxOrange.withValues(alpha: 0.35), blurRadius: 20)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Processando pagamento...',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePaymentRedirect(String url) {
    if(url.isEmpty || !_canRedirect) {
      return;
    }

    Get.find<OrderController>().paymentRedirect(
      url: url,
      canRedirect: _canRedirect,
      onClose: () => _canRedirect = false,
      addFundUrl: widget.addFundUrl,
      orderID: widget.orderModel.id.toString(),
      contactNumber: widget.contactNumber,
      storeId: widget.storeId,
      subscriptionUrl: widget.subscriptionUrl,
      createAccount: widget.createAccount,
      guestId: widget.createAccount ? (widget.createUserId?.toString() ?? widget.guestId) : widget.guestId,
    );
  }

  Future<bool?> _exitApp() async {
    final bool hasAddFund = widget.addFundUrl != null && widget.addFundUrl!.isNotEmpty;
    final bool hasSubscription = widget.subscriptionUrl != null && widget.subscriptionUrl!.isNotEmpty;

    if(!hasAddFund && !hasSubscription){
      return Get.dialog(PaymentFailedDialog(
        orderID: widget.orderModel.id.toString(),
        orderAmount: widget.orderModel.orderAmount,
        maxCodOrderAmount: _maximumCodOrderAmount,
        orderType: widget.orderModel.orderType,
        isCashOnDelivery: widget.isCashOnDelivery,
        guestId: widget.createAccount ? widget.createUserId.toString() : widget.guestId,
      ));
    } else{
      return Get.dialog(FundPaymentDialogWidget(isSubscription: hasSubscription));
    }
  }
}
