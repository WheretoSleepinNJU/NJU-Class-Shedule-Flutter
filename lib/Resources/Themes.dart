import 'package:flutter/material.dart';
import '../Utils/ColorUtil.dart';

ThemeData getThemeData(String color, Brightness brightness) {
  ThemeData td =
      ThemeData(colorSchemeSeed: HexColor(color), brightness: brightness);
  ThemeData tdlight =
      ThemeData(colorSchemeSeed: HexColor(color), brightness: Brightness.light);
  Color primaryThemeColor = tdlight.primaryColor;
  Color primaryColor = HexColor(color);
  ThemeData rst = td.copyWith(
    appBarTheme: AppBarTheme(
      titleTextStyle: const TextStyle(fontSize: 18, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
      color: brightness == Brightness.light ? primaryColor : primaryThemeColor,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
      ),
    ),
  );
  return rst;
}

final List<ThemeData> themeDataList = [
  getThemeData('#0095F9', Brightness.light),
  getThemeData('#4CAF50', Brightness.light),
  getThemeData('#002B82', Brightness.light),
  getThemeData('#872574', Brightness.light),
  getThemeData('#C52830', Brightness.light),
  getThemeData('#DDA3B2', Brightness.light),
  getThemeData('#2D7D93', Brightness.light),
  getThemeData('#919FC5', Brightness.light),
  getThemeData('#638190', Brightness.light),
];

final List<ThemeData> darkThemeDataList = [
  getThemeData('#0095F9', Brightness.dark),
  getThemeData('#4CAF50', Brightness.dark),
  getThemeData('#002B82', Brightness.dark),
  getThemeData('#872574', Brightness.dark),
  getThemeData('#C52830', Brightness.dark),
  getThemeData('#DDA3B2', Brightness.dark),
  getThemeData('#2D7D93', Brightness.dark),
  getThemeData('#919FC5', Brightness.dark),
  getThemeData('#638190', Brightness.dark),
];
