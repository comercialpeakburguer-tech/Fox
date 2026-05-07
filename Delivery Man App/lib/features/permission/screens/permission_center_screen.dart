import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/common/widgets/custom_button_widget.dart';
import 'package:sixam_mart_delivery/features/permission/controllers/permission_flow_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';
import 'package:sixam_mart_delivery/util/styles.dart';

class PermissionCenterScreen extends StatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  State<PermissionCenterScreen> createState() => _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends State<PermissionCenterScreen> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: () => Get.find<PermissionFlowController>().revalidateAfterReturn());
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.find<PermissionFlowController>().refreshStatuses());
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissões do app')),
      body: GetBuilder<PermissionFlowController>(builder: (controller) {
        return RefreshIndicator(
          onRefresh: () => controller.refreshStatuses(),
          child: ListView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Central de permissões Fox GO', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    'Visualize o status real das permissões do Android e corrija o que estiver pendente usando o mesmo fluxo guiado do login.',
                    style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                  ),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              ...controller.checks.map((check) => _PermissionStatusTile(check: check)),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              CustomButtonWidget(
                buttonText: controller.hasCriticalMissing ? 'Corrigir permissões pendentes' : 'Atualizar status',
                onPressed: controller.hasCriticalMissing
                    ? () => controller.openPermissionFlow()
                    : () => controller.refreshStatuses(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PermissionStatusTile extends StatelessWidget {
  final FoxGoPermissionCheck check;
  const _PermissionStatusTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final bool ok = check.isGranted;
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey[Get.isDarkMode ? 850 : 200]!, blurRadius: 5, spreadRadius: 1)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: ok ? Colors.green : Theme.of(context).colorScheme.error),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(check.title, style: robotoBold),
            const SizedBox(height: 4),
            Text(ok ? check.activeLabel : check.inactiveLabel, style: robotoMedium.copyWith(color: ok ? Colors.green : Theme.of(context).colorScheme.error)),
            if (check.details != null) ...[
              const SizedBox(height: 4),
              Text(check.details!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
            ],
          ]),
        ),
        if (check.needsAction)
          TextButton(
            onPressed: () => Get.find<PermissionFlowController>().openPermissionFlow(startAt: check.step),
            child: const Text('Corrigir'),
          )
        else
          TextButton(
            onPressed: () => Get.find<PermissionFlowController>().refreshStatuses(),
            child: const Text('Atualizar'),
          ),
      ]),
    );
  }
}
