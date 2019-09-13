import 'package:scoped_model/scoped_model.dart';

abstract class FlagStateModel extends Model {
  void refresh() {
    notifyListeners();
  }
}