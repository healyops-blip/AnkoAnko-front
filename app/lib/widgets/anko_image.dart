import 'package:flutter/material.dart';

class AnkoImage extends StatelessWidget {
  const AnkoImage({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/anko.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Anko 家庭守护角色',
    );
  }
}
