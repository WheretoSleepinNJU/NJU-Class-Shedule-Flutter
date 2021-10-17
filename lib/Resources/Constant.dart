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

  static const List<String> CLASS_TIME = [
    "08:00\n08:50",
    "09:00\n09:50",
    "10:10\n11:00",
    "11:10\n12:00",
    "14:00\n14:50",
    "15:00\n15:50",
    "16:10\n17:00",
    "17:10\n18:00",
    "18:30\n19:20",
    "19:30\n20:20",
    "20:30\n21:20",
    "21:30\n22:20",
    "22:30"
  ];

  static const int LOGIN_CORRECT = 0;
  static const int PASSWORD_ERROR = 1;
  static const int CAPTCHA_ERROR = 2;
  static const int USERNAME_ERROR = 3;

  static const int ADD_MANUALLY = 0;
  static const int ADD_BY_IMPORT = 1;

  static const int DEFAULT_WEEK_START = 1;
  static const int DEFAULT_WEEK_END = Config.DEFAULT_WEEK_NUM;
  static const int DEFAULT_WEEK_NUM = Config.DEFAULT_WEEK_NUM;

  static const int FULL_WEEKS = 0;
  static const int SINGLE_WEEKS = 1;
  static const int DOUBLE_WEEKS = 2;
  static const int DEFINED_WEEKS = 3;

  //TODO: add 自定义
  static const List<String> WEEK_TYPES = ['全部', '单周', '双周'];
}
