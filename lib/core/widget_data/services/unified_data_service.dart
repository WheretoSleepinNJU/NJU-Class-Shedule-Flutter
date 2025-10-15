import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/widget_schedule_data.dart';
import '../models/live_activity_data.dart';
import '../models/school_time_template.dart';
import '../models/widget_course.dart';
import '../exporters/unified_exporter.dart';
import '../communication/native_data_bridge.dart';
import '../../../Models/CourseModel.dart';
import '../../../Models/ScheduleModel.dart';

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

  /// 构建 Widget 数据（从真实数据源）
  Future<WidgetScheduleData> _buildWidgetScheduleData() async {
    try {
      // 1. 获取当前课程表ID
      final currentTableId = _preferences.getInt('tableId') ?? 0;
      
      // 2. 获取当前周次（使用现有逻辑）
      final currentWeek = _preferences.getInt('weekIndex') ?? 1;
      
      // 3. 获取学校信息
      final schoolId = _preferences.getString('school_id') ?? 'nju';
      final schoolName = _getSchoolName(schoolId);
      final timeTemplate = _getTimeTemplate(schoolId);
      
      // 4. 获取所有课程数据
      final courseProvider = CourseProvider();
      final allCoursesMaps = await courseProvider.getAllCourses(currentTableId);
      final allCourses = allCoursesMaps.map((map) => Course.fromMap(map)).toList();
      
      // 5. 使用现有逻辑分类课程
      final scheduleModel = ScheduleModel(allCourses, currentWeek);
      scheduleModel.init();
      
      // 6. 计算今日课程
      final currentWeekDay = DateTime.now().weekday;
      final todayCourses = _filterCoursesForDay(scheduleModel.activeCourses, currentWeekDay);
      
      // 7. 计算明日课程
      final tomorrowWeekDay = currentWeekDay == 7 ? 1 : currentWeekDay + 1;
      final tomorrowWeek = currentWeekDay == 7 ? currentWeek + 1 : currentWeek;
      final tomorrowCourses = _filterCoursesForTomorrow(allCourses, tomorrowWeek, tomorrowWeekDay);
      
      // 8. 计算当前课程和下一节课
      final now = DateTime.now();
      final currentCourse = _getCurrentCourse(todayCourses, now, timeTemplate);
      final nextCourse = _getNextCourse(todayCourses, now, timeTemplate);
      
      // 9. 构建周课表
      final weekSchedule = _buildWeekSchedule(scheduleModel.activeCourses);
      
      // 10. 转换为 Widget 格式
      final widgetTodayCourses = todayCourses.map((c) => _convertToWidgetCourse(c, schoolId)).toList();
      final widgetTomorrowCourses = tomorrowCourses.map((c) => _convertToWidgetCourse(c, schoolId)).toList();
      final widgetCurrentCourse = currentCourse != null ? _convertToWidgetCourse(currentCourse, schoolId) : null;
      final widgetNextCourse = nextCourse != null ? _convertToWidgetCourse(nextCourse, schoolId) : null;
      
      return WidgetScheduleData(
        version: '1.0',
        timestamp: DateTime.now(),
        schoolId: schoolId,
        schoolName: schoolName,
        timeTemplate: timeTemplate,
        currentWeek: currentWeek,
        currentWeekDay: currentWeekDay,
        semesterName: '${DateTime.now().year}学年',
        todayCourses: widgetTodayCourses,
        tomorrowCourses: widgetTomorrowCourses,
        nextCourse: widgetNextCourse,
        currentCourse: widgetCurrentCourse,
        weekSchedule: _convertWeekScheduleToWidget(weekSchedule, schoolId),
        todayCourseCount: widgetTodayCourses.length,
        tomorrowCourseCount: widgetTomorrowCourses.length,
        weekCourseCount: scheduleModel.activeCourses.length,
        hasCoursesToday: widgetTodayCourses.isNotEmpty,
        hasCoursesTomorrow: widgetTomorrowCourses.isNotEmpty,
        dataSource: 'sqlite',
        totalCourses: allCourses.length,
        lastUpdateTime: DateTime.now(),
      );
    } catch (e) {
      print('Error building widget data: $e');
      return _createEmptyData();
    }
  }
  
  /// 筛选今日课程
  List<Course> _filterCoursesForDay(List<Course> activeCourses, int weekDay) {
    final filtered = activeCourses.where((course) => course.weekTime == weekDay).toList();
    // 按开始时间排序
    filtered.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    return filtered;
  }
  
  /// 筛选明日课程（需要重新计算周次）
  List<Course> _filterCoursesForTomorrow(List<Course> allCourses, int tomorrowWeek, int tomorrowWeekDay) {
    final filtered = allCourses.where((course) {
      if (course.weekTime != tomorrowWeekDay) return false;
      
      // 检查明日周次是否包含在课程周次中
      if (course.weeks == null) return false;
      
      try {
        final weeks = json.decode(course.weeks!);
        return weeks.contains(tomorrowWeek);
      } catch (e) {
        return false;
      }
    }).toList();
    
    filtered.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    return filtered;
  }
  
  /// 获取当前正在上的课程
  Course? _getCurrentCourse(List<Course> todayCourses, DateTime now, SchoolTimeTemplate timeTemplate) {
    final currentPeriod = _getCurrentPeriod(now, timeTemplate);
    if (currentPeriod == 0) return null;
    
    for (final course in todayCourses) {
      final startPeriod = course.startTime ?? 0;
      final endPeriod = startPeriod + (course.timeCount ?? 1) - 1;
      
      if (currentPeriod >= startPeriod && currentPeriod <= endPeriod) {
        return course;
      }
    }
    
    return null;
  }
  
  /// 获取下一节课
  Course? _getNextCourse(List<Course> todayCourses, DateTime now, SchoolTimeTemplate timeTemplate) {
    final currentPeriod = _getCurrentPeriod(now, timeTemplate);
    
    for (final course in todayCourses) {
      final startPeriod = course.startTime ?? 0;
      if (startPeriod > currentPeriod) {
        return course;
      }
    }
    
    return null;
  }
  
  /// 获取当前节次（基于时间模板）
  int _getCurrentPeriod(DateTime now, SchoolTimeTemplate timeTemplate) {
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;
    
    for (int i = 0; i < timeTemplate.periods.length; i++) {
      final period = timeTemplate.periods[i];
      final startMinutes = _parseTimeToMinutes(period.startTime);
      final endMinutes = _parseTimeToMinutes(period.endTime);
      
      if (totalMinutes >= startMinutes && totalMinutes <= endMinutes) {
        return i + 1;
      }
    }
    
    return 0; // 非上课时间
  }
  
  /// 解析时间为分钟数
  int _parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return hour * 60 + minute;
      }
    } catch (e) {
      // ignore
    }
    return 0;
  }
  
  /// 构建周课表
  Map<int, List<Course>> _buildWeekSchedule(List<Course> activeCourses) {
    final schedule = <int, List<Course>>{};
    
    // 初始化 1-7
    for (int i = 1; i <= 7; i++) {
      schedule[i] = [];
    }
    
    // 填充课程
    for (final course in activeCourses) {
      if (course.weekTime != null && course.weekTime! >= 1 && course.weekTime! <= 7) {
        schedule[course.weekTime!]?.add(course);
      }
    }
    
    // 排序
    for (final courses in schedule.values) {
      courses.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    }
    
    return schedule;
  }
  
  /// 转换为 Widget 课程格式
  WidgetCourse _convertToWidgetCourse(Course course, String schoolId) {
    final courseId = 'course_${course.id ?? 0}_${course.weekTime}_${course.startTime}';
    
    // 解析周次列表
    List<int> weeksList = [];
    if (course.weeks != null) {
      try {
        final weeks = json.decode(course.weeks!);
        weeksList = List<int>.from(weeks);
      } catch (e) {
        // ignore
      }
    }
    
    return WidgetCourse(
      id: courseId,
      name: course.name ?? '未知课程',
      classroom: course.classroom,
      teacher: course.teacher,
      startPeriod: course.startTime ?? 1,
      periodCount: course.timeCount ?? 1,
      weekDay: course.weekTime ?? 1,
      color: course.color,
      schoolId: schoolId,
      weeks: weeksList,
      courseType: course.importType == 1 ? 'import' : 'manual',
      notes: course.info,
    );
  }
  
  /// 转换周课表格式
  Map<int, List<WidgetCourse>> _convertWeekScheduleToWidget(
    Map<int, List<Course>> schedule,
    String schoolId,
  ) {
    final widgetSchedule = <int, List<WidgetCourse>>{};
    
    for (final entry in schedule.entries) {
      final widgetCourses = entry.value
          .map((c) => _convertToWidgetCourse(c, schoolId))
          .toList();
      widgetSchedule[entry.key] = widgetCourses;
    }
    
    return widgetSchedule;
  }
  
  /// 获取学校名称
  String _getSchoolName(String schoolId) {
    switch (schoolId) {
      case 'seu':
        return '东南大学';
      case 'nju':
      default:
        return '南京大学';
    }
  }
  
  /// 创建空数据
  WidgetScheduleData _createEmptyData() {
    final schoolId = _preferences.getString('school_id') ?? 'nju';
    final schoolName = _getSchoolName(schoolId);
    
    return WidgetScheduleData(
      version: '1.0',
      timestamp: DateTime.now(),
      schoolId: schoolId,
      schoolName: schoolName,
      timeTemplate: _getTimeTemplate(schoolId),
      currentWeek: 1,
      currentWeekDay: DateTime.now().weekday,
      semesterName: '${DateTime.now().year}学年',
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
      dataSource: 'empty',
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
