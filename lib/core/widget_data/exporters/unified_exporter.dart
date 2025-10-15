import 'dart:convert';
import 'dart:io';
import '../models/widget_schedule_data.dart';
import '../models/live_activity_data.dart';
import '../models/widget_course.dart';

/// 统一数据导出器
/// 为不同平台（iOS、Android、HarmonyOS）提供标准化的数据导出格式
class UnifiedDataExporter {
  static const String VERSION = '1.0';
  static const int MAX_WIDGET_SIZE = 50 * 1024; // 50KB
  static const int MAX_ACTIVITY_SIZE = 10 * 1024; // 10KB
  static const int MAX_UNIFIED_SIZE = 100 * 1024; // 100KB

  /// 导出 Widget 专用数据包
  static Map<String, dynamic> exportWidgetData(WidgetScheduleData data) {
    // 确保数据大小在限制范围内
    final widgetJson = data.toJson();
    final size = _calculateJsonSize(widgetJson);
    
    if (size > MAX_WIDGET_SIZE) {
      // 数据过大，进行裁剪
      final trimmedData = _trimWidgetData(data);
      return _createWidgetPackage(trimmedData);
    }
    
    return _createWidgetPackage(data);
  }

  /// 导出 Live Activity 专用数据包
  static Map<String, dynamic> exportLiveActivityData(List<LiveActivityData> activities) {
    final package = {
      'type': 'live_activity_data',
      'version': VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'universal',
      'data': {
        'activities': activities.map((a) => a.toJson()).toList(),
        'count': activities.length,
        'summary': _createActivitySummary(activities),
      },
      'meta': {
        'target': 'live_activity',
        'maxActivities': 3,
        'maxDuration': 12 * 60, // 12小时（分钟）
        'supportedPlatforms': ['ios'], // 目前只有 iOS 支持
        'dataSize': 0, // 将在序列化后填充
        'compression': 'none',
      },
    };
    
    // 计算实际大小
    final meta = package['meta'] as Map<String, dynamic>;
    meta['dataSize'] = _calculateJsonSize(package);

    return package;
  }

  /// 导出统一数据包（包含所有类型的数据）
  static Map<String, dynamic> exportUnifiedPackage({
    WidgetScheduleData? widgetData,
    List<LiveActivityData>? liveActivities,
    Map<String, dynamic>? customData,
    Map<String, dynamic>? metadata,
  }) {
    final package = {
      'type': 'unified_data_package',
      'version': VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'universal',
      'data': {
        if (widgetData != null) 'widget': widgetData.toJson(),
        if (liveActivities != null) 'liveActivities': {
          'activities': liveActivities.map((a) => a.toJson()).toList(),
          'count': liveActivities.length,
          'summary': _createActivitySummary(liveActivities),
        },
        if (customData != null) 'custom': customData,
      },
      'meta': {
        'hasWidgetData': widgetData != null,
        'hasLiveActivityData': liveActivities != null,
        'hasCustomData': customData != null,
        'dataSize': 0, // 将在序列化后填充
        'compression': 'none',
        'encryption': 'none',
        if (metadata != null) ...metadata,
      },
    };

    // 计算实际大小
    final meta = package['meta'] as Map<String, dynamic>;
    meta['dataSize'] = _calculateJsonSize(package);

    // 检查是否需要压缩
    if (meta['dataSize'] as int > MAX_UNIFIED_SIZE) {
      return _createCompressedPackage(package);
    }

    return package;
  }

  /// 导出平台特定格式
  static Map<String, dynamic> exportPlatformData({
    required String platform,
    WidgetScheduleData? widgetData,
    List<LiveActivityData>? liveActivities,
    Map<String, dynamic>? customData,
  }) {
    final basePackage = exportUnifiedPackage(
      widgetData: widgetData,
      liveActivities: liveActivities,
      customData: customData,
      metadata: {'targetPlatform': platform},
    );
    
    switch (platform.toLowerCase()) {
      case 'ios':
      case 'iphone':
        return _createIOSPackage(basePackage);
      case 'android':
        return _createAndroidPackage(basePackage);
      case 'harmonyos':
      case 'harmony':
        return _createHarmonyOSPackage(basePackage);
      case 'web':
        return _createWebPackage(basePackage);
      default:
        return basePackage;
    }
  }

  /// 创建 iOS 专用数据包
  static Map<String, dynamic> _createIOSPackage(Map<String, dynamic> basePackage) {
    return {
      ...basePackage,
      'platform': 'ios',
      'ios_specific': {
        'min_version': '16.1',
        'widget_support': true,
        'live_activity_support': true,
        'dynamic_island_support': true,
        'widget_types': ['small', 'medium', 'large', 'lock_screen'],
        'max_widget_size': 30 * 1024, // 30KB
        'max_live_activity_size': 10 * 1024, // 10KB
        'app_groups_enabled': true,
        'push_notifications_enabled': true,
      },
    };
  }

  /// 创建 Android 专用数据包
  static Map<String, dynamic> _createAndroidPackage(Map<String, dynamic> basePackage) {
    return {
      ...basePackage,
      'platform': 'android',
      'android_specific': {
        'min_sdk': 31, // Android 12
        'widget_support': true,
        'glance_support': true, // Jetpack Glance
        'widget_types': ['small', 'medium', 'large'],
        'max_widget_size': 50 * 1024, // 50KB
        'notification_support': true,
        'work_manager_support': true,
      },
    };
  }

