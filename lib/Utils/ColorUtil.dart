import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Resources/Colors.dart';
import '../Resources/ColorSchemes.dart';
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

/// 某一时刻"实际生效"的自动配色数据：`palette` 是当前选中方案的色板，
/// `indices` 是这套色板的洗牌顺序（下标数组，长度始终和 palette 一致——
/// `ColorPool` 负责保证这一点，比如方案色板扩容后会自动重新洗牌）。
/// `Course.getColor()` 就是靠 `palette[indices[courseId % indices.length]]`
/// 算出某门课具体是哪个颜色。
class ActiveColorPool {
  final List<int> indices;
  final List<String> palette;

  const ActiveColorPool(this.indices, this.palette);
}

class ColorPool {
  static const _kColorSchemeIdKey = 'colorSchemeId';
  static const _kColorPoolKey = 'colorPool';

  static Future<CourseColorScheme> getActiveScheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return CourseColorSchemes.findById(sp.getString(_kColorSchemeIdKey));
  }

  /// 切换配色方案：写入方案 id，并按新方案的色板长度重新洗一次牌。
  /// 是否要连带清空所有课程已经手动指定过的自定义颜色，由调用方（设置页）
  /// 自己决定并执行，这里只负责"方案本身"这一层。
  static Future<void> setActiveScheme(String schemeId) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(_kColorSchemeIdKey, schemeId);
    await shuffleColorPool();
  }

  /// 保证本地存的洗牌下标数组存在、且长度和当前方案色板长度一致；
  /// 不一致（比如色板扩容了，或者刚切换了一套长度不同的方案）就重新
  /// 洗一次——这是"调色板扩容后自动配色课程颜色重排一次"的落地点。
  static Future<void> checkColorPool() async {
    final scheme = await getActiveScheme();
    SharedPreferences sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kColorPoolKey);
    if (raw == null) {
      await shuffleColorPool();
      return;
    }
    List decoded;
    try {
      decoded = json.decode(raw);
    } catch (_) {
      decoded = const [];
    }
    if (decoded.length != scheme.colors.length) {
      await shuffleColorPool();
    }
  }

  static Future<List> getColorPool() async {
    await checkColorPool();
    SharedPreferences sp = await SharedPreferences.getInstance();
    String colorPoolString = sp.getString(_kColorPoolKey)!;
    List colorPool = json.decode(colorPoolString);
    return colorPool;
  }

  /// 一次性拿到"洗牌下标 + 当前方案色板"这一整套配套数据，供
  /// `Course.getColor()` 用。
  static Future<ActiveColorPool> getActivePool() async {
    final scheme = await getActiveScheme();
    final indices = await getColorPool();
    return ActiveColorPool(indices.cast<int>(), scheme.colors);
  }

  static Future<void> shuffleColorPool() async {
    final scheme = await getActiveScheme();
    List<int> colorPool = List<int>.generate(scheme.colors.length, (i) => i);
    colorPool.shuffle();
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(_kColorPoolKey, json.encode(colorPool));
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
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
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
