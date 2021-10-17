import 'package:flutter/material.dart';
import '../Utils/ColorUtil.dart';

//final List<Color> themeList = [
//  Colors.black,
//  Colors.red,
//  Colors.teal,
//  Colors.pink,
//  Colors.amber,
//  Colors.orange,
//  Colors.green,
//  Colors.blue,
//  Colors.lightBlue,
//  Colors.purple,
//  Colors.deepPurple,
//  Colors.indigo,
//  Colors.cyan,
//  Colors.brown,
//  Colors.grey,
//  Colors.blueGrey
//];
//
//final List<ThemeData> themeDataList = [
//  ThemeData(
//    primaryColor: HexColor('#0087F1'),
//    secondaryHeaderColor: HexColor('#0095F9'),
//    accentColor: HexColor('#1BA4F9')
//  ),
//  ThemeData(
//      primaryColor: HexColor('#388E3C'),
//      secondaryHeaderColor: HexColor('#4CAF50'),
//      accentColor: HexColor('#8BC34A')
//  ),
//  ThemeData(
//      primaryColor: HexColor('#002060'),
//      secondaryHeaderColor: HexColor('#002B82'),
//      accentColor: HexColor('#203B90')
//  ),
//  ThemeData(
//      primaryColor: HexColor('#661C58'),
//      secondaryHeaderColor: HexColor('#872574'),
//      accentColor: HexColor('#9A4C8D')
//  ),
//  ThemeData(
//      primaryColor: HexColor('#A92F29'),
//      secondaryHeaderColor: HexColor('#C52830'),
//      accentColor: HexColor('#D9434A')
//  ),
//  ThemeData(
//      primaryColor: HexColor('#DDA3B2'),
//      secondaryHeaderColor: HexColor('#BB7F90'),
//      accentColor: HexColor('#EAC8D1'),
//      primaryColorBrightness: Brightness.dark
//  ),
//  ThemeData(
//    primaryColor: HexColor('#26637E'),
//    secondaryHeaderColor: HexColor('#2D7D93'),
//    accentColor: HexColor('#23A2AF'),
//  ),
//  ThemeData(
//    primaryColor: HexColor('#7D83B9'),
//    secondaryHeaderColor: HexColor('#919FC5'),
//    accentColor: HexColor('#A6B4CA'),
//  ),
//  ThemeData(
//    primaryColor: HexColor('#3C5A64'),
//    secondaryHeaderColor: HexColor('#638190'),
//    accentColor: HexColor('#9E9E9E'),
//  ),
//];

final List<ThemeData> themeDataList = [
  ThemeData(
    primaryColor: HexColor('#0095F9'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#1BA4F9')),
    appBarTheme: AppBarTheme(
      color: HexColor('#0095F9'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#4CAF50'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#8BC34A')),
    appBarTheme: AppBarTheme(
      color: HexColor('#4CAF50'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#002B82'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#203B90')),
    appBarTheme: AppBarTheme(
      color: HexColor('#002B82'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#872574'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#9A4C8D')),
    appBarTheme: AppBarTheme(
      color: HexColor('#872574'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#C52830'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#D9434A')),
    appBarTheme: AppBarTheme(
      color: HexColor('#C52830'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#DDA3B2'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#EAC8D1')),
    appBarTheme: AppBarTheme(
      color: HexColor('#DDA3B2'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#2D7D93'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#23A2AF')),
    appBarTheme: AppBarTheme(
      color: HexColor('#2D7D93'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#919FC5'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#A6B4CA')),
    appBarTheme: AppBarTheme(
      color: HexColor('#919FC5'),
    ),
  ),
  ThemeData(
    primaryColor: HexColor('#638190'),
    primaryColorBrightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSwatch().copyWith(secondary: HexColor('#9E9E9E')),
    appBarTheme: AppBarTheme(
      color: HexColor('#638190'),
    ),
  ),
];
