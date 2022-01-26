import 'dart:io';
import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final String _bgImgPath;

  const BackgroundImage(this._bgImgPath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
//    return Container(child: Image.file(File(_bgImgPath)));
//      Image.file(File(_bgImgPath));
    if (_bgImgPath == '') {
      return Container();
    }
    File file = File(_bgImgPath);
    // if(file == null)
    //   return Container();
    return Container(
        decoration: BoxDecoration(
      image: DecorationImage(
        colorFilter:
            ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.dstATop),
        image: FileImage(file),
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
