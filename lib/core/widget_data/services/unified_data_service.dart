import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_schedule_data.dart';
import '../models/live_activity_data.dart';
import '../models/school_time_template.dart';
import '../exporters/unified_exporter.dart';
import '../communication/native_data_bridge.dart';

/// 统一数据服务
/// 为 Widget 和 Live Activity 提供数据支持
/// 这是一个简化版本，具体实现需要根据实际数据源集成
class UnifiedDataService {
  final SharedPreferences _preferences;
  final NativeDataBridge _bridge;

  /// 缓存机制
  final Map<String, dynamic> _cache = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  DateTime? _lastCacheUpdate;

  UnifiedDataService({
    required SharedPreferences preferences,
    NativeDataBridge? bridge,
  }) : _preferences = preferences,
       _bridge = bridge ?? NativeDataBridge();

  /// 获取 Widget 显示数据
  /// 注意：这是示例实现，需要根据实际数据源（数据库、状态管理等）进行调整
  Future<WidgetScheduleData> getWidgetData() async {
    const cacheKey = 'widget_data';
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as WidgetScheduleData;
    }

    final data = await _buildWidgetScheduleData();
    _cache[cacheKey] = data;
    return data;
  }

  /// 获取 Live Activity 数据
  Future<List<LiveActivityData>> getLiveActivityData() async {
    // 示例实现：返回空列表
    // 实际实现需要根据即将开始的课程生成 LiveActivityData
    return [];
  }

  /// 导出平台特定数据
  Future<Map<String, dynamic>> exportPlatformData({
    required String platform,
  }) async {
    final widgetData = await getWidgetData();
    final liveActivities = await getLiveActivityData();

    return UnifiedDataExporter.exportPlatformData(
      platform: platform,
      widgetData: widgetData,
      liveActivities: liveActivities,
    );
  }

  /// 发送数据到原生端
  Future<bool> sendToNative({
    WidgetScheduleData? widgetData,
    List<LiveActivityData>? liveActivities,
  }) async {
    widgetData ??= await getWidgetData();
    liveActivities ??= await getLiveActivityData();

    return await _bridge.sendUnifiedDataPackage(
      widgetData: widgetData,
      liveActivities: liveActivities,
    );
  }

  /// 更新 Widget 数据
  Future<bool> updateWidgetData() async {
    try {
      final data = await getWidgetData();
      return await _bridge.sendWidgetData(data);
    } catch (e) {
      return false;
    }
  }

  /// 更新 Live Activity 数据
  Future<bool> updateLiveActivityData() async {
    try {
      final activities = await getLiveActivityData();
      return await _bridge.sendLiveActivityData(activities);
    } catch (e) {
      return false;
    }
  }

  /// 构建 Widget 数据（示例实现）
  Future<WidgetScheduleData> _buildWidgetScheduleData() async {
    // 这里需要从实际数据源获取课程数据
    // 示例实现：返回空数据
    final schoolId = _preferences.getString('school_id') ?? 'nju';
    final template = _getTimeTemplate(schoolId);

    return WidgetScheduleData(
      version: '1.0',
      timestamp: DateTime.now(),
      schoolId: schoolId,
      schoolName: template.schoolName,
      timeTemplate: template,
      currentWeek: 1,
      currentWeekDay: DateTime.now().weekday,
      semesterName: '2024-2025学年第一学期',
      todayCourses: [],
      tomorrowCourses: [],
      nextCourse: null,
      currentCourse: null,
      weekSchedule: {},
      todayCourseCount: 0,
      tomorrowCourseCount: 0,
      weekCourseCount: 0,
      hasCoursesToday: false,
      hasCoursesTomorrow: false,
      dataSource: 'local',
      totalCourses: 0,
      lastUpdateTime: DateTime.now(),
    );
  }

  /// 获取学校时间模板
  SchoolTimeTemplate _getTimeTemplate(String schoolId) {
    switch (schoolId) {
      case 'seu':
        return SchoolTimeTemplate.southeastUniversity;
      case 'nju':
      default:
        return SchoolTimeTemplate.nanjingUniversity;
    }
  }

  /// 检查缓存是否有效
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    if (_lastCacheUpdate == null) return false;

    final elapsed = DateTime.now().difference(_lastCacheUpdate!);
    return elapsed < _cacheExpiry;
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }

  /// 清除特定缓存
  void clearCacheKey(String key) {
    _cache.remove(key);
  }
}
