import 'package:flutter/material.dart';
import '../Resources/Colors.dart';
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
    final _random = new Random();
    return colorList[_random.nextInt(colorList.length)];
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}