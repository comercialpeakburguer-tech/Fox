import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/foxgo_design.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FoxGoWebHomeScreen extends StatelessWidget {
  const FoxGoWebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FoxGoPalette palette = FoxGoPalette(Theme.of(context).brightness == Brightness.dark);
    final String location = AddressHelper.getUserAddressFromSharedPref()?.address ?? 'São Paulo, SP';

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(children: [
            _topStrip(palette, location),
            _navBar(palette),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _hero(palette),
                    const SizedBox(height: 28),
                    _categoryRow(palette),
                    const SizedBox(height: 34),
                    _sectionHeader(palette, 'Lojas em destaque'),
                    const SizedBox(height: 16),
                    _storeGrid(palette),
                    const SizedBox(height: 34),
                    _sectionHeader(palette, 'Mais pedidos'),
                    const SizedBox(height: 16),
                    _productGrid(palette),
                    const SizedBox(height: 48),
                    _benefitBar(palette),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _topStrip(FoxGoPalette palette, String location) {
    return Container(
      height: 40,
      color: palette.dark ? FoxGoColors.darkSurface : const Color(0xFFFFEFE7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(children: [
              const Icon(Icons.location_on_rounded, color: FoxGoColors.orange, size: 17),
              const SizedBox(width: 6),
              Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: 13, color: palette.text))),
              Text('Junte-se a nós', style: robotoMedium.copyWith(fontSize: 13, color: palette.text)),
              const SizedBox(width: 12),
              _roundIcon(palette, Icons.dark_mode_outlined, size: 16),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navBar(FoxGoPalette palette) {
    return Container(
      height: 72,
      color: palette.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(children: [
              ShaderMask(
                shaderCallback: (bounds) => palette.brandGradient.createShader(bounds),
                child: Text('Fox GO', style: robotoBold.copyWith(fontSize: 25, color: Colors.white, letterSpacing: .4)),
              ),
              const SizedBox(width: 44),
              _navItem(palette, 'Início'),
              _navItem(palette, 'Categorias'),
              _navItem(palette, 'Favoritos'),
              _navItem(palette, 'Lojas'),
              const Spacer(),
              _plainIcon(palette, Icons.search_rounded),
              _plainIcon(palette, Icons.notifications_rounded),
              _plainIcon(palette, Icons.shopping_cart_rounded),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(gradient: palette.brandGradient, borderRadius: BorderRadius.circular(999)),
                child: Text('Entrar', style: robotoBold.copyWith(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              _plainIcon(palette, Icons.menu_rounded),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(FoxGoPalette palette, String label) => Padding(
    padding: const EdgeInsets.only(right: 26),
    child: Text(label, style: robotoMedium.copyWith(fontSize: 15, color: palette.text)),
  );

  Widget _hero(FoxGoPalette palette) {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        flex: 7,
        child: Container(
          height: 294,
          decoration: BoxDecoration(
            gradient: palette.brandGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x33FF6A00), blurRadius: 34, offset: Offset(0, 16))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned(right: -16, bottom: -50, child: Image.asset(Images.logo, height: 330, fit: BoxFit.contain)),
            Positioned(left: 42, top: 42, bottom: 36, width: 420, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fox GO', style: robotoBold.copyWith(fontSize: 50, height: 1, color: Colors.white, letterSpacing: .6)),
              const SizedBox(height: 16),
              Text('Entrega rápida. Sempre com você.', style: robotoMedium.copyWith(fontSize: 26, height: 1.2, color: Colors.white)),
              const SizedBox(height: 14),
              Text('Premium. Rápido. Confiável.', style: robotoMedium.copyWith(fontSize: 18, color: FoxGoColors.yellow)),
              const Spacer(),
              Row(children: [
                _heroButton('Ver promoções', palette.dark ? FoxGoColors.yellow : Colors.white, FoxGoColors.lightText),
                const SizedBox(width: 12),
                _heroButton('Buscar lojas', Colors.black.withValues(alpha: .18), Colors.white, border: Colors.white.withValues(alpha: .45)),
              ]),
            ])),
          ]),
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 3,
        child: Container(
          height: 294,
          padding: const EdgeInsets.all(24),
          decoration: foxGoCardDecoration(palette, radius: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Por que Fox GO?', style: robotoBold.copyWith(fontSize: 22, color: palette.text)),
            const SizedBox(height: 20),
            _benefitItem(palette, Icons.bolt_rounded, 'Rápido', 'Entregas ágeis na sua região.'),
            _benefitItem(palette, Icons.verified_user_rounded, 'Confiável', 'Segurança e privacidade.'),
            _benefitItem(palette, Icons.favorite_rounded, 'Feito para você', 'Experiência simples e prática.'),
          ]),
        ),
      ),
    ]);
  }

  Widget _heroButton(String label, Color bg, Color fg, {Color? border}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: border == null ? null : Border.all(color: border)),
    child: Text(label, style: robotoBold.copyWith(fontSize: 14, color: fg)),
  );

  Widget _categoryRow(FoxGoPalette palette) {
    final data = [
      ['Restaurantes', Icons.restaurant_rounded],
      ['Mercado', Icons.shopping_basket_rounded],
      ['Farmácia', Icons.medical_services_rounded],
      ['Entregas', Icons.delivery_dining_rounded],
      ['Carrinho', Icons.shopping_cart_rounded],
      ['Cupons', Icons.confirmation_number_rounded],
      ['Suporte', Icons.headset_mic_rounded],
      ['Configurações', Icons.settings_rounded],
    ];
    return Row(children: data.map((item) => Expanded(child: Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 104,
          decoration: foxGoCardDecoration(palette, radius: 20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ShaderMask(shaderCallback: (b) => palette.brandGradient.createShader(b), child: Icon(item[1] as IconData, color: Colors.white, size: 32)),
            const SizedBox(height: 10),
            Text(item[0] as String, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: 12, color: palette.text)),
          ]),
        ),
      ),
    ))).toList());
  }

  Widget _sectionHeader(FoxGoPalette palette, String title) => Row(children: [
    Text(title, style: robotoBold.copyWith(fontSize: 23, color: palette.text)),
    const Spacer(),
    Text('Ver todas', style: robotoBold.copyWith(fontSize: 14, color: FoxGoColors.orange)),
  ]);

  Widget _storeGrid(FoxGoPalette palette) => GridView.count(
    crossAxisCount: 4,
    crossAxisSpacing: 18,
    mainAxisSpacing: 18,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.18,
    children: [
      _storeCard(palette, 'Burger House', '25–35 min • R\$ 9,90'),
      _storeCard(palette, 'Sabor & Cia', '20–30 min • R\$ 7,90'),
      _storeCard(palette, 'Pizzaria Top', '30–40 min • R\$ 8,90'),
      _storeCard(palette, 'Padaria Artesanal', '20–30 min • Frete grátis'),
    ],
  );

  Widget _storeCard(FoxGoPalette palette, String title, String subtitle) => Container(
    decoration: foxGoCardDecoration(palette, radius: 22),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Stack(children: [
        Positioned.fill(child: Image.asset(Images.placeholder, fit: BoxFit.cover)),
        Positioned(top: 12, right: 12, child: _roundIcon(palette, Icons.favorite_border_rounded, size: 20)),
      ])),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: 16, color: palette.text)),
          const SizedBox(height: 5),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: 13, color: palette.muted)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.star_rounded, color: FoxGoColors.yellow, size: 18),
            Text(' 4.8', style: robotoBold.copyWith(fontSize: 13, color: palette.text)),
            const Spacer(),
            Text('Aberto', style: robotoBold.copyWith(fontSize: 12, color: FoxGoColors.success)),
          ]),
        ]),
      ),
    ]),
  );

  Widget _productGrid(FoxGoPalette palette) => GridView.count(
    crossAxisCount: 3,
    crossAxisSpacing: 18,
    mainAxisSpacing: 18,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 2.45,
    children: [
      _productCard(palette, 'Pizza Calabresa', 'Tradicional • Média', 'R\$ 49,90'),
      _productCard(palette, 'Burger House', 'Combo premium', 'R\$ 39,90'),
      _productCard(palette, 'Sushi Zen', 'Japonês especial', 'R\$ 59,90'),
    ],
  );

  Widget _productCard(FoxGoPalette palette, String title, String subtitle, String price) => Container(
    padding: const EdgeInsets.all(12),
    decoration: foxGoCardDecoration(palette, radius: 20),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(Images.placeholder, width: 96, height: 86, fit: BoxFit.cover)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: 16, color: palette.text)),
        const SizedBox(height: 5),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: 13, color: palette.muted)),
        const SizedBox(height: 8),
        Text(price, style: robotoBold.copyWith(fontSize: 15, color: palette.text)),
      ])),
      Container(width: 38, height: 38, decoration: BoxDecoration(gradient: palette.brandGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: Colors.white)),
    ]),
  );

  Widget _benefitBar(FoxGoPalette palette) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
    decoration: BoxDecoration(gradient: palette.brandGradient, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      Text('Fox GO', style: robotoBold.copyWith(fontSize: 28, color: Colors.white)),
      const SizedBox(width: 18),
      Expanded(child: Text('Rápido, fácil e sempre com você.', style: robotoBold.copyWith(fontSize: 16, color: Colors.white))),
      _footerBenefit(Icons.delivery_dining_rounded, 'Entregas rápidas'),
      _footerBenefit(Icons.verified_rounded, 'Pagamento seguro'),
      _footerBenefit(Icons.headset_mic_rounded, 'Suporte dedicado'),
    ]),
  );

  Widget _footerBenefit(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(left: 28),
    child: Row(children: [Icon(icon, color: FoxGoColors.yellow, size: 26), const SizedBox(width: 8), Text(label, style: robotoBold.copyWith(color: Colors.white, fontSize: 13))]),
  );

  Widget _benefitItem(FoxGoPalette palette, IconData icon, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(gradient: palette.brandGradient, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 23)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoBold.copyWith(fontSize: 15, color: palette.text)),
        const SizedBox(height: 3),
        Text(text, style: robotoRegular.copyWith(fontSize: 12, color: palette.muted, height: 1.25)),
      ])),
    ]),
  );

  Widget _plainIcon(FoxGoPalette palette, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(icon, color: palette.text, size: 23),
  );

  Widget _roundIcon(FoxGoPalette palette, IconData icon, {double size = 18}) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: palette.surface.withValues(alpha: .92), borderRadius: BorderRadius.circular(13), border: Border.all(color: palette.border.withValues(alpha: .65))),
    child: Icon(icon, color: FoxGoColors.orange, size: size),
  );
}
