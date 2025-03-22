import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DotsLoading extends StatelessWidget {
  const DotsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: const Color.fromRGBO(160, 103, 234, 1),
        // rightDotColor: const Color(0xFFEA3799),
        size: 60,
      ),
    );
  }
}
