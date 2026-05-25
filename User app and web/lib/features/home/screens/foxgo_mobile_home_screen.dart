import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class FoxGoMobileHomeScreen extends StatelessWidget {
  const FoxGoMobileHomeScreen({super.key});

  static const Color orange = Color(0xFFFF6A00);
  static const Color orange2 = Color(0xFFFF8F1F);
  static const Color yellow = Color(0xFFFFC107);
  static const Color red = Color(0xFFFF3B30);
  static const Color bg = Color(0xFFFFFBF7);
  static const Color text = Color(0xFF1A1C1E);
  static const Color muted = Color(0xFF6F7277);
  static const Color green = Color(0xFF119A4A);

  @override
  Widget build(BuildContext context) {
    final address = AddressHelper.getUserAddressFromSharedPref();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _header(address?.addressType?.tr ?? 'São Paulo, SP'),
                  const SizedBox(height: 14),
                  _search(),
                  const SizedBox(height: 16),
                  _banner(),
                  const SizedBox(height: 18),
                  _shortcuts(),
                  const SizedBox(height: 22),
                  _title('Lojas em destaque'),
                  const SizedBox(height: 12),
                  SizedBox(height: 172, child: ListView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), children: const [
                    _StoreCard('Pizzaria Itália', '30–40 min', 'Frete R\$ 2,99'),
                    _StoreCard('Padaria Artesanal', '20–30 min', 'Frete Grátis'),
                    _StoreCard('Burger House', '25–35 min', 'Frete R\$ 3,99'),
                  ])),
                  const SizedBox(height: 22),
                  _title('Mais pedidos'),
                  const SizedBox(height: 12),
                  _product('Burger House', 'Hambúrguer • $$', '4.8', 'Frete R\$ 3,99'),
                  _product('Sushi Zen', 'Japonês • $$$', '4.9', 'Frete Grátis'),
                  _product('Pizza Calabresa', 'Tradicional • Média', '4.7', 'R\$ 49,90'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String location) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [orange, red]).createShader(b), child: Text('FOX GO', style: robotoBold.copyWith(fontSize: 24, color: Colors.white, letterSpacing: .5))),
      const SizedBox(height: 3),
      Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: muted), const SizedBox(width: 3), Expanded(child: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: 12, color: muted))), const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: muted)]),
    ])),
    InkWell(onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()), borderRadius: BorderRadius.circular(18), child: Stack(clipBehavior: Clip.none, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 14, offset: Offset(0, 6))]), child: const Icon(Icons.notifications_none_rounded, color: text, size: 24)),
      Positioned(top: -4, right: -3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)), child: Text('3', style: robotoBold.copyWith(color: Colors.white, fontSize: 10)))),
    ])),
  ]);

  Widget _search() => InkWell(onTap: () => Get.toNamed(RouteHelper.getSearchRoute()), borderRadius: BorderRadius.circular(14), child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE9E9E9)), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 5))]), child: Row(children: [const Icon(Icons.search_rounded, color: muted, size: 22), const SizedBox(width: 8), Expanded(child: Text('Buscar restaurantes, mercados...', style: robotoRegular.copyWith(fontSize: 13, color: muted))), const Icon(Icons.tune_rounded, color: text, size: 20)])));

  Widget _banner() => Container(height: 118, width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [orange, red]), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x33FF6A00), blurRadius: 18, offset: Offset(0, 8))]), clipBehavior: Clip.antiAlias, child: Stack(children: [
    Positioned(right: -12, bottom: -25, child: Image.asset(Images.logo, height: 138, fit: BoxFit.contain)),
    Positioned(left: 18, top: 18, bottom: 16, right: 128, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Frete Grátis', style: robotoBold.copyWith(color: Colors.white, fontSize: 24, height: 1)), const SizedBox(height: 4), Text('em pedidos acima de R\$ 59', style: robotoMedium.copyWith(color: Colors.white.withValues(alpha: .92), fontSize: 12)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Text('Aproveitar', style: robotoBold.copyWith(color: text, fontSize: 12)))])),
  ]));

  Widget _shortcuts() {
    final data = [
      ['Restaurantes', Icons.restaurant_rounded, RouteHelper.allStores],
      ['Mercado', Icons.shopping_basket_rounded, RouteHelper.allStores],
      ['Farmácia', Icons.medical_services_rounded, RouteHelper.categories],
      ['Promoções', Icons.local_offer_rounded, RouteHelper.coupon],
    ];
    return Row(children: data.map((e) => Expanded(child: InkWell(onTap: () => Get.toNamed(e[2] as String), borderRadius: BorderRadius.circular(18), child: Column(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF0E6DF)), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6))]), child: ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [orange, red]).createShader(b), child: Icon(e[1] as IconData, color: Colors.white, size: 27))), const SizedBox(height: 7), Text(e[0] as String, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoMedium.copyWith(fontSize: 11, color: text))])))).toList());
  }

  Widget _title(String label) => Row(children: [Expanded(child: Text(label, style: robotoBold.copyWith(fontSize: 17, color: text))), Text('Ver todas', style: robotoMedium.copyWith(fontSize: 12, color: orange))]);

  Widget _product(String title, String subtitle, String rating, String delivery) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6))]), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(Images.placeholder, width: 76, height: 66, fit: BoxFit.cover)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: 14, color: text)), const SizedBox(height: 3), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoRegular.copyWith(fontSize: 12, color: muted)), const SizedBox(height: 8), Row(children: [const Icon(Icons.star_rounded, size: 16, color: yellow), const SizedBox(width: 2), Text(rating, style: robotoMedium.copyWith(fontSize: 12, color: text)), const SizedBox(width: 12), Text(delivery, style: robotoBold.copyWith(fontSize: 12, color: green))])])), Container(width: 34, height: 34, decoration: BoxDecoration(gradient: const LinearGradient(colors: [orange, red]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: Colors.white))]));
}

class _StoreCard extends StatelessWidget {
  final String title; final String time; final String price;
  const _StoreCard(this.title, this.time, this.price);
  @override
  Widget build(BuildContext context) => Container(width: 138, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 6))]), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [Image.asset(Images.placeholder, height: 84, width: double.infinity, fit: BoxFit.cover), Positioned(right: 8, top: 8, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), shape: BoxShape.circle), child: const Icon(Icons.favorite_border_rounded, size: 18, color: FoxGoMobileHomeScreen.orange)))]), Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(time, style: robotoRegular.copyWith(fontSize: 10, color: FoxGoMobileHomeScreen.muted)), const SizedBox(height: 3), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: 12.5, color: FoxGoMobileHomeScreen.text)), const SizedBox(height: 7), Row(children: [const Icon(Icons.star_rounded, color: FoxGoMobileHomeScreen.yellow, size: 15), Text(' 4.8', style: robotoMedium.copyWith(fontSize: 11, color: FoxGoMobileHomeScreen.text)), const Spacer(), Text(price, style: robotoBold.copyWith(fontSize: 10.5, color: FoxGoMobileHomeScreen.green))])]))]));
}
