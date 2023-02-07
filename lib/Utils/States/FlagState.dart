import 'package:scoped_model/scoped_model.dart';

mixin FlagStateModel on Model {
  void refresh() {
    notifyListeners();
  }
}
