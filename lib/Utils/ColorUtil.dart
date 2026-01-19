import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Resources/Colors.dart';
import 'dart:convert';
import "dart:math";

import 'package:palette_generator/palette_generator.dart';

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

class ColorUtil {
  /// 计算图片顶部的亮度，返回是否应该使用白色文字
  /// true = 背景深，用白字
  /// false = 背景浅，用黑字
  static Future<bool> shouldApplyWhiteMode(String imagePath) async {
    if (imagePath.isEmpty) return false;

    try {
      final File file = File(imagePath);
      if (!file.existsSync()) return false;

      final ImageProvider imageProvider = FileImage(file);

      // 生成调色板
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        region: Offset.zero & const Size(1000, 150),
        maximumColorCount: 10,
      );

      // 获取主色调，如果没有则默认白色
      Color dominantColor = generator.dominantColor?.color ?? Colors.white;

      // 计算亮度：0.0 (黑) ~ 1.0 (白)
      // 如果背景亮度 < 0.7 (偏暗)，则开启 WhiteMode (使用白字)
      return dominantColor.computeLuminance() < 0.7;
    } catch (e) {
      debugPrint("颜色分析失败: $e");
      return false; 
    }
  }
}