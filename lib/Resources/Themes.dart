import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Utils/ColorUtil.dart';
import 'package:flutter/foundation.dart'; // ✅ 引入 foundation 以使用 defaultTargetPlatform

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

  static bool _isPresetHex(String hex) {
    final h = hex.trim().toUpperCase();
    return presetHexColors.any((e) => e.toUpperCase() == h);
  }

  static Color _brightenForDark(Color c, {double amount = 0.14}) {
    final hsl = HSLColor.fromColor(c);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    final out = hsl.withLightness(newLightness).toColor();

    final lum = out.computeLuminance();
    if (lum < 0.18) {
      final hsl2 = HSLColor.fromColor(out);
      return hsl2
          .withLightness((hsl2.lightness + 0.10).clamp(0.0, 1.0))
          .toColor();
    }
    return out;
  }

  static ThemeData build(String hex, Brightness brightness) {
    final rawSeed = HexColor(hex);
    final isDark = brightness == Brightness.dark;

    final bool isCustom = !_isPresetHex(hex);
    final Color seed = (isDark && isCustom)
        ? _brightenForDark(rawSeed, amount: 0.14)
        : rawSeed;

    final seeded = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final background =
        isDark ? const Color(0xFF0F0F11) : const Color(0xFFF8F8FA);
    final appBarSurface =
        isDark ? const Color(0xFF17171A) : const Color(0xFFEEEEF1);

    final surfaceHigh =
        isDark ? const Color(0xFF1F1F23) : const Color(0xFFE9E9ED);

    final onPrimary =
        ThemeData.estimateBrightnessForColor(seed) == Brightness.dark
            ? Colors.white
            : Colors.black;

    final scheme = seeded.copyWith(
      primary: seed,
      onPrimary: onPrimary,
      background: background,
      surface: background,
      surfaceContainerHighest: surfaceHigh,
      surfaceTint: Colors.transparent,
    );

    final appBarBg = appBarSurface;
    final appBarFg = scheme.onSurface;
    final overlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    const radius = 14.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    // ✅ 新增修复逻辑：强制统一字体字重
    // 1. 获取对应平台和亮度的标准排版配置 (Material 2021 是 M3 标准)
    final typography = Typography.material2021(platform: defaultTargetPlatform);
    final TextTheme defaultTextTheme = isDark ? typography.white : typography.black;

    // 2. 强制指定 bodyMedium (默认文本) 和 titleMedium 等关键样式的字重为 w400 (Normal)
    // 这样可以抵抗系统深色模式下的自动加粗
    final TextTheme fixedTextTheme = defaultTextTheme.copyWith(
      bodyMedium: defaultTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodyLarge: defaultTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: defaultTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      titleMedium: defaultTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
    );

    // 3. 将颜色应用到修复后的 TextTheme 上
    final TextTheme finalTextTheme = fixedTextTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      
      // ✅ 应用修复后的字体主题
      textTheme: finalTextTheme,

      scaffoldBackgroundColor: background,

      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: appBarFg,
          fontSize: 20,
          fontWeight: FontWeight.w600, // 标题保留 w600 加粗
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: scheme.surfaceContainerHighest,
        shape: shape,
      ),
      dialogTheme: DialogTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return scheme.primary.withOpacity(0.35);
            }
            return scheme.primary;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return scheme.onPrimary.withOpacity(0.6);
            }
            return scheme.onPrimary;
          }),
          elevation: MaterialStateProperty.all(0),
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(shape),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return scheme.onPrimary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.hovered)) {
              return scheme.onPrimary.withOpacity(0.06);
            }
            return null;
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: shape,
        ),
      ),

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

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return scheme.outlineVariant;
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        shape: const StadiumBorder(),
      ),
    );
  }
}

ThemeData getThemeData(String hex, Brightness brightness) =>
    AppThemes.build(hex, brightness);

final List<ThemeData> themeDataList =
    AppThemes.presetHexColors.map((c) => getThemeData(c, Brightness.light)).toList();

final List<ThemeData> darkThemeDataList =
    AppThemes.presetHexColors.map((c) => getThemeData(c, Brightness.dark)).toList();