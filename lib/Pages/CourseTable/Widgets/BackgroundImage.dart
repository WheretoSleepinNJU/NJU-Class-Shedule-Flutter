import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final String _bgImgPath;

  BackgroundImage(this._bgImgPath);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
      image: DecorationImage(
        colorFilter: new ColorFilter.mode(
            Colors.white.withOpacity(0.8), BlendMode.dstATop),
        image: AssetImage(_bgImgPath),
        fit: BoxFit.cover,
      ),
    ));
  }
}
