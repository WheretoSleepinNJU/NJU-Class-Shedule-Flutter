import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Resources/Colors.dart';
import 'dart:convert';
import "dart:math";

import 'package:palette_generator/palette_generator.dart';
import 'package:libmonet/material_color_utilities.dart' as monet;

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
  static Future<void> checkColorPool() async {
    await getColorPool();
  }

  static Future<List<int>> getColorPool() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('colorPool');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List &&
            decoded.length == colorList.length &&
            decoded.every((v) => v is int && v >= 0 && v < colorList.length) &&
            decoded.toSet().length == colorList.length) {
          return List<int>.from(decoded);
        }
      } on FormatException {
        /* Repair incomplete or obsolete preferences. */
      }
    }
    return _writeNewPool(sp);
  }

  static Future<List<int>> _writeNewPool(SharedPreferences sp) async {
    final pool = List<int>.generate(colorList.length, (i) => i)..shuffle();
    await sp.setString('colorPool', jsonEncode(pool));
    return pool;
  }

  static Future<void> shuffleColorPool() async {
    await _writeNewPool(await SharedPreferences.getInstance());
  }
}

class ColorUtil {
  /// A one-off 96px sample, never a frame capture. Score colorful candidates by
  /// population; monochrome images retain their neutral hue instead of blue.
  static Future<String?> backgroundSeed(String imagePath) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        await File(imagePath).readAsBytes(),
        targetWidth: 96,
        targetHeight: 96,
        allowUpscaling: false,
      );
      image = (await codec.getNextFrame()).image;
      final palette = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 24,
        filters: const [],
      );
      final colors = {
        for (final c in palette.paletteColors) c.color.toARGB32(): c.population,
      };
      if (colors.isEmpty) return null;
      final fallback = palette.dominantColor!.color.toARGB32();
      final seed = monet.Score.score(colors, 1, fallback).first;
      return '#${(seed & 0xffffff).toRadixString(16).padLeft(6, '0')}';
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  /// 计算图片顶部的亮度，返回是否应该使用白色文字
  /// true = 背景深，用白字
  /// false = 背景浅，用黑字
  static Future<bool> shouldApplyWhiteMode(String imagePath) async {
    if (imagePath.isEmpty) return false;

    try {
      final File file = File(imagePath);
      if (!file.existsSync()) return false;

      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: 200,
      );
      late PaletteGenerator generator;
      final frame = await codec.getNextFrame();
      try {
        generator = await PaletteGenerator.fromImage(
          frame.image,
          region: Rect.fromLTWH(
            0,
            0,
            frame.image.width.toDouble(),
            min(32, frame.image.height).toDouble(),
          ),
          maximumColorCount: 10,
          filters: const [], // Black/white backgrounds must participate too.
        );
      } finally {
        frame.image.dispose();
        codec.dispose();
      }

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
