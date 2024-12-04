import 'package:flutter/material.dart';

class MyLogo extends StatelessWidget {
  final double height;

  const MyLogo({super.key, this.height = 150.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      height: height,
    );
  }
}
