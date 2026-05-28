import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/address/controllers/address_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/screens/order_details_screen.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart_delivery/features/support/widgets/foxgo_support_center_sheet.dart';
import 'package:sixam_mart_delivery/helper/price_converter_helper.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/enums.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoAcceptedOrderCardWidget extends StatelessWidget {
  final OrderModel orderModel;

  const FoxGoAcceptedOrderCardWidget({super.key, required this.orderModel});

  String get _rawType => [
    orderModel.moduleType,
    orderModel.orderType,
    orderModel.storeBusinessModel,
    _jsonString('module_type'),
    _jsonString('order_type'),
    _jsonString('type'),
  ].where((value) => value != null && value.toString().trim().isNotEmpty).join('|').toLowerCase();

  bool get _isRide => _rawType.contains('ride') || _rawType.contains('taxi') || _rawType.contains('corrida') || AppConstants.appMode == AppMode.ride;
  bool get _isParcel => orderModel.orderType == 'parcel' || _rawType.contains('parcel') || _rawType.contains('encomenda');

  bool get _isFoodOrder {
    final raw = _rawType;
    if(raw.contains('parcel') || raw.contains('pharmacy') || raw.contains('grocery') || raw.contains('market') || raw.contains('ride') || raw.contains('taxi') || raw.contains('corrida')) {
      return false;
    }
    return raw.isEmpty || raw.contains('food') || raw.contains('restaurant') || raw.contains('comida');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = Get.find<SplashController>().configModel;
    final bool showEarning = _isRide ? (config?.showRiderEarning ?? true) : (config?.showDmEarning ?? false);
    final bool showAmount = showEarning && Get.find<ProfileController>().profileModel != null && Get.find<ProfileController>().profileModel!.earnings == 1;
    final double distance = _distanceFromDeliveryMan();
    final Color accent = _isRide ? const Color(0xFF0B7CFF) : const Color(0xFF17A34A);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRide ? const [Color(0xFF06274F), Color(0xFF0B7CFF)] : const [Color(0xFF062E1C), Color(0xFF0E7A3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                    child: Text(_isRide ? 'FOX GO CORRIDA' : 'FOX GO', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                  ),
                  const Spacer(),
                  Text('#${orderModel.id ?? '-'}', style: robotoMedium.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeSmall)),
                ]),
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                    child: Icon(_isRide ? Icons.local_taxi_rounded : Icons.check_circle_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_isRide ? 'Corrida aceita' : 'Pedido aceito', style: robotoBold.copyWith(color: Colors.white, fontSize: 26, height: 1.0)),
                    const SizedBox(height: 6),
                    Text(_operationSubtitle(), style: robotoRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeDefault)),
                  ])),
                ]),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _statusPanel(context),
                  if(_isRide) ...[
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    _rideSafetyPanel(context),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _infoRow(context, _isRide ? Icons.local_taxi_outlined : Icons.category_outlined, 'Tipo', _moduleLabel()),
                  _infoRow(context, _isRide ? Icons.person_pin_circle_outlined : Icons.storefront_outlined, _isRide ? 'Embarque' : (_isParcel ? 'Origem / local de retirada' : 'Origem / loja'), _originName()),
                  _infoRow(context, Icons.my_location_rounded, _isRide ? 'Endereço de embarque' : 'Endereço de retirada', _pickupAddress()),
                  _infoRow(context, Icons.location_on_outlined, _isRide ? 'Destino da corrida' : (_isParcel ? 'Destino' : 'Endereço de entrega / destino'), _destinationAddress()),
                  Row(children: [
                    Expanded(child: _metricBox(context, _isRide ? 'Distância corrida' : 'Distância', '${distance > 1000 ? '1000+' : distance.toStringAsFixed(2)} km')),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(child: _metricBox(context, 'Pagamento', _paymentLabel())),
                  ]),
                  if(showAmount) ...[
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _metricBox(context, _isRide ? 'Valor estimado' : 'Você recebe', PriceConverterHelper.convertPrice(_earningAmount()), highlight: true),
                  ],
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  CustomButtonWidget(
                    height: 52,
                    radius: 16,
                    buttonText: _primaryActionLabel(),
                    fontSize: Dimensions.fontSizeDefault,
                    onPressed: () => _openExistingOrderFlow(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if(Get.isDialogOpen == true) {
                            Get.back();
                          }
                          FoxGoSupportCenterSheet.show(orderId: orderModel.id, initialReason: _isRide ? 'Ajuda após aceitar corrida' : 'Ajuda após aceite do pedido');
                        },
                        icon: Icon(_isRide ? Icons.shield_rounded : Icons.support_agent_rounded, size: 20),
                        label: Text(_isRide ? 'Segurança / Ajuda' : 'Ajuda'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if(Get.isDialogOpen == true) {
                            Get.back();
                          }
                        },
                        child: Text('Continuar aqui', style: robotoMedium.copyWith(color: theme.disabledColor)),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statusPanel(BuildContext context) {
    final accent = _isRide ? const Color(0xFF0B7CFF) : const Color(0xFF0E7A3D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (_isRide ? const Color(0xFF0B7CFF) : const Color(0xFF17A34A)).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Icon(_isRide ? Icons.navigation_rounded : Icons.route_rounded, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_nextStepTitle(), style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black)),
          const SizedBox(height: 4),
          Text(_isRide ? 'Siga até o ponto de embarque, confirme o passageiro e mantenha o GPS ativo.' : 'Siga para a próxima etapa e mantenha o GPS ativo.', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF666666))),
        ])),
      ]),
    );
  }

  Widget _rideSafetyPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD400).withValues(alpha: 0.55)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.health_and_safety_rounded, color: Colors.black, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('Segurança ativa: em caso de risco, use a Central Fox GO/SOS quando disponível no fluxo da corrida. Não finalize a corrida fora do destino.', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.black87, height: 1.35))),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: _isRide ? const Color(0xFF0B7CFF) : const Color(0xFF17A34A)),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: highlight ? (_isRide ? const Color(0xFF0B7CFF).withValues(alpha: 0.12) : const Color(0xFF17A34A).withValues(alpha: 0.14)) : Theme.of(context).disabledColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        const SizedBox(height: 3),
        Text(value.isNotEmpty ? value : 'A confirmar', maxLines: 2, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ]),
    );
  }

  void _openExistingOrderFlow() {
    if(Get.isDialogOpen == true) {
      Get.back();
    }
    final orderController = Get.find<OrderController>();
    final int orderIndex = orderController.currentOrderList?.indexWhere((order) => order.id == orderModel.id) ?? -1;
    Get.toNamed(
      RouteHelper.getOrderDetailsRoute(orderModel.id),
      arguments: OrderDetailsScreen(orderId: orderModel.id, isRunningOrder: true, orderIndex: orderIndex < 0 ? 0 : orderIndex),
    );
  }

  double _distanceFromDeliveryMan() {
    final jsonDistance = _jsonDouble('distance') ?? _jsonDouble('distance_km') ?? _jsonDouble('total_distance') ?? _jsonDouble('totalDistanceKm');
    if(_isRide && jsonDistance != null && jsonDistance > 0) return jsonDistance;
    final lat = double.tryParse(_isParcel ? orderModel.deliveryAddress?.latitude ?? '0' : (_isRide ? _pickupLat() : orderModel.storeLat ?? '0')) ?? 0;
    final lng = double.tryParse(_isParcel ? orderModel.deliveryAddress?.longitude ?? '0' : (_isRide ? _pickupLng() : orderModel.storeLng ?? '0')) ?? 0;
    if(lat == 0 || lng == 0) return jsonDistance ?? 0;
    return Get.find<AddressController>().getRestaurantDistance(LatLng(lat, lng));
  }

  double _earningAmount() {
    if(_isRide) {
      final rideAmount = _jsonDouble('final_fare') ?? _jsonDouble('finalFare') ?? _jsonDouble('estimated_fare') ?? _jsonDouble('estimatedFare') ?? _jsonDouble('fare') ?? _jsonDouble('bid_fare') ?? _jsonDouble('amount');
      if(rideAmount != null && rideAmount > 0) return rideAmount;
    }
    final amount = ((orderModel.originalDeliveryCharge ?? 0) + (orderModel.dmTips ?? 0)).toDouble();
    return amount > 0 ? amount : ((orderModel.deliveryCharge ?? 0) + (orderModel.dmTips ?? 0)).toDouble();
  }

  String _moduleLabel() {
    final raw = _rawType;
    if(_isRide) return 'Corrida';
    if(_isFoodOrder) return 'Food';
    if(raw.contains('pharmacy') || raw.contains('farm')) return 'Farmácia';
    if(raw.contains('grocery') || raw.contains('market') || raw.contains('mercado')) return 'Mercado';
    if(_isParcel) return 'Encomenda';
    final module = orderModel.moduleType?.trim();
    return module != null && module.isNotEmpty ? module : 'Entrega';
  }

  String _operationSubtitle() {
    if(_isRide) return 'Embarque do passageiro + destino final';
    if(_isFoodOrder) return 'Retirada na loja + entrega ao cliente';
    if(_isParcel) return 'Retirada da encomenda + entrega ao destinatário';
    return 'Entrega em andamento';
  }

  String _nextStepTitle() {
    if(_isRide) return 'Próxima etapa: ir ao embarque';
    if(_isParcel) return 'Próxima etapa: retirar encomenda';
    return 'Próxima etapa: ir para retirada';
  }

  String _primaryActionLabel() {
    if(_isRide) return 'Ir para embarque';
    if(_isParcel) return 'Iniciar retirada';
    return 'Ir para retirada';
  }

  String _originName() {
    if(_isRide) return _jsonString('pickup_name') ?? _jsonString('pickupName') ?? _jsonString('pickup_address') ?? _jsonString('pickupAddress') ?? 'Local de embarque';
    if(_isParcel) return orderModel.parcelCategory?.name ?? 'Origem do pacote';
    return orderModel.storeName ?? 'Loja';
  }

  String _pickupAddress() {
    if(_isRide) return _jsonString('pickup_address') ?? _jsonString('pickupAddress') ?? _jsonString('origin_address') ?? _jsonString('originAddress') ?? '';
    if(_isParcel) return orderModel.deliveryAddress?.address ?? '';
    return orderModel.storeAddress ?? '';
  }

  String _destinationAddress() {
    if(_isRide) return _jsonString('destination_address') ?? _jsonString('destinationAddress') ?? _jsonString('drop_address') ?? _jsonString('dropAddress') ?? '';
    if(_isParcel) return orderModel.receiverDetails?.address ?? '';
    return orderModel.deliveryAddress?.address ?? '';
  }

  String _paymentLabel() {
    final raw = _jsonString('payment_method') ?? _jsonString('paymentMethod') ?? orderModel.paymentMethod;
    switch (raw) {
      case 'cash_on_delivery':
      case 'cash':
        return 'Dinheiro';
      case 'wallet':
        return 'wallet'.tr;
      case 'offline_payment':
        return 'Offline';
      case 'partial_payment':
        return 'Parcial';
      default:
        return _isRide ? (raw?.isNotEmpty == true ? raw! : 'A confirmar') : 'digitally_paid'.tr;
    }
  }

  String _pickupLat() => (_jsonString('pickup_latitude') ?? _jsonString('pickupLatitude') ?? _jsonString('pickup_lat') ?? _jsonString('pickupLat') ?? '0');
  String _pickupLng() => (_jsonString('pickup_longitude') ?? _jsonString('pickupLongitude') ?? _jsonString('pickup_lng') ?? _jsonString('pickupLng') ?? '0');

  String? _jsonString(String key) {
    try {
      final value = orderModel.toJson()[key];
      final text = value?.toString().trim();
      return text == null || text.isEmpty || text == 'null' ? null : text;
    } catch (_) {
      return null;
    }
  }

  double? _jsonDouble(String key) {
    final value = _jsonString(key);
    return value == null ? null : double.tryParse(value);
  }
}
