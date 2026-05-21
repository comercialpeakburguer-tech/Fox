import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_details_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/fox_go_accepted_order_card_widget.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoOrderRequestCardWidget extends StatefulWidget {
  final OrderModel orderModel;
  final int index;
  final Function onTap;
  final bool compact;

  const FoxGoOrderRequestCardWidget({
    super.key,
    required this.orderModel,
    required this.index,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<FoxGoOrderRequestCardWidget> createState() => _FoxGoOrderRequestCardWidgetState();
}

class _FoxGoOrderRequestCardWidgetState extends State<FoxGoOrderRequestCardWidget> {
  List<OrderDetailsModel>? _orderDetails;
  bool _loadingDetails = false;
  bool _isAccepting = false;
  bool _isIgnoring = false;
  bool _expiredHandled = false;
  Timer? _ttlTimer;
  Duration _remaining = Duration.zero;

  bool get _isFoodOrder {
    final raw = [
      widget.orderModel.moduleType,
      widget.orderModel.orderType,
      widget.orderModel.storeBusinessModel,
    ].where((value) => value != null).join('|').toLowerCase();

    if(raw.contains('parcel') || raw.contains('pharmacy') || raw.contains('grocery') || raw.contains('market') || raw.contains('ride') || raw.contains('taxi')) {
      return false;
    }

    return raw.isEmpty || raw.contains('food') || raw.contains('restaurant') || raw.contains('comida');
  }

  bool get _isParcel => widget.orderModel.orderType == 'parcel';

  int get _routeStopCount {
    final detailsCount = widget.orderModel.detailsCount ?? 0;
    final baseStops = _isParcel ? 2 : 2;
    return math.max(baseStops, detailsCount > 1 ? detailsCount : baseStops);
  }

  bool get _isGroupedRoute => (widget.orderModel.detailsCount ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    _initCountdown();
    if(_isFoodOrder && !_isParcel) {
      _loadFoodItems();
    }
  }

  @override
  void didUpdateWidget(covariant FoxGoOrderRequestCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.orderModel.id != widget.orderModel.id) {
      _ttlTimer?.cancel();
      _expiredHandled = false;
      _initCountdown();
    }
    if(oldWidget.orderModel.id != widget.orderModel.id && _isFoodOrder && !_isParcel) {
      _orderDetails = null;
      _loadFoodItems();
    }
  }

  @override
  void dispose() {
    _ttlTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFoodItems() async {
    if(_loadingDetails || widget.orderModel.id == null) return;
    _loadingDetails = true;
    try {
      final details = await Get.find<OrderController>().orderServiceInterface.getOrderDetails(widget.orderModel.id);
      if(!mounted) return;
      setState(() {
        _orderDetails = details;
        _loadingDetails = false;
      });
    } catch (_) {
      if(!mounted) return;
      setState(() {
        _orderDetails = [];
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = Get.find<SplashController>().configModel;
    final bool isRideActive = AppConstants.appMode == AppMode.ride;
    final bool showEarning = isRideActive ? (config?.showRiderEarning ?? false) : (config?.showDmEarning ?? false);
    final double distance = _distanceFromDeliveryMan();
    final String payment = _paymentLabel();
    final bool showAmount = showEarning && Get.find<ProfileController>().profileModel != null && Get.find<ProfileController>().profileModel!.earnings == 1;
    final String receiveValue = PriceConverterHelper.convertPrice(_earningAmount());
    final bool expired = _remaining.inSeconds <= 0;

    return AnimatedOpacity(
      opacity: expired ? 0.72 : 1,
      duration: const Duration(milliseconds: 220),
      child: Container(
        margin: EdgeInsets.only(bottom: widget.compact ? 0 : Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: expired ? const Color(0xFFF2F2F2) : const Color(0xFFFFF7A6),
                border: Border(left: BorderSide(color: expired ? const Color(0xFFE6003E) : Theme.of(context).primaryColor, width: 7)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.room_service_rounded, size: 17, color: Colors.black87),
                      const SizedBox(width: 7),
                      Text('${_moduleTitle()}${_isGroupedRoute ? ' (${widget.orderModel.detailsCount})' : ''}', style: robotoBold.copyWith(color: Colors.black87, fontSize: Dimensions.fontSizeSmall)),
                    ]),
                  ),
                  const Spacer(),
                  _timerChip(),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(receiveValue, style: robotoBold.copyWith(fontSize: 42, color: Colors.black, height: 1)),
                const SizedBox(height: 8),
                Text(expired ? 'Oferta expirada' : 'Você recebe', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black54)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: _metricLine(Icons.route_rounded, 'Distância total', '${distance > 1000 ? '1000+' : distance.toStringAsFixed(1)} km')),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(child: _metricLine(Icons.payments_rounded, 'Pagamento', payment)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _routeTimeline(),
                if(_isFoodOrder) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _buildFoodItems(context),
                ],
                if(expired) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _expiredNotice(),
                ],
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (_isIgnoring || _isAccepting || expired) ? null : () => _showDecisionOverlay(accept: false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: Color(0xFFE6003E), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Recusar', textAlign: TextAlign.center, style: robotoBold.copyWith(color: const Color(0xFFE6003E), fontSize: Dimensions.fontSizeDefault)),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: CustomButtonWidget(
                      height: 52,
                      radius: 16,
                      buttonText: _isAccepting ? 'Aguarde...' : (expired ? 'Expirada' : _isGroupedRoute ? 'Aceitar (${widget.orderModel.detailsCount})' : 'Aceitar'),
                      fontSize: Dimensions.fontSizeDefault,
                      onPressed: (_isAccepting || _isIgnoring || expired) ? null : () => _showDecisionOverlay(accept: true),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _expiredNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF0F3), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.timer_off_rounded, color: Color(0xFFE6003E), size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text('O tempo dessa chamada acabou. Ela será removida da lista automaticamente.', style: robotoMedium.copyWith(color: const Color(0xFFE6003E), fontSize: Dimensions.fontSizeSmall))),
      ]),
    );
  }

  Widget _timerChip() {
    final expired = _remaining.inSeconds <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: expired ? const Color(0xFFE6003E) : Colors.black.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(expired ? Icons.timer_off_rounded : Icons.timer_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(expired ? 'Expirada' : '${_remaining.inSeconds}s', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
      ]),
    );
  }

  Widget _metricLine(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: Colors.black87, size: 22),
      const SizedBox(width: 8),
      Expanded(child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(style: robotoRegular.copyWith(color: Colors.black87, fontSize: Dimensions.fontSizeDefault), children: [
          TextSpan(text: '$label ', style: robotoRegular.copyWith(color: Colors.black54)),
          TextSpan(text: value, style: robotoBold.copyWith(color: Colors.black87)),
        ]),
      )),
    ]);
  }

  Widget _routeTimeline() {
    final points = <_RoutePoint>[
      _RoutePoint(color: const Color(0xFFFFD400), title: _originName(), subtitle: _pickupAddress()),
      _RoutePoint(color: const Color(0xFFFF6A2A), title: _isParcel ? 'Destinatário' : 'Cliente', subtitle: _destinationAddress()),
    ];

    return Column(children: [
      for(int index = 0; index < points.length; index++)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: points[index].color, shape: BoxShape.circle)),
            if(index != points.length - 1) Container(width: 2, height: 42, color: const Color(0xFFBDBDBD)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: index == points.length - 1 ? 0 : 15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(points[index].title.isNotEmpty ? points[index].title : 'Local a confirmar', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black)),
              const SizedBox(height: 4),
              Text(points[index].subtitle.isNotEmpty ? points[index].subtitle : 'Endereço a confirmar', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black54)),
            ]),
          )),
        ]),
    ]);
  }

  Widget _buildFoodItems(BuildContext context) {
    if(_loadingDetails && _orderDetails == null) {
      return _panel(context, child: Row(children: [
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text('Carregando itens do pedido...', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ]));
    }

    final details = _orderDetails ?? [];
    if(details.isEmpty) {
      return _panel(
        context,
        child: Text('${widget.orderModel.detailsCount ?? 0} ${((widget.orderModel.detailsCount ?? 0) == 1) ? 'item' : 'itens'} no pedido', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
      );
    }

    return _panel(
      context,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Itens do pedido', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ...details.take(4).toList().asMap().entries.map((entry) {
          final item = entry.value;
          final name = item.itemDetails?.name?.trim().isNotEmpty == true ? item.itemDetails!.name!.trim() : 'Item do pedido';
          return Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Text('• $name (x${item.quantity ?? 1})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
          );
        }),
        if(details.length > 4) Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
          child: Text('+ ${details.length - 4} itens', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ),
      ]),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: const Color(0xFF17A34A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: child,
    );
  }

  void _showDecisionOverlay({required bool accept}) {
    if(_remaining.inSeconds <= 0) return;
    Get.dialog(
      _RouteDecisionOverlay(
        accept: accept,
        amount: PriceConverterHelper.convertPrice(_earningAmount()),
        distance: '${_distanceFromDeliveryMan() > 1000 ? '1000+' : _distanceFromDeliveryMan().toStringAsFixed(2)} km',
        stops: _routeStopCount,
        initialSeconds: _remaining.inSeconds,
        onConfirm: () => accept ? _acceptOrder() : _rejectOrder(),
        onExpired: _handleExpiredOffer,
      ),
      barrierDismissible: false,
      useSafeArea: false,
    );
  }

  Future<void> _rejectOrder() async {
    if(_isIgnoring || _isAccepting || _remaining.inSeconds <= 0) return;
    setState(() => _isIgnoring = true);
    Get.find<OrderController>().ignoreOrderById(widget.orderModel.id);
    if(widget.compact) {
      widget.onTap();
    }
    if(Get.isDialogOpen == true) {
      Get.back();
    }
    if(mounted) setState(() => _isIgnoring = false);
  }

  Future<void> _acceptOrder() async {
    if(_isAccepting || _remaining.inSeconds <= 0) return;
    setState(() => _isAccepting = true);
    final orderController = Get.find<OrderController>();
    final int index = orderController.latestOrderList?.indexWhere((order) => order.id == widget.orderModel.id) ?? widget.index;
    final isSuccess = await orderController.acceptOrder(widget.orderModel.id, index, widget.orderModel);
    if(Get.isDialogOpen == true) {
      Get.back();
    }
    if(isSuccess) {
      widget.orderModel.orderStatus = (widget.orderModel.orderStatus == 'pending' || widget.orderModel.orderStatus == 'confirmed') ? 'accepted' : widget.orderModel.orderStatus;
      if(widget.compact) {
        widget.onTap();
      }
      if(Get.isDialogOpen != true) {
        Get.dialog(FoxGoAcceptedOrderCardWidget(orderModel: widget.orderModel), barrierDismissible: false);
      }
    } else {
      orderController.getLatestOrders(routeCall: false);
    }
    if(mounted) setState(() => _isAccepting = false);
  }

  void _handleExpiredOffer() {
    if(_expiredHandled) return;
    _expiredHandled = true;
    final orderController = Get.find<OrderController>();
    orderController.ignoreOrderById(widget.orderModel.id);
    if(widget.compact && Get.isDialogOpen == true) {
      Get.back();
    }
  }

  double _distanceFromDeliveryMan() {
    final lat = double.tryParse(_isParcel ? widget.orderModel.deliveryAddress?.latitude ?? '0' : widget.orderModel.storeLat ?? '0') ?? 0;
    final lng = double.tryParse(_isParcel ? widget.orderModel.deliveryAddress?.longitude ?? '0' : widget.orderModel.storeLng ?? '0') ?? 0;
    return Get.find<AddressController>().getRestaurantDistance(LatLng(lat, lng));
  }

  double _earningAmount() {
    final amount = ((widget.orderModel.originalDeliveryCharge ?? 0) + (widget.orderModel.dmTips ?? 0)).toDouble();
    return amount > 0 ? amount : ((widget.orderModel.deliveryCharge ?? 0) + (widget.orderModel.dmTips ?? 0)).toDouble();
  }

  String _moduleTitle() {
    if(_isFoodOrder) return 'Entrega Food';
    if(_isParcel) return 'Entrega Encomenda';
    final module = widget.orderModel.moduleType?.toLowerCase() ?? '';
    if(module.contains('pharmacy')) return 'Entrega Farmácia';
    if(module.contains('grocery') || module.contains('market')) return 'Entrega Mercado';
    return 'Entrega';
  }

  String _originName() {
    if(_isParcel) return widget.orderModel.parcelCategory?.name ?? 'Origem do pacote';
    return widget.orderModel.storeName ?? 'Loja';
  }

  String _pickupAddress() {
    if(_isParcel) return widget.orderModel.deliveryAddress?.address ?? '';
    return widget.orderModel.storeAddress ?? '';
  }

  String _destinationAddress() {
    if(_isParcel) return widget.orderModel.receiverDetails?.address ?? '';
    return widget.orderModel.deliveryAddress?.address ?? '';
  }

  String _paymentLabel() {
    switch (widget.orderModel.paymentMethod) {
      case 'cash_on_delivery':
        return 'cod'.tr;
      case 'wallet':
        return 'wallet'.tr;
      default:
        return 'digitally_paid'.tr;
    }
  }

  void _initCountdown() {
    final expiry = _resolveExpiry();
    if(expiry == null) {
      _remaining = const Duration(seconds: 45);
    } else {
      _remaining = expiry.difference(DateTime.now());
      if(_remaining.isNegative) _remaining = Duration.zero;
    }

    if(_remaining.inSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleExpiredOffer());
      return;
    }

    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if(!mounted) return;
      setState(() {
        if(_remaining.inSeconds <= 1) {
          _remaining = Duration.zero;
          timer.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleExpiredOffer());
        } else {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        }
      });
    });
  }

  DateTime? _resolveExpiry() {
    final json = widget.orderModel.toJson();
    final dynamic expiresAt = json['expires_at'] ?? json['expiresAt'] ?? json['offer_expires_at'];
    if(expiresAt != null) {
      final parsed = DateTime.tryParse(expiresAt.toString());
      if(parsed != null) return parsed.toLocal();
    }
    final dynamic ttlRaw = json['ttl_seconds'] ?? json['ttlSeconds'] ?? json['timeout'] ?? json['offer_timeout'];
    final ttl = int.tryParse((ttlRaw ?? '').toString());
    if(ttl != null && ttl > 0) return DateTime.now().add(Duration(seconds: ttl));
    return null;
  }
}

