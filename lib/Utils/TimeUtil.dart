import 'package:intl/intl.dart';
import '../Resources/Constant.dart';

class TimeUtil {
  Map getClassTime(DateTime startTime, DateTime endTime) {
    var simpleFormatter = new DateFormat('HH:mm');
    String startTimeStr = simpleFormatter.format(startTime);
    String endTimeStr = simpleFormatter.format(endTime);
    int startTimeInt = 0;
    int endTimeInt = 0;
    Constant.CLASS_TIME_LIST.asMap().forEach((i, v) {
      if(startTimeStr == v['start']) startTimeInt = i + 1;
      if(endTimeStr == v['end']) endTimeInt = i + 1;
    });
    if(startTimeInt != 0 && endTimeInt != 0) {
      return {
        'startTime': startTimeInt,
        'timeCount': endTimeInt - startTimeInt,
        'isStrict': true
      };
    }
    return {
      'startTime': 5,
      'timeCount': 1,
      'isStrict': false
    };
  }
}