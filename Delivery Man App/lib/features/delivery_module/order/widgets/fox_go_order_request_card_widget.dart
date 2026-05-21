import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/common/widgets/confirmation_dialog_widget.dart';
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
import 'package:sixam_mart_delivery/util/images.dart';
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

    return Container(
      margin: EdgeInsets.only(bottom: widget.compact ? 0 : Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF17A34A).withValues(alpha: 0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF062E1C), Color(0xFF0E7A3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                  child: Text('FOX GO', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                ),
                const Spacer(),
                Text('#${widget.orderModel.id ?? '-'}', style: robotoMedium.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeSmall)),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                _isFoodOrder ? 'Nova entrega de comida' : 'Nova entrega disponível',
                style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(_moduleLabel(), style: robotoRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeSmall)),
              if(_remaining.inSeconds > 0) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('Expira em: ${_remaining.inSeconds}s', style: robotoBold.copyWith(color: const Color(0xFFFFE066), fontSize: Dimensions.fontSizeSmall)),
              ] else ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('Chamada expirada', style: robotoBold.copyWith(color: Colors.redAccent.shade100, fontSize: Dimensions.fontSizeSmall)),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if(_isFoodOrder) _buildFoodItems(context),
              if(_isFoodOrder) const SizedBox(height: Dimensions.paddingSizeSmall),
              _infoRow(context, Icons.storefront_outlined, _isParcel ? 'Origem' : 'Loja / origem', _originName()),
              _infoRow(context, Icons.shopping_bag_outlined, 'Retirada', _pickupAddress()),
              _infoRow(context, Icons.location_on_outlined, 'Destino', _destinationAddress()),
              Row(children: [
                Expanded(child: _metricBox(context, 'Distância', '${distance > 1000 ? '1000+' : distance.toStringAsFixed(2)} km')),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(child: _metricBox(context, 'Pagamento', payment)),
              ]),
              if(showAmount) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _metricBox(
                  context,
                  'Você recebe',
                  PriceConverterHelper.convertPrice(_earningAmount()),
                  highlight: true,
                ),
              ],
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isIgnoring || _isAccepting || _remaining.inSeconds <= 0) ? null : () => _confirmIgnore(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: BorderSide(color: theme.disabledColor.withValues(alpha: 0.55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                    ),
                    child: Text('Recusar / Ignorar', textAlign: TextAlign.center, style: robotoMedium.copyWith(color: theme.textTheme.bodyLarge?.color)),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: CustomButtonWidget(
                    height: 46,
                    radius: Dimensions.radiusDefault,
                    buttonText: _isAccepting ? 'Aguarde...' : (_remaining.inSeconds <= 0 ? 'Expirada' : 'Aceitar pedido'),
                    fontSize: Dimensions.fontSizeDefault,
                    onPressed: (_isAccepting || _isIgnoring || _remaining.inSeconds <= 0) ? null : () => _confirmAccept(context),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
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
        Text('Itens comprados', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ...details.asMap().entries.map((entry) {
          final item = entry.value;
          final name = item.itemDetails?.name?.trim().isNotEmpty == true ? item.itemDetails!.name!.trim() : 'Item do pedido';
          return Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Text('Item ${entry.key + 1}: $name (x${item.quantity ?? 1})', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
          );
        }),
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

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: const Color(0xFF17A34A)),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
          const SizedBox(height: 2),
          Text(value.isNotEmpty ? value : 'A confirmar', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
        ])),
      ]),
    );
  }

  Widget _metricBox(BuildContext context, String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF17A34A).withValues(alpha: 0.14) : Theme.of(context).disabledColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        const SizedBox(height: 3),
        Text(value.isNotEmpty ? value : 'A confirmar', maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ]),
    );
  }

  void _confirmIgnore(BuildContext context) {
    Get.dialog(ConfirmationDialogWidget(
      icon: Images.warning,
      title: 'are_you_sure_to_ignore'.tr,
      description: _isParcel ? 'you_want_to_ignore_this_delivery'.tr : 'you_want_to_ignore_this_order'.tr,
      onYesPressed: () async {
        if(_isIgnoring || _isAccepting) return;
        setState(() => _isIgnoring = true);
        Get.back();
        Get.find<OrderController>().ignoreOrder(widget.index);
        if(mounted) setState(() => _isIgnoring = false);
      },
    ), barrierDismissible: false);
  }

  void _confirmAccept(BuildContext context) {
    final orderController = Get.find<OrderController>();
    Get.dialog(ConfirmationDialogWidget(
      icon: Images.warning,
      title: 'are_you_sure_to_accept'.tr,
      description: _isParcel ? 'you_want_to_accept_this_delivery'.tr : 'you_want_to_accept_this_order'.tr,
      onYesPressed: () {
        if(_isAccepting || _remaining.inSeconds <= 0) return;
        setState(() => _isAccepting = true);
        orderController.acceptOrder(widget.orderModel.id, widget.index, widget.orderModel).then((isSuccess) {
          if(isSuccess) {
            widget.orderModel.orderStatus = (widget.orderModel.orderStatus == 'pending' || widget.orderModel.orderStatus == 'confirmed') ? 'accepted' : widget.orderModel.orderStatus;
            if(widget.compact) {
              widget.onTap();
            }
            Get.dialog(FoxGoAcceptedOrderCardWidget(orderModel: widget.orderModel), barrierDismissible: false);
          } else {
            orderController.getLatestOrders();
          }
        }).whenComplete(() { if(mounted) setState(() => _isAccepting = false); });
      },
    ), barrierDismissible: false);
  }

  double _distanceFromDeliveryMan() {
    final lat = double.tryParse(_isParcel ? widget.orderModel.deliveryAddress?.latitude ?? '0' : widget.orderModel.storeLat ?? '0') ?? 0;
    final lng = double.tryParse(_isParcel ? widget.orderModel.deliveryAddress?.longitude ?? '0' : widget.orderModel.storeLng ?? '0') ?? 0;
    return Get.find<AddressController>().getRestaurantDistance(LatLng(lat, lng));
  }

  double _earningAmount() {
    return ((widget.orderModel.originalDeliveryCharge ?? 0) + (widget.orderModel.dmTips ?? 0)).toDouble();
  }

  String _moduleLabel() {
    if(_isFoodOrder) return 'Food / comida / restaurante';
    if(_isParcel) return 'Entrega / encomenda';
    final module = widget.orderModel.moduleType?.trim();
    return module != null && module.isNotEmpty ? module : 'Entrega';
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

    _ttlTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if(!mounted) return;
      setState(() {
        if(_remaining.inSeconds <= 0) {
          _remaining = Duration.zero;
          timer.cancel();
        } else {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        }
      });
    });
  }

  DateTime? _resolveExpiry() {
    final dynamic expiresAt = widget.orderModel.toJson()['expires_at'];
    if(expiresAt != null) {
      final parsed = DateTime.tryParse(expiresAt.toString());
      if(parsed != null) return parsed.toLocal();
    }
    final dynamic ttlRaw = widget.orderModel.toJson()['ttl_seconds'];
    final ttl = int.tryParse((ttlRaw ?? '').toString());
    if(ttl != null && ttl > 0) return DateTime.now().add(Duration(seconds: ttl));
    return null;
  }

}
