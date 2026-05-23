import 'package:flutter/material.dart';
import 'package:sixam_mart/features/reels/widgets/reels_section_widget.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ReelsSectionWidget(),
        ),
      ),
    );
  }
}
