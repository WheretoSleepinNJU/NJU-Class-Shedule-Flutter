class Constant {
  static final String database_name = "demo.db";
  static final List<String> WEEK_WITH_BIAS = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"];
  static final List<String> WEEK_WITHOUT_BIAS = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];

  static final int LOGIN_CORRECT = 0;
  static final int PASSWORD_ERROR = 1;
  static final int CAPTCHA_ERROR = 2;

  static final int ADD_MANUALLY = 0;
  static final int ADD_BY_IMPORT = 1;
}