  /// 创建 HarmonyOS 专用数据包
  static Map<String, dynamic> _createHarmonyOSPackage(Map<String, dynamic> basePackage) {
    return {
      ...basePackage,
      'platform': 'harmonyos',
      'harmonyos_specific': {
        'min_api_level': 9,
        'form_factor': 'phone',
        'widget_support': true,
        'service_widget_support': true,
        'max_widget_size': 40 * 1024, // 40KB
        'distributed_support': true,
      },
    };
  }

  /// 创建 Web 专用数据包
  static Map<String, dynamic> _createWebPackage(Map<String, dynamic> basePackage) {
    return {
      ...basePackage,
      'platform': 'web',
      'web_specific': {
        'format': 'json',
        'cors_enabled': true,
        'compression': 'gzip',
        'cache_control': 'max-age=300', // 5分钟缓存
      },
    };
  }

  /// 创建 Widget 专用数据包
  static Map<String, dynamic> _createWidgetPackage(WidgetScheduleData data) {
    return {
      'type': 'widget_data',
      'version': VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'universal',
      'data': data.toJson(),
      'meta': {
        'target': 'widget',
        'platforms': ['ios', 'android', 'harmonyos'],
        'widget_types': ['small', 'medium', 'large', 'lock_screen'],
        'max_size': MAX_WIDGET_SIZE,
        'data_size': 0, // 将在序列化后填充
        'compression': 'none',
        'features': {
          'multi_school': true,
          'time_template': true,
          'next_course': true,
          'week_schedule': true,
        },
      },
    };
  }

  /// 创建压缩数据包
  static Map<String, dynamic> _createCompressedPackage(Map<String, dynamic> originalPackage) {
    final jsonString = jsonEncode(originalPackage);
    final originalBytes = utf8.encode(jsonString);
    final compressedBytes = gzip.encode(originalBytes);
    
    return {
      'type': 'compressed_data_package',
      'version': VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'universal',
      'data': {
        'compressed': compressedBytes,
        'original_size': originalBytes.length,
        'compressed_size': compressedBytes.length,
        'compression_ratio': compressedBytes.length / originalBytes.length,
      },
      'meta': {
        'compression': 'gzip',
        'original_package_type': originalPackage['type'],
        'original_size': originalBytes.length,
        'compressed_size': compressedBytes.length,
      },
    };
  }

  /// 创建活动摘要
  static Map<String, dynamic> _createActivitySummary(List<LiveActivityData> activities) {
    if (activities.isEmpty) {
      return {
        'total_count': 0,
        'has_upcoming': false,
        'has_active': false,
        'next_activity_time': null,
      };
    }

    final now = DateTime.now();
    final upcoming = activities.where((a) => a.startTime.isAfter(now)).toList();
    final active = activities.where((a) => a.isActive).toList();
    
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    final nextActivity = upcoming.isNotEmpty ? upcoming.first : null;

    return {
      'total_count': activities.length,
      'upcoming_count': upcoming.length,
      'active_count': active.length,
      'has_upcoming': upcoming.isNotEmpty,
      'has_active': active.isNotEmpty,
      'next_activity_time': nextActivity?.startTime.toIso8601String(),
      'next_activity_name': nextActivity?.courseName,
    };
  }

  /// 裁剪 Widget 数据（当数据过大时）
  static WidgetScheduleData _trimWidgetData(WidgetScheduleData originalData) {
    // 只保留今天和明天的课程，本周课表只保留前3天
    final trimmedToday = originalData.todayCourses.take(10).toList();
    final trimmedTomorrow = originalData.tomorrowCourses.take(10).toList();
    
    final trimmedWeekSchedule = <int, List<WidgetCourse>>{};
    final weekDays = [1, 2, 3]; // 只保留周一到周三
    for (final day in weekDays) {
      if (originalData.weekSchedule.containsKey(day)) {
        trimmedWeekSchedule[day] = originalData.weekSchedule[day]!.take(5).toList();
      }
    }

    return WidgetScheduleData(
      version: originalData.version,
      timestamp: originalData.timestamp,
      schoolId: originalData.schoolId,
      schoolName: originalData.schoolName,
      timeTemplate: originalData.timeTemplate,
      currentWeek: originalData.currentWeek,
      currentWeekDay: originalData.currentWeekDay,
      semesterName: originalData.semesterName,
      todayCourses: trimmedToday,
      tomorrowCourses: trimmedTomorrow,
      nextCourse: originalData.nextCourse,
      currentCourse: originalData.currentCourse,
      weekSchedule: trimmedWeekSchedule,
      todayCourseCount: trimmedToday.length,
      tomorrowCourseCount: trimmedTomorrow.length,
      weekCourseCount: trimmedWeekSchedule.values.expand((c) => c).length,
      hasCoursesToday: trimmedToday.isNotEmpty,
      hasCoursesTomorrow: trimmedTomorrow.isNotEmpty,
      dataSource: originalData.dataSource,
      totalCourses: originalData.totalCourses,
      lastUpdateTime: originalData.lastUpdateTime,
    );
  }

  /// 计算 JSON 数据大小（字节）
  static int _calculateJsonSize(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    return utf8.encode(jsonString).length;
  }
}

