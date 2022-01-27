import 'dart:io';
import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final String _bgImgPath;

  const BackgroundImage(this._bgImgPath, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<File?> checkImg() async {
      if (_bgImgPath == '') {
        return null;
      }
      File file = File(_bgImgPath);
      if (await file.exists()) {
        return file;
      } else {
        return null;
      }
    }

    return FutureBuilder(
        future: checkImg(),
        builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          } else {
            return Container(
                decoration: BoxDecoration(
              image: DecorationImage(
                colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8), BlendMode.dstATop),
                image: FileImage(snapshot.data!),
                fit: BoxFit.cover,
              ),
            ));
          }
        });
  }
}
