import 'package:flutter/material.dart';

class MenuIconImage extends StatelessWidget {
  final String asset;
  final double size;

  const MenuIconImage({super.key, required this.asset, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, width: size, height: size);
  }
}
