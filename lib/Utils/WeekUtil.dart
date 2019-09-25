import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../Resources/Config.dart';

class WeekUtil {
  static checkWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String lastMondayString = sp.getString("lastWeekMonday");
    String thisMondayString = _getMonday();
    DateTime thisMonday = DateTime.parse(_getMonday());
    if (lastMondayString == null) {
      // For test
//      String testMondayString = '2019-08-26';
//      await _initWeek(testMondayString, 1);
//      lastMondayString = testMondayString;

      // 如果在本学期内，则按本学期学期开始更新周数
      // 如果字符串已经过期，则重置当前周数为第一周
      if (thisMonday
                  .difference(DateTime.parse(Config.SEMESTER_START_MONDAY))
                  .inDays ~/
              7 <
          Config.MAX_WEEKS) {
        await _initWeek(Config.SEMESTER_START_MONDAY, 1);
        lastMondayString = Config.SEMESTER_START_MONDAY;
      } else {
        await _initWeek(thisMondayString, 1);
        return;
      }
    }
//      print(lastMondayString);
    DateTime lastMonday = DateTime.parse(lastMondayString);
    int weekBias = thisMonday.difference(lastMonday).inDays ~/ 7;
//      print('$weekBias weeks');
    if (weekBias != 0) await _setWeek(thisMondayString, weekBias);
  }

  static setNowWeek(int weekNum) async {
    String monday = _getMonday();
    await _initWeek(monday, weekNum);
  }

  static int getNowMonth() {
//    DateTime now = new DateTime(2019,10,1);
    DateTime now = new DateTime.now();
    return now.month;
  }

  static String getNowMonthName() {
    DateTime now = new DateTime.now();
    var formatter = new DateFormat('MMM');
    return formatter.format(now);
  }

  static List<String> getDayList() {
    List<String> result = [];
    int monday = 1;
    DateTime now = new DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(new Duration(days: 1));
    }
    var formatter = new DateFormat('MM/dd');
    for (int i = 0; i < 7; i++) {
      String formatted = formatter.format(now);
      result.add(formatted);
      now = now.add(new Duration(days: 1));
    }
    return result;
  }

  static int getWeekDay() {
    DateTime now = new DateTime.now();
    return now.weekday;
  }
  
  static int getTmpMonth(int biasWeek){
    DateTime now = new DateTime.now();
    now = now.add(Duration(days: biasWeek * 7));
    return now.month;
  }

  static String getTmpMonthName(int biasWeek) {
    DateTime now = new DateTime.now();
    now = now.add(Duration(days: biasWeek * 7));
    var formatter = new DateFormat('MMM');
    return formatter.format(now);
  }

  static List<String> getTmpDayList(int biasWeek) {
    List<String> result = [];
    int monday = 1;
    DateTime now = new DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(new Duration(days: 1));
    }
    now = now.add(Duration(days: biasWeek * 7));
    var formatter = new DateFormat('MM/dd');
    for (int i = 0; i < 7; i++) {
      String formatted = formatter.format(now);
      result.add(formatted);
      now = now.add(new Duration(days: 1));
    }
    return result;
  }

  static String _getMonday() {
    int monday = 1;
    DateTime now = new DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(new Duration(days: monday));
    }

    var formatter = new DateFormat('yyyy-MM-dd');
    String formatted = formatter.format(now);

//    print('Recent monday $formatted');
    return formatted;
  }

  static _setWeek(String monday, int bias) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("lastWeekMonday", monday);
    int nowWeek = await sp.getInt('weekIndex');
    await sp.setInt('weekIndex', nowWeek + bias);
  }

  static _initWeek(String monday, int week) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("lastWeekMonday", monday);
    await sp.setInt('weekIndex', week);
  }
}
