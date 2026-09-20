import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:collection';
import '../Utils/ColorUtil.dart';

/// 自定义强调色槽位还没被设置过任何颜色时的兜底默认值。
const String defaultCustomAccentColor = '#0095F9';

class AppThemes {
  static const List<String> presetHexColors = [
    '#0095F9',
    '#4CAF50',
    '#002B82',
    '#872574',
    '#C52830',
    '#DDA3B2',
    '#2D7D93',
    '#919FC5',
    '#638190',
  ];

  static ThemeData build(String hex, Brightness brightness) {
    final rawSeed = HexColor(hex);
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: rawSeed,
      brightness: brightness,
    );

    // 强调色始终直接用你选的原色做 primary，不经过 M3 fromSeed 算法
    // 二次调色——这样"色轮里看到的颜色"和"App 里用到的颜色"完全一致，
    // 不会有算法自动调整导致的落差。
    final Color targetPrimary = rawSeed;

    // 背景色层级设定
    final background = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF8F8FA);
    final surfaceHigh = isDark ? const Color(0xFF1F1F23) : const Color(0xFFE9E9ED);

    // 组合最终 Scheme
    // 强制覆盖 primary 为我们计算出的 targetPrimary
    final scheme = baseScheme.copyWith(
      primary: targetPrimary,
      // onPrimary: Colors.white, 
      
      background: background,
      surface: background,
      surfaceContainerHighest: surfaceHigh,
      surfaceTint: Colors.transparent, // 禁用 M3 染色
    );

    // AppBar 配置：背景跟着强调色走（早期 Material 2 版本一直是这样，
    // 中间迁移到这套 M3 风格时改成了固定中性色，这里按要求改回来）。
    // 前景色按跟强调色的亮度对比自动选黑/白字，不管选了多浅或多深的
    // 强调色，标题文字都还能看清楚。
    final appBarBg = targetPrimary;
    final appBarFg = ThemeData.estimateBrightnessForColor(appBarBg) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    final overlayStyle =
        ThemeData.estimateBrightnessForColor(appBarBg) == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

    const radius = 14.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: appBarFg,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: scheme.surfaceContainerHighest,
        shape: shape,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        backgroundColor: isDark ? const Color(0xFF25252A) : Colors.white,
      ),
      
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          // 保持旧版逻辑：文字按钮直接用 Primary 做背景，白字 (新版 M3 默认是无背景)
          // 如果你想要新版那种 "只有字变色" 的风格，可以删掉 backgroundColor 设置
          // 下面保留你新版代码里写的 "有背景" 的 TextButton 样式：
          backgroundColor: MaterialStateProperty.resolveWith((states) {
             if (states.contains(MaterialState.disabled)) return scheme.primary.withOpacity(0.3);
             return scheme.primary; // 用回鲜艳色
          }),
          foregroundColor: MaterialStateProperty.all(Colors.white), // 强制白字
          shape: MaterialStateProperty.all(shape),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: shape,
        ),
      ),

      // OutlineButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: shape,
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1D) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return scheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) => Colors.transparent),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _PresetThemeList extends ListBase<ThemeData> {
  final Brightness brightness;
  _PresetThemeList(this.brightness);

  List<ThemeData>? _cache;

  List<ThemeData> _resolve() {
    return _cache ??= AppThemes.presetHexColors
        .map((c) => getThemeData(c, brightness))
        .toList(growable: false);
  }

  @override
  int get length => AppThemes.presetHexColors.length;

  @override
  set length(int newLength) => throw UnsupportedError('read-only');

  @override
  ThemeData operator [](int index) => _resolve()[index];

  @override
  void operator []=(int index, ThemeData value) =>
      throw UnsupportedError('read-only');
}

ThemeData getThemeData(String hex, Brightness brightness) =>
    AppThemes.build(hex, brightness);

final themeDataList = _PresetThemeList(Brightness.light);
final darkThemeDataList = _PresetThemeList(Brightness.dark);