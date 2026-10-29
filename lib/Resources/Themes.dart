import 'package:flutter/material.dart';
import '../AdaptiveUI/src/adaptive_typography.dart';
import 'package:flutter/services.dart';
import 'package:wheretosleepinnju/Utils/ThemeUtil.dart';
import 'dart:collection';
import '../Utils/ColorUtil.dart';
import '../AdaptiveUI/src/theme/deadliner_color_theme.dart';

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

  static ThemeData build(
    String hex,
    Brightness brightness, {
    required bool useSeedScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = DeadlinerColorTheme.fromSeed(
      seed: HexColor(hex),
      brightness: brightness,
      useMonet: useSeedScheme,
    );
    final scheme = palette.material;
    final background = scheme.surface;
    final appBarBg = scheme.surface;
    final appBarFg = scheme.onSurface;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            );

    const radius = 20.0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      textTheme: AdaptiveTypography.textTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      canvasColor: scheme.surface,
      cardColor: scheme.surfaceContainer,
      dividerColor: scheme.outlineVariant,
      disabledColor: palette.miuixColors.disabledOnSurface,
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
        color: scheme.surfaceContainer,
        shape: shape,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        backgroundColor: scheme.surfaceContainer,
        barrierColor: scheme.scrim,
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        modalBackgroundColor: scheme.surfaceContainer,
        modalBarrierColor: scheme.scrim,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.miuixColors.disabledPrimaryButton
                : scheme.primary,
          ),
          shape: WidgetStateProperty.all(shape),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
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
        fillColor: palette.textFieldContainer,
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
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return palette.miuixColors.onSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return palette.miuixColors.secondary;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _PresetThemeList extends ListBase<ThemeData> {
  final Brightness brightness;
  _PresetThemeList(this.brightness);

  // 两份缓存：useSeedScheme=true/false
  List<ThemeData>? _cacheSeedOn;
  List<ThemeData>? _cacheSeedOff;

  bool get _useSeedScheme {
    if (brightness == Brightness.dark) return ThemeRuntimeConfig.material3Dark;
    return ThemeRuntimeConfig.material3Light;
  }

  List<ThemeData> _resolve() {
    if (_useSeedScheme) {
      return _cacheSeedOn ??= AppThemes.presetHexColors
          .map((c) => getThemeData(c, brightness, useSeedScheme: true))
          .toList(growable: false);
    } else {
      return _cacheSeedOff ??= AppThemes.presetHexColors
          .map((c) => getThemeData(c, brightness, useSeedScheme: false))
          .toList(growable: false);
    }
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

ThemeData getThemeData(
  String hex,
  Brightness brightness, {
  required bool useSeedScheme,
}) => AppThemes.build(hex, brightness, useSeedScheme: useSeedScheme);

final themeDataList = _PresetThemeList(Brightness.light);
final darkThemeDataList = _PresetThemeList(Brightness.dark);
