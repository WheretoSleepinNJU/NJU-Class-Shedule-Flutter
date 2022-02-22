import 'package:flutter/material.dart';
import 'Config.dart';

class Constant {
  static const List<String> WEEK_WITH_BIAS = [
    "",
    "周一",
    "周二",
    "周三",
    "周四",
    "周五",
    "周六",
    "周日"
  ];
  static const List<String> WEEK_WITHOUT_BIAS = [
    "周一",
    "周二",
    "周三",
    "周四",
    "周五",
    "周六",
    "周日"
  ];
  static const List<String> WEEK_WITHOUT_BIAS_WITHOUT_PRE = [
    "一",
    "二",
    "三",
    "四",
    "五",
    "六",
    "日"
  ];

  static const List<Map> CLASS_TIME_LIST = [
    {"start": "08:00", "end": "08:50"},
    {"start": "09:00", "end": "09:50"},
    {"start": "10:10", "end": "11:00"},
    {"start": "11:10", "end": "12:00"},
    {"start": "14:00", "end": "14:50"},
    {"start": "15:00", "end": "15:50"},
    {"start": "16:10", "end": "17:00"},
    {"start": "17:10", "end": "18:00"},
    {"start": "18:30", "end": "19:20"},
    {"start": "19:30", "end": "20:20"},
    {"start": "20:30", "end": "21:20"},
    {"start": "21:30", "end": "22:20"},
    {"start": "22:30", "end": "23:59"},
  ];

  static const int LOGIN_CORRECT = 0;
  static const int PASSWORD_ERROR = 1;
  static const int CAPTCHA_ERROR = 2;
  static const int USERNAME_ERROR = 3;

  static const int ADD_MANUALLY = 0;
  static const int ADD_BY_IMPORT = 1;
  static const int ADD_BY_LECTURE = 2;

  static const int DEFAULT_WEEK_START = 1;
  static const int DEFAULT_WEEK_END = Config.DEFAULT_WEEK_NUM;
  static const int DEFAULT_WEEK_NUM = Config.DEFAULT_WEEK_NUM;

  static const int FULL_WEEKS = 0;
  static const int SINGLE_WEEKS = 1;
  static const int DOUBLE_WEEKS = 2;
  static const int DEFINED_WEEKS = 3;

  //TODO: add 自定义
  static const List<String> WEEK_TYPES = ['全部', '单周', '双周'];

  static const themeModeList = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark
  ];
}
