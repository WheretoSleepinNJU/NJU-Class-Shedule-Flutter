import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class BackgroundImage extends StatelessWidget {
  final String _bgImgPath;

  BackgroundImage(this._bgImgPath);

  @override
  Widget build(BuildContext context) {
//    return Container(child: Image.file(File(_bgImgPath)));
//      Image.file(File(_bgImgPath));

    return Container(
        decoration: BoxDecoration(
      image: DecorationImage(
        colorFilter: new ColorFilter.mode(
            Colors.white.withOpacity(0.8), BlendMode.dstATop),
        image: FileImage(File(_bgImgPath)),
        fit: BoxFit.cover,
      ),
    ));
//    Container(
//        decoration: BoxDecoration(
//      image: DecorationImage(
//        colorFilter: new ColorFilter.mode(
//            Colors.white.withOpacity(0.8), BlendMode.dstATop),
//        image: AssetImage(_bgImgPath),
//        fit: BoxFit.cover,
//      ),
//    ));
  }
}
