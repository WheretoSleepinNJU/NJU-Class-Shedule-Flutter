import 'package:scoped_model/scoped_model.dart';
import './ThemeState.dart';
import './ClassTableState.dart';
import './WeekState.dart';

class MainStateModel extends Model with ThemeStateModel, ClassTableStateModel, WeekStateModel{
  static MainStateModel of(context) => ScopedModel.of<MainStateModel>(context, rebuildOnChange: true);
}