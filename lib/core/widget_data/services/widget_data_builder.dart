import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_schedule_data.dart';
import 'unified_data_service.dart';

/// Compatibility entry point; use the same source, time template and week
/// selection as native widget refreshes.
class WidgetDataBuilder {
  final SharedPreferences preferences;
  WidgetDataBuilder({required this.preferences});

  Future<WidgetScheduleData> buildWidgetData() =>
      UnifiedDataService(preferences: preferences).getWidgetData();
}
