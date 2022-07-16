import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Resources/Colors.dart';
import 'dart:convert';
import "dart:math";

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  static String getRandomColor() {
    final _random = Random();
    return colorList[_random.nextInt(colorList.length)];
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class ColorPool {
  static checkColorPool() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? colorPool = sp.getString("colorPool");
    if (colorPool == null) shuffleColorPool();
  }

  static Future<List> getColorPool() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? colorPoolString = sp.getString('colorPool');
//    print(colorPoolString);
    List colorPool = json.decode(colorPoolString!);
    return colorPool;
  }

  static shuffleColorPool() async {
    List<int> colorPool = List<int>.generate(colorList.length, (i) => i);
    colorPool.shuffle();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('colorPool', colorPool.toString());
  }
}
