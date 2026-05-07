import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/helper/route_helper.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  final bool fromLogin;
  const PermissionOnboardingScreen({super.key, required this.fromLogin});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: () => Get.find<PermissionFlowController>().revalidateAfterReturn());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<PermissionFlowController>();
      await controller.refreshStatuses();
      if (!controller.hasCriticalMissing && mounted) _finish();
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.fromLogin) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.fromLogin,
      child: Scaffold(
        backgroundColor: const Color(0xFF111318),
        body: SafeArea(
          child: GetBuilder<PermissionFlowController>(builder: (controller) {
            if (controller.isRefreshing && controller.checks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!controller.hasCriticalMissing || controller.currentStep == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
              return _buildCompleted(context);
            }
            return _buildStep(context, controller, controller.currentStep!);
          }),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, PermissionFlowController controller, FoxGoPermissionStep step) {
    final _StepCopy copy = _copyFor(step);
    final int total = FoxGoPermissionStep.values.length;
    final int current = FoxGoPermissionStep.values.indexOf(step) + 1;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(copy.eyebrow, style: robotoBold.copyWith(color: const Color(0xFFFF7A00), fontSize: 12, letterSpacing: 1.2))),
          Text('$current/$total', style: robotoMedium.copyWith(color: Colors.white70)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: current / total,
            minHeight: 6,
            color: const Color(0xFFFF7A00),
            backgroundColor: Colors.white12,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1F27),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 12))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(color: const Color(0xFFFF7A00).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(24)),
              child: Icon(copy.icon, color: const Color(0xFFFF7A00), size: 36),
            ),
            const SizedBox(height: 28),
            Text(copy.title, style: robotoBold.copyWith(color: Colors.white, fontSize: 27, height: 1.12)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(copy.body1, style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.82), fontSize: Dimensions.fontSizeLarge, height: 1.42)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(copy.body2, style: robotoRegular.copyWith(color: Colors.white60, fontSize: Dimensions.fontSizeDefault, height: 1.4)),
            if (step == FoxGoPermissionStep.overlay) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              FutureBuilder<Map<String, dynamic>>(
                future: controller.getAndroidDeviceInfo(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null || data.isEmpty) return const SizedBox();
                  return Text(
                    'Vamos abrir a melhor configuração disponível para ${data['manufacturer'] ?? 'Android'} ${data['model'] ?? ''}. Se a tela direta não abrir, use a opção de acesso especial do Android.',
                    style: robotoRegular.copyWith(color: Colors.white54, fontSize: Dimensions.fontSizeSmall, height: 1.35),
                  );
                },
              ),
            ],
          ]),
        ),
        const Spacer(),
        CustomButtonWidget(
          buttonText: copy.primaryButton,
          radius: 16,
          height: 56,
          backgroundColor: const Color(0xFFFF7A00),
          onPressed: controller.isRefreshing ? null : () => controller.requestCurrentStep(),
        ),
        if (copy.secondaryButton != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextButton(
            onPressed: () => Get.snackbar('Permissão necessária', 'Para ficar online, conclua esta permissão crítica do Fox GO.'),
            child: Text(copy.secondaryButton!, style: robotoMedium.copyWith(color: Colors.white70)),
          ),
        ],
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ]),
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_rounded, color: Color(0xFFFF7A00), size: 72),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text('Permissões concluídas', style: robotoBold.copyWith(color: Colors.white, fontSize: 26), textAlign: TextAlign.center),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text('Tudo certo para receber chamadas de entrega no Fox GO.', style: robotoRegular.copyWith(color: Colors.white70), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  _StepCopy _copyFor(FoxGoPermissionStep step) {
    switch (step) {
      case FoxGoPermissionStep.preciseLocation:
        return const _StepCopy(
          eyebrow: 'PERMISSÃO DE LOCALIZAÇÃO',
          title: 'Permita acesso à sua localização exata',
          body1: 'Precisamos da sua localização exata para encontrar entregas próximas e calcular rotas com precisão.',
          body2: 'Não coletamos sua localização quando você estiver indisponível para receber entregas.',
          primaryButton: 'Permitir',
          icon: Icons.my_location_rounded,
        );
      case FoxGoPermissionStep.backgroundLocation:
        return const _StepCopy(
          eyebrow: 'PERMISSÃO DE LOCALIZAÇÃO',
          title: 'Precisamos acessar sua localização o tempo todo',
          body1: 'Esse acesso permite encontrar entregas e manter suas rotas de entrega funcionando mesmo quando o app estiver em segundo plano.',
          body2: 'Não coletamos sua localização quando você estiver indisponível para receber entregas.',
          primaryButton: 'Permitir',
          icon: Icons.location_on_rounded,
        );
      case FoxGoPermissionStep.notifications:
        return const _StepCopy(
          eyebrow: 'PERMISSÕES DO APP',
          title: 'Permitir notificações',
          body1: 'Precisamos enviar notificações importantes para avisar sobre novas chamadas de entrega, status do serviço e funcionamento em segundo plano.',
          body2: 'Você pode alterar essa permissão quando quiser nas configurações do aparelho.',
          primaryButton: 'Permitir',
          icon: Icons.notifications_active_rounded,
        );
      case FoxGoPermissionStep.overlay:
        return const _StepCopy(
          eyebrow: 'PERMISSÕES DO APP',
          title: 'Aparecer sobre outros apps',
          body1: 'Para garantir que você não perca novas chamadas de entrega enquanto usa outros aplicativos, ative a opção Aparecer sobre outros apps no seu celular.',
          body2: 'Você pode remover essa permissão quando quiser nas configurações do aparelho.',
          primaryButton: 'Permitir aparecer sobre outros',
          secondaryButton: 'Agora não',
          icon: Icons.picture_in_picture_alt_rounded,
        );
      case FoxGoPermissionStep.batteryOptimization:
        return const _StepCopy(
          eyebrow: 'PERMISSÕES DO APP',
          title: 'Permitir funcionamento em segundo plano',
          body1: 'Para receber chamadas de entrega mesmo com a tela bloqueada ou usando outros aplicativos, o Fox GO precisa continuar ativo em segundo plano.',
          body2: 'Isso ajuda a manter suas chamadas, localização e notificações funcionando corretamente enquanto você estiver disponível.',
          primaryButton: 'Permitir',
          icon: Icons.battery_saver_rounded,
        );
    }
  }
}

class _StepCopy {
  final String eyebrow;
  final String title;
  final String body1;
  final String body2;
  final String primaryButton;
  final String? secondaryButton;
  final IconData icon;

  const _StepCopy({
    required this.eyebrow,
    required this.title,
    required this.body1,
    required this.body2,
    required this.primaryButton,
    required this.icon,
    this.secondaryButton,
  });
}
