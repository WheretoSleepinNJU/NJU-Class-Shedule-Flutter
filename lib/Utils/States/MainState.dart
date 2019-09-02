import 'package:scoped_model/scoped_model.dart';
import './ThemeState.dart';
import './ClassTableState.dart';

class MainStateModel extends Model with ThemeStateModel, ClassTableStateModel{
  static MainStateModel of(context) => ScopedModel.of<MainStateModel>(context, rebuildOnChange: true);
}