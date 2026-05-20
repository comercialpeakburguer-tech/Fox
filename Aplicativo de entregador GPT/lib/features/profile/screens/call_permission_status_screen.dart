import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_app_bar_widget.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/helper/call_permission_helper.dart';

class CallPermissionStatusScreen extends StatefulWidget {
  const CallPermissionStatusScreen({super.key});

  @override
  State<CallPermissionStatusScreen> createState() => _CallPermissionStatusScreenState();
}

class _CallPermissionStatusScreenState extends State<CallPermissionStatusScreen> {
  bool _loading = true;
  bool _notifications = false;
  bool _overlay = false;
  bool _fsi = false;
  bool _battery = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    _notifications = await CallPermissionHelper.isNotificationGranted();
    _overlay = await CallPermissionHelper.isOverlayGranted();
    _fsi = await CallPermissionHelper.isFullScreenIntentAvailable();
    _battery = await CallPermissionHelper.isIgnoringBatteryOptimizations();
    if(mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'Permissões da nova chamada'),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _loadStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Para receber chamadas de entrega por cima de outros apps, permita que o Fox GO Entregador apareça sobre outros apps.'),
            const SizedBox(height: 16),
            _tile('Notificações', _notifications ? 'Ativo' : 'Inativo', _notifications ? null : () async {
              await CallPermissionHelper.openNotificationSettings();
              _loadStatus();
            }, 'Ativar notificações'),
            _tile('Aparecer sobre outros apps', _overlay ? 'Ativo' : 'Inativo', _overlay ? null : () async {
              await CallPermissionHelper.openOverlaySettings();
              _loadStatus();
            }, 'Ativar aparecer sobre outros apps'),
            _tile('Tela cheia (complementar)', _fsi ? 'Disponível' : 'Indisponível', null,
                'A permissão de tela cheia pode ser limitada em versões recentes do Android. O Fox GO usará essa função apenas como complemento.'),
            _tile('Bateria / segundo plano', _battery ? 'Ativo' : 'Atenção', _battery ? null : () async {
              await CallPermissionHelper.openBatterySettings();
              _loadStatus();
            }, 'Permitir funcionamento em segundo plano'),
            const SizedBox(height: 16),
            CustomButtonWidget(buttonText: 'Atualizar status', onPressed: _loadStatus),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String status, VoidCallback? onTap, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Status: $status'),
          const SizedBox(height: 8),
          Text(subtitle),
          if(onTap != null) ...[
            const SizedBox(height: 10),
            CustomButtonWidget(buttonText: subtitle, onPressed: onTap, height: 38),
          ],
        ]),
      ),
    );
  }
}
