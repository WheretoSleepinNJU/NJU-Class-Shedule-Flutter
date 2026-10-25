import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';
import '../WeekUtil.dart';

mixin WeekStateModel on Model {
  int? _weekIndex;
  int? _tmpWeekIndex;

  get wekIndex => _weekIndex;

  get tmpWeekIndex => _tmpWeekIndex;

  Future<void> changeWeek(int weekIndex) async {
    await WeekUtil.setNowWeek(weekIndex);
    _weekIndex = weekIndex;
    _tmpWeekIndex = weekIndex;
    notifyListeners();

    // 刷新 Widget
    await WidgetRefreshHelper.refreshAfterWeekChanged();
  }

  Future<int> getWeek() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? weekIndex = sp.getInt("weekIndex");
    if (weekIndex != null) {
      return weekIndex;
    }
    return 1;
  }

  Future<void> changeTmpWeek(int weekIndex) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setInt("tmpWeekIndex", weekIndex);
    _tmpWeekIndex = weekIndex;
    notifyListeners();
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
