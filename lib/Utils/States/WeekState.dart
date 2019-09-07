import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class WeekStateModel extends Model {
  int _weekIndex;

  get wekIndex => _weekIndex;

  void changeWeek(int weekIndex) async {
    _weekIndex = weekIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("weekIndex", weekIndex);
  }

  Future<int> getWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int weekIndex = sp.getInt("weekIndex");
    if (weekIndex != null) {
      return weekIndex;
    }
    return 1;
  }


}
