import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class WeekStateModel extends Model {
  int? _weekIndex;
  int? _tmpWeekIndex;

  get wekIndex => _weekIndex;

  get tmpWeekIndex => _tmpWeekIndex;

  void changeWeek(int weekIndex) async {
    _weekIndex = weekIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("weekIndex", weekIndex);
    // 同时更新 tmpWeekIndex
    sp.setInt("tmpWeekIndex", weekIndex);
  }

  Future<int> getWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? weekIndex = sp.getInt("weekIndex");
    if (weekIndex != null) {
      return weekIndex;
    }
    return 1;
  }

  void changeTmpWeek(int weekIndex) async {
    _tmpWeekIndex = weekIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("tmpWeekIndex", weekIndex);
  }

  Future<int> getTmpWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? tmpWeekIndex = sp.getInt("tmpWeekIndex");
    if (tmpWeekIndex != null) {
      return tmpWeekIndex;
    }
    // 默认给 weekIndex
    return getWeek();
  }
}
