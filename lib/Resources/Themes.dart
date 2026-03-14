import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wheretosleepinnju/Utils/ThemeUtil.dart';

import '../Utils/ColorUtil.dart';
import 'PrototypePalette.dart';

class AppThemes {
  static const List<String> presetHexColors = [
    '#FFC93C',
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
    final rawSeed = HexColor(hex);
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: rawSeed,
      brightness: brightness,
    );

    final Color targetPrimary = useSeedScheme
        ? ColorScheme.fromSeed(
            seedColor: rawSeed,
            brightness: brightness,
          ).primary
        : rawSeed;

    final Color background =
        isDark ? const Color(0xFF15120F) : DuckPalette.page;
    final Color appBarSurface =
        isDark ? const Color(0xFF1E1A16) : DuckPalette.page;
    final Color surfaceHigh =
        isDark ? const Color(0xFF26211B) : DuckPalette.surface;
    final Color outlineColor =
        isDark ? const Color(0xFF4E453B) : DuckPalette.border;
    final Color onSurface =
        isDark ? const Color(0xFFF7EFE5) : DuckPalette.textMain;
    final Color onSurfaceVariant =
        isDark ? const Color(0xFFD1C2B2) : DuckPalette.textMuted;

    final ColorScheme scheme = baseScheme.copyWith(
      primary: isDark ? targetPrimary : DuckPalette.duckYellow,
      onPrimary: isDark ? DuckPalette.textMain : Colors.white,
      secondary: DuckPalette.duckYellowSoft,
      surface: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      outlineVariant: outlineColor,
      outline: outlineColor,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceTint: Colors.transparent,
    );

    final SystemUiOverlayStyle overlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    const double radius = 24.0;
    final RoundedRectangleBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarSurface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: scheme.surfaceContainerHighest,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        backgroundColor: isDark ? const Color(0xFF211C17) : DuckPalette.page,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.primary.withValues(alpha: 0.3);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
          shape: WidgetStateProperty.all(shape),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1612) : DuckPalette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
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
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
      ),
      dividerColor: outlineColor,
    );
  }
}

class _PresetThemeList extends ListBase<ThemeData> {
  _PresetThemeList(this.brightness);

  final Brightness brightness;
  List<ThemeData>? _cacheSeedOn;
  List<ThemeData>? _cacheSeedOff;

  bool get _useSeedScheme {
    if (brightness == Brightness.dark) {
      return ThemeRuntimeConfig.material3Dark;
    }
    return ThemeRuntimeConfig.material3Light;
  }

  List<ThemeData> _resolve() {
    if (_useSeedScheme) {
      return _cacheSeedOn ??= AppThemes.presetHexColors
          .map(
            (String color) => getThemeData(
              color,
              brightness,
              useSeedScheme: true,
            ),
          )
          .toList(growable: false);
    }
    return _cacheSeedOff ??= AppThemes.presetHexColors
        .map(
          (String color) => getThemeData(
            color,
            brightness,
            useSeedScheme: false,
          ),
        )
        .toList(growable: false);
  }

  @override
  int get length => AppThemes.presetHexColors.length;

  @override
  set length(int newLength) => throw UnsupportedError('read-only');

  @override
  ThemeData operator [](int index) => _resolve()[index];

  @override
  void operator []=(int index, ThemeData value) {
    throw UnsupportedError('read-only');
  }
}

ThemeData getThemeData(
  String hex,
  Brightness brightness, {
  required bool useSeedScheme,
}) =>
    AppThemes.build(
      hex,
      brightness,
      useSeedScheme: useSeedScheme,
    );

final themeDataList = _PresetThemeList(Brightness.light);
final darkThemeDataList = _PresetThemeList(Brightness.dark);
