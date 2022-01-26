import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WeekUtil {
  static checkWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? lastMondayString = sp.getString("lastWeekMonday");
    String thisMondayString = _getMonday();
    DateTime thisMonday = DateTime.parse(thisMondayString);
    // print(lastMondayString);
    if (lastMondayString == null) {
      await _initWeek(thisMondayString, 1);
    } else{
      DateTime lastMonday = DateTime.parse(lastMondayString);
      int weekBias = thisMonday.difference(lastMonday).inDays ~/ 7;
      if (weekBias != 0) await _setWeek(thisMondayString, weekBias);
    }
  }

  static setNowWeek(int weekNum) async {
    String monday = _getMonday();
    await _initWeek(monday, weekNum);
  }

  static initWeek(String monday, int week) async {
    String thisMondayString = _getMonday();
    DateTime thisMonday = DateTime.parse(thisMondayString);
    DateTime lastMonday = DateTime.parse(monday);
    int weekBias = thisMonday.difference(lastMonday).inDays ~/ 7;
    await _initWeek(thisMondayString, weekBias + 1);
  }

  static isSameWeek(String monday, int index) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? lastMondayString = sp.getString("lastWeekMonday");
    DateTime lastMonday = DateTime.parse(lastMondayString!);
    int? lastIndex = sp.getInt("weekIndex");
    DateTime thisMonday = DateTime.parse(monday);
    int weekBias = thisMonday.difference(lastMonday).inDays ~/ 7;
    return (weekBias == index - lastIndex!);
  }

  static int getNowMonth() {
//    DateTime now = new DateTime(2019,10,1);
    DateTime now = DateTime.now();
    return now.month;
  }

  static String getNowMonthName() {
    DateTime now = DateTime.now();
    var formatter = DateFormat('MMM');
    return formatter.format(now);
  }

  static List<String> getDayList() {
    List<String> result = [];
    int monday = 1;
    DateTime now = DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(const Duration(days: 1));
    }
    var formatter = DateFormat('MM/dd');
    for (int i = 0; i < 7; i++) {
      String formatted = formatter.format(now);
      result.add(formatted);
      now = now.add(const Duration(days: 1));
    }
    return result;
  }

  static int getWeekDay() {
    DateTime now = DateTime.now();
    return now.weekday;
  }

  static int getTmpMonth(int biasWeek) {
    DateTime now = DateTime.now();
    now = now.add(Duration(days: biasWeek * 7));
    return now.month;
  }

  static String getTmpMonthName(int biasWeek) {
    DateTime now = DateTime.now();
    now = now.add(Duration(days: biasWeek * 7));
    var formatter = DateFormat('MMM');
    return formatter.format(now);
  }

  static List<String> getTmpDayList(int biasWeek) {
    List<String> result = [];
    int monday = 1;
    DateTime now = DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(const Duration(days: 1));
    }
    now = now.add(Duration(days: biasWeek * 7));
    var formatter = DateFormat('MM/dd');
    for (int i = 0; i < 7; i++) {
      String formatted = formatter.format(now);
      result.add(formatted);
      now = now.add(const Duration(days: 1));
    }
    return result;
  }

  static Future<int> getWeekNumOfDay(DateTime dateTime) async {
    int monday = 1;
    while (dateTime.weekday != monday) {
      dateTime = dateTime.subtract(const Duration(days: 1));
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? lastMondayString = sp.getString("lastWeekMonday");
    DateTime lastMonday = DateTime.parse(lastMondayString!);
    int lastIndex = sp.getInt("weekIndex") ?? 0;
    int weekBias = dateTime.difference(lastMonday).inDays ~/ 7;
    return lastIndex + weekBias;
  }

  static String _getMonday() {
    int monday = 1;
    DateTime now = DateTime.now();

    while (now.weekday != monday) {
      now = now.subtract(Duration(days: monday));
    }

    var formatter = DateFormat('yyyy-MM-dd');
    String formatted = formatter.format(now);

//    print('Recent monday $formatted');
    return formatted;
  }

  static _setWeek(String monday, int bias) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("lastWeekMonday", monday);
    int? nowWeek = sp.getInt('weekIndex');
    await sp.setInt('weekIndex', nowWeek! + bias);
    await sp.setInt('tmpWeekIndex', nowWeek + bias);
  }

  static _initWeek(String monday, int week) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString("lastWeekMonday", monday);
    await sp.setInt('weekIndex', week);
    if (week < 1) {
      await sp.setInt("tmpWeekIndex", 1);
    } else {
      await sp.setInt("tmpWeekIndex", week);
    }
  }
}
