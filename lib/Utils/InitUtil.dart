import 'package:shared_preferences/shared_preferences.dart';
import '../Models/CourseTableModel.dart';
import '../Resources/Config.dart';
import '../Utils/ColorUtil.dart';
import '../Utils/WeekUtil.dart';

class InitUtil {
  static Future<int> Initialize() async {
    int themeIndex = await getTheme();
    await checkDataBase();
    await WeekUtil.checkWeek();
    await ColorPool.checkColorPool();
    return themeIndex;
  }

  static Future<int> getTheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int themeIndex = sp.getInt("themeIndex");
    if (themeIndex != null) {
      return themeIndex;
    }
    return 0;
  }

  static checkDataBase() async {
    CourseTableProvider courseTableProvider = new CourseTableProvider();
    List c = await courseTableProvider.getAllCourseTable();
    if (c.isEmpty) courseTableProvider.insert(
        new CourseTable(Config.default_class_table));
  }
}