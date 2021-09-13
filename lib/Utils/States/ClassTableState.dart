import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ClassTableStateModel extends Model {
  int? _classTableIndex;

  get classTableIndex => _classTableIndex;

  Future<bool> changeclassTable(int classTableIndex) async {
    _classTableIndex = classTableIndex;
    notifyListeners();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt("tableId", classTableIndex);
    return true;
  }

  Future<int> getClassTable() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? classTableIndex = sp.getInt("tableId");
    if (classTableIndex != null) {
      return classTableIndex;
    }
    return 0;
  }
}