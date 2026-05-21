import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/domain/models/order_model.dart';
import 'package:sixam_mart_delivery/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/app_constants.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class FoxGoCustomerNoShowTimerWidget extends StatefulWidget {
  final OrderModel order;
  final bool parcel;

  const FoxGoCustomerNoShowTimerWidget({
    super.key,
    required this.order,
    required this.parcel,
  });

  @override
  State<FoxGoCustomerNoShowTimerWidget> createState() => _FoxGoCustomerNoShowTimerWidgetState();
}

class _FoxGoCustomerNoShowTimerWidgetState extends State<FoxGoCustomerNoShowTimerWidget> {
  static const int _totalSeconds = 300;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;
  bool _started = false;
  bool _finished = false;

  bool get _isDeliveryStage => widget.order.orderStatus == AppConstants.pickedUp;
  bool get _isParcel => widget.parcel;

  String get _title => _isParcel ? 'Destinatário não localizado' : 'Cliente não localizado';
  String get _personLabel => _isParcel ? 'destinatário' : 'cliente';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_started) return;

    setState(() {
      _started = true;
      _finished = false;
      _remainingSeconds = _totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _finished = true;
        });
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  void _openSupport() {
    if (!_finished) return;

    final notificationBody = NotificationBodyModel(
      orderId: widget.order.id,
      adminId: 0,
      type: AppConstants.admin,
    );

    Get.toNamed(RouteHelper.getChatRoute(
      notificationBody: notificationBody,
      user: User(
        id: 0,
        fName: 'Suporte Fox GO',
        lName: '',
        imageFullUrl: '',
        phone: '',
      ),
      conversationId: null,
      fromNotification: false,
      fromSupport: true,
    ));
  }

  String _formatRemaining() {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeliveryStage) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4C6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_search_rounded, color: Colors.black, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_title, style: robotoBold.copyWith(fontSize: 21, color: Colors.black)),
            const SizedBox(height: 6),
            Text(
              'Use esta opção somente depois de marcar que chegou no destino e tentar contato com o $_personLabel.',
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF666666), height: 1.35),
            ),
          ])),
        ]),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: [
            Container(
              width: 106,
              height: 106,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD400), width: 8),
              ),
              child: Center(
                child: Text(_started ? _formatRemaining() : '05:00', style: robotoBold.copyWith(fontSize: 26, color: Colors.black)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _finished ? 'Tempo concluído' : (_started ? 'Aguarde o $_personLabel' : 'Iniciar espera de 5 minutos'),
              textAlign: TextAlign.center,
              style: robotoBold.copyWith(fontSize: 20, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _finished
                  ? 'Agora você pode falar com o suporte/admin para receber orientação.'
                  : (_started ? 'O suporte será liberado ao terminar o contador.' : 'O pedido continua aberto e o fluxo não será quebrado.'),
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: const Color(0xFF666666), height: 1.35),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        if (!_started)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Cliente não apareceu', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
            ),
          ),
        if (_started && !_finished)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Falar com suporte em ${_formatRemaining()}', style: robotoMedium),
            ),
          ),
        if (_finished)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openSupport,
              icon: const Icon(Icons.support_agent_rounded),
              label: Text('Falar com suporte', style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Mensagem pronta: pedido #${widget.order.id ?? '-'} com ${_personLabel} não localizado após 5 minutos no destino.',
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: const Color(0xFF888888), height: 1.35),
        ),
      ]),
    );
  }
}
