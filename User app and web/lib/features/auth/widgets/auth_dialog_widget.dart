import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/centralize_login_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';

class AuthDialogWidget extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  const AuthDialogWidget({super.key, required this.exitFromApp, required this.backFromThis});

  @override
  AuthDialogWidgetState createState() => AuthDialogWidgetState();
}

class AuthDialogWidgetState extends State<AuthDialogWidget> {

  @override
  void initState() {
    super.initState();
    Get.find<AuthController>().resetOtpView(isUpdate: false);
  }

  bool _isOtpViewEnable = false;

  @override
  Widget build(BuildContext context) {
    double width = _isOtpViewEnable ? 400 : CentralizeLoginHelper.getPreferredLoginMethod(Get.find<SplashController>().configModel!.centralizeLoginSetup!, false).size;
    return SizedBox(
      width: width,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 18,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Stack(children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                decoration: BoxDecoration(
                  gradient: FoxGoDesign.redGradient(),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: SvgPicture.asset(Images.foxGoMark, width: 72, height: 72),
                  ),
                  const SizedBox(height: 14),
                  SvgPicture.asset(Images.foxGoLogoLight, width: 210),
                  const SizedBox(height: 10),
                  const Text(
                    'Peça comida, mercado, farmácia e muito mais com praticidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15.5, height: 1.35, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18)),
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.clear, color: Colors.white),
                ),
              ),

            ]),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                child: Column(children: [

                  const _FoxGoAuthBenefits(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis,
                    isOtpViewEnable: (bool val) {
                    setState(() {
                      _isOtpViewEnable = true;
                    });
                    },
                  ),
                ]),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


class _FoxGoAuthBenefits extends StatelessWidget {
  const _FoxGoAuthBenefits();

  @override
  Widget build(BuildContext context) {
    return Column(children: const [
      _FoxGoBenefitRow(icon: Icons.flash_on_rounded, title: 'Entrega rápida', subtitle: 'Acompanhe seus pedidos em tempo real.'),
      SizedBox(height: 10),
      _FoxGoBenefitRow(icon: Icons.verified_user_rounded, title: 'Pagamento seguro', subtitle: 'Seus dados sempre protegidos.'),
      SizedBox(height: 10),
      _FoxGoBenefitRow(icon: Icons.local_offer_rounded, title: 'Ofertas exclusivas', subtitle: 'Descontos e benefícios só para você.'),
    ]);
  }
}

class _FoxGoBenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FoxGoBenefitRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FoxGoDesign.softRed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: FoxGoDesign.graphite, fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w400, fontSize: 12.5, height: 1.2)),
        ])),
      ]),
    );
  }
}
