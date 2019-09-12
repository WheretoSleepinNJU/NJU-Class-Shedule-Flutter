import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../Resources/Constant.dart';

class WeekUtil{

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
      if(thisMonday.difference(DateTime.parse(Constant.SEMESTER_START_MONDAY)).inDays ~/ 7 < Constant.MAX_WEEKS){
        await _initWeek(Constant.SEMESTER_START_MONDAY, 1);
        lastMondayString =Constant.SEMESTER_START_MONDAY;
      }else{
        await _initWeek(thisMondayString, 1);
        return;
      }
    }
//      print(lastMondayString);
    DateTime lastMonday = DateTime.parse(lastMondayString);
    int weekBias = thisMonday.difference(lastMonday).inDays ~/ 7;
//      print('$weekBias weeks');
    if(weekBias != 0) await _setWeek(thisMondayString, weekBias);
  }

  static setNowWeek(int weekNum) async{
    String monday = _getMonday();
    await _initWeek(monday, weekNum);
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