class _RouteDecisionOverlay extends StatefulWidget {
  const _RouteDecisionOverlay({
    required this.accept,
    required this.amount,
    required this.distance,
    required this.stops,
    required this.initialSeconds,
    required this.onConfirm,
    required this.onExpired,
  });

  final bool accept;
  final String amount;
  final String distance;
  final int stops;
  final int initialSeconds;
  final Future<void> Function() onConfirm;
  final VoidCallback onExpired;

  @override
  State<_RouteDecisionOverlay> createState() => _RouteDecisionOverlayState();
}

class _RouteDecisionOverlayState extends State<_RouteDecisionOverlay> {
  Timer? _timer;
  late int _seconds;
  bool _loading = false;
  bool _expiredCalled = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds > 0 ? widget.initialSeconds : 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if(!mounted) return;
      if(_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
        _expireAndClose();
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _expireAndClose() {
    if(_expiredCalled) return;
    _expiredCalled = true;
    widget.onExpired();
    Future.delayed(const Duration(milliseconds: 260), () {
      if(Get.isDialogOpen == true) {
        Get.back();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color actionColor = widget.accept ? const Color(0xFF006B2B) : const Color(0xFFE6003E);
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      child: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width - 32,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 34),
            decoration: BoxDecoration(color: actionColor, borderRadius: BorderRadius.circular(28)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 118,
                height: 118,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: CircularProgressIndicator(
                      value: widget.initialSeconds <= 0 ? 0 : (_seconds / widget.initialSeconds).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: Colors.black.withValues(alpha: 0.16),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text('$_seconds', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(height: 52),
              Text(_seconds <= 0 ? 'Tempo esgotado' : (widget.accept ? 'Aceitar a rota?' : 'Rejeitar a rota?'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 38, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 28),
              Text(widget.amount, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              const SizedBox(height: 22),
              Text('${widget.distance} • 30 min • ${widget.stops} paradas', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 1.0)),
              const SizedBox(height: 120),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: actionColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: (_loading || _seconds <= 0) ? null : () async {
                    setState(() => _loading = true);
                    await widget.onConfirm();
                    if(mounted) setState(() => _loading = false);
                  },
                  child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.accept ? 'Aceito' : 'Rejeitar', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _loading ? null : () => Get.back(),
                  child: const Text('Voltar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RoutePoint {
  final Color color;
  final String title;
  final String subtitle;

  const _RoutePoint({required this.color, required this.title, required this.subtitle});
}
