import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigStateModel extends Model {
  bool _showWeekend = true;
  bool _showClassTime = true;
  bool _showFreeClass = true;
  bool _showMonth = true;
  int _classHeight = 50;
  bool _showDate = true;
  bool _forceZoom = false;
  bool _addButton = false;
  bool _whiteMode = false;
  String? _bgImgPath = "";
  int _lastCheckUpdateTime = 0;
  int _coolDownTime = 600;

  void setShowWeekend(bool showWeekend) async {
    _showWeekend = showWeekend;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showWeekend", _showWeekend);
  }

  Future<bool> getShowWeekend() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? showWeekend = sp.getBool("showWeekend");
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
    bool? showClassTime = sp.getBool("showClassTime");
    if (showClassTime != null) {
      _showClassTime = showClassTime;
      return showClassTime;
    }
    return _showClassTime;
  }

  void setShowFreeClass(bool showFreeClass) async {
    _showFreeClass = showFreeClass;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showFreeClass", _showFreeClass);
  }

  Future<bool> getShowFreeClass() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? showFreeClass = sp.getBool("showFreeClass");
    if (showFreeClass != null) {
      _showFreeClass = showFreeClass;
      return showFreeClass;
    }
    return _showFreeClass;
  }

  void setShowMonth(bool showMonth) async {
    _showMonth = showMonth;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showMonth", _showMonth);
  }

  Future<bool> getShowMonth() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? showMonth = sp.getBool("showMonth");
    if (showMonth != null) {
      _showMonth = showMonth;
      return showMonth;
    }
    return _showMonth;
  }

  void setClassHeight(int classHeight) async {
    _classHeight = classHeight;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("classHeight", _classHeight);
  }

  Future<int> getClassHeight() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? classHeight = sp.getInt("classHeight");
    if (classHeight != null) {
      _classHeight = classHeight;
      return classHeight;
    }
    return _classHeight;
  }

  void setShowDate(bool showDate) async {
    _showDate = showDate;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("showDate", _showDate);
  }

  Future<bool> getShowDate() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? showDate = sp.getBool("showDate");
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
    bool? forceZoom = sp.getBool("forceZoom");
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
    bool? addButton = sp.getBool("addButton");
    if (addButton != null) {
      _addButton = addButton;
      return addButton;
    }
    return _addButton;
  }

  void setWhiteMode(bool whiteMode) async {
    _whiteMode = whiteMode;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool("whiteMode", _whiteMode);
  }

  Future<bool> getWhiteMode() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    bool? whiteMode = sp.getBool("whiteMode");
    if (whiteMode != null) {
      _whiteMode = whiteMode;
      return whiteMode;
    }
    return _whiteMode;
  }

  Future<bool> setBgImgPath(String bgImgPath) async {
    _bgImgPath = bgImgPath;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString("bgImgPath", _bgImgPath!);
    return true;
  }

  Future<String> getBgImgPath() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? bgImgPath = sp.getString("bgImgPath");
    if (bgImgPath != null) {
      _bgImgPath = bgImgPath;
      return bgImgPath;
    }
    return _bgImgPath!;
  }

  Future<bool> removeBgImgPath() async {
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove("bgImgPath");
    return true;
  }

  Future<int> getLastCheckUpdateTime() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? lastCheckUpdateTime = sp.getInt("lastCheckUpdateTime");
    if (lastCheckUpdateTime != null) {
      _lastCheckUpdateTime = lastCheckUpdateTime;
      return lastCheckUpdateTime;
    }
    return _lastCheckUpdateTime;
  }

  void setLastCheckUpdateTime(int newTime) async {
    _lastCheckUpdateTime = newTime;
    // IMPORTANT: don't notify listeners
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("lastCheckUpdateTime", _lastCheckUpdateTime);
  }

  Future<int> getCoolDownTime() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? coolDownTime = sp.getInt("coolDownTime");
    if (coolDownTime != null) {
      _coolDownTime = coolDownTime;
      return coolDownTime;
    }
    return _coolDownTime;
  }

  void setCoolDownTime(int newTime) async {
    _coolDownTime = newTime;
    // IMPORTANT: don't notify listeners
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("coolDownTime", _coolDownTime);
  }
}
