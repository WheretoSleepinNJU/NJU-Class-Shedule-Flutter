class Constant {
  static final String database_name = "demo.db";
  static final List<String> WEEK_WITH_BIAS = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"];
  static final List<String> WEEK_WITHOUT_BIAS = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];

  static final int LOGIN_CORRECT = 0;
  static final int PASSWORD_ERROR = 1;
  static final int CAPTCHA_ERROR = 2;

  static final int ADD_MANUALLY = 0;
  static final int ADD_BY_IMPORT = 1;

  static final int DEFAULT_WEEK_START = 1;
  static final int DEFAULT_WEEK_END = 17;
  static final int DEFAULT_WEEK_NUM = 17;

  static final int FULL_WEEKS = 0;
  static final int SINGLE_WEEKS = 1;
  static final int DOUBLE_WEEKS = 2;
  static final int DEFINED_WEEKS = 3;
  //TODO: add 自定义
  static final List<String> WEEK_TYPES = ['全部', '单周', '双周'];

  static final String SEMESTER_START_MONDAY = '2019-09-02';
  static final int MAX_WEEKS = 20;
}