import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigStateModel extends Model {
  bool _showWeekend = true;
  bool _showClassTime = false;
  bool _showMonth = false;
  bool _showDate = false;
  bool _forceZoom = false;
  bool _addButton = false;

  void setShowWeekend(bool showWeekend) async {
    _showWeekend = showWeekend;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showWeekend", _showWeekend);
  }

  Future<bool> getShowWeekend() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool showWeekend = sp.getBool("showWeekend");
    if (showWeekend != null) {
      _showWeekend = showWeekend;
      return showWeekend;
    }
    return _showWeekend;
  }

  void setShowClassTime(bool showClassTime) async {
    _showClassTime = showClassTime;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showClassTime", _showClassTime);
  }

  Future<bool> getShowClassTime() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool showClassTime = sp.getBool("showClassTime");
    if (showClassTime != null) {
      _showClassTime = showClassTime;
      return showClassTime;
    }
    return _showClassTime;
  }

  void setShowMonth(bool showMonth) async {
    _showMonth = showMonth;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showMonth", _showMonth);
  }

  Future<bool> getShowMonth() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool showMonth = sp.getBool("showMonth");
    if (showMonth != null) {
      _showMonth = showMonth;
      return showMonth;
    }
    return _showMonth;
  }

  void setShowDate(bool showDate) async {
    _showDate = showDate;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showDate", _showDate);
  }

  Future<bool> getShowDate() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool showDate = sp.getBool("showDate");
    if (showDate != null) {
      _showDate = showDate;
      return showDate;
    }
    return _showDate;
  }

  void setForceZoom(bool forceZoom) async {
    _forceZoom = forceZoom;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("forceZoom", _forceZoom);
  }

  Future<bool> getForceZoom() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool forceZoom = sp.getBool("forceZoom");
    if (forceZoom != null) {
      _forceZoom = forceZoom;
      return forceZoom;
    }
    return _forceZoom;
  }
  void setAddButton(bool addButton) async {
    _addButton = addButton;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("addButton", _addButton);
  }

  Future<bool> getAddButton() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool addButton = sp.getBool("addButton");
    if (addButton != null) {
      _addButton = addButton;
      return addButton;
    }
    return _addButton;
  }
}
