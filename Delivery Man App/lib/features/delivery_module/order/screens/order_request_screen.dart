import 'dart:async';
import 'package:sixam_mart_delivery/features/delivery_module/order/controllers/order_controller.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/helper/order_request_overlay_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';
import 'package:sixam_mart_delivery/features/delivery_module/order/widgets/fox_go_order_request_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderRequestScreen extends StatefulWidget {
  final Function onTap;
  final bool? fromMapScreen;
  const OrderRequestScreen({super.key, required this.onTap, this.fromMapScreen = false});

  @override
  OrderRequestScreenState createState() => OrderRequestScreenState();
}

class OrderRequestScreenState extends State<OrderRequestScreen> {
  Timer? _timer;
  bool _refreshing = false;

  @override
  initState() {
    super.initState();
    OrderRequestOverlayHelper.setSuppressAutoCard(true);

    if(Get.find<ProfileController>().profileModel == null) {
      Get.find<ProfileController>().getProfile();
    }

    _refreshRequests(source: 'init');
    _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
      _refreshRequests(source: 'poll');
    });
  }

  Future<void> _refreshRequests({String source = 'manual'}) async {
    if(_refreshing) return;
    _refreshing = true;
    final orderController = Get.find<OrderController>();
    orderController.removeFromIgnoreList();
    await orderController.getLatestOrders(routeCall: false);
    if(mounted) {
      setState(() => _refreshing = false);
    } else {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    OrderRequestOverlayHelper.setSuppressAutoCard(false);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: GetBuilder<OrderController>(builder: (orderController) {
          final requests = orderController.latestOrderList;
          final int count = requests?.length ?? 0;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => widget.onTap(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 22),
                ),
                Expanded(
                  child: Text(
                    'SOLICITAÇÕES',
                    textAlign: TextAlign.center,
                    style: robotoBold.copyWith(fontSize: 15, letterSpacing: 1.5, color: Colors.black),
                  ),
                ),
                IconButton(
                  onPressed: _refreshing ? null : () => _refreshRequests(source: 'button'),
                  icon: _refreshing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Colors.black, size: 26),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pedidos disponíveis', style: robotoBold.copyWith(fontSize: 32, height: 1.05, color: Colors.black)),
                const SizedBox(height: 8),
                Text(
                  count == 0 ? 'Quando tocar uma chamada, ela aparece aqui.' : '$count ${count == 1 ? 'chamada disponível' : 'chamadas disponíveis'} agora',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: const Color(0xFF666666)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: requests == null
                  ? const Center(child: CircularProgressIndicator())
                  : requests.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => _refreshRequests(source: 'pull-empty'),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(22, 70, 22, 24),
                            children: [_emptyState()],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _refreshRequests(source: 'pull-list'),
                          child: ListView.separated(
                            itemCount: requests.length,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if(index >= requests.length) return const SizedBox();
                              return FoxGoOrderRequestCardWidget(
                                key: ValueKey('foxgo_request_${requests[index].id}_$index'),
                                orderModel: requests[index],
                                index: index,
                                onTap: widget.onTap,
                              );
                            },
                          ),
                        ),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(color: const Color(0xFFFFF4C6), borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.delivery_dining_rounded, color: Colors.black, size: 42),
        ),
        const SizedBox(height: 18),
        Text('Nenhuma chamada no momento', textAlign: TextAlign.center, style: robotoBold.copyWith(fontSize: 22, color: Colors.black)),
        const SizedBox(height: 8),
        Text(
          'Fique online e mantenha o GPS ativo para receber novas ofertas da logística Fox GO.',
          textAlign: TextAlign.center,
          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: const Color(0xFF666666), height: 1.35),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _refreshing ? null : () => _refreshRequests(source: 'empty-button'),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Atualizar solicitações'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]),
    );
  }
}
