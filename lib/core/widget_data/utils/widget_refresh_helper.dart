import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unified_data_service.dart';

/// Widget 刷新助手
/// 在课程数据变化后自动刷新 Widget
class WidgetRefreshHelper {
  static UnifiedDataService? _cachedService;
  
  /// 获取 Widget 数据服务实例（单例模式）
  static Future<UnifiedDataService> _getService() async {
    if (_cachedService != null) return _cachedService!;
    
    final preferences = await SharedPreferences.getInstance();
    _cachedService = UnifiedDataService(preferences: preferences);
    return _cachedService!;
  }
  
  /// 在课程增加后刷新 Widget
  static Future<void> refreshAfterCourseAdded() async {
    await _refreshWidget('课程添加');
  }
  
  /// 在课程删除后刷新 Widget
  static Future<void> refreshAfterCourseDeleted() async {
    await _refreshWidget('课程删除');
  }
  
  /// 在课程更新后刷新 Widget
  static Future<void> refreshAfterCourseUpdated() async {
    await _refreshWidget('课程更新');
  }
  
  /// 在批量导入课程后刷新 Widget
  static Future<void> refreshAfterCoursesImported() async {
    await _refreshWidget('课程导入');
  }
  
  /// 在切换课程表后刷新 Widget
  static Future<void> refreshAfterTableChanged() async {
    await _refreshWidget('课程表切换');
  }
  
  /// 在周次变化后刷新 Widget
  static Future<void> refreshAfterWeekChanged() async {
    await _refreshWidget('周次变化');
  }
  
  /// 通用刷新方法
  static Future<void> _refreshWidget(String reason) async {
    try {
      // 仅在 iOS 平台执行
      if (!Platform.isIOS) return;
      
      final service = await _getService();
      
      // 清除缓存，强制重新计算
      service.clearCache();
      
      // 更新 Widget 数据
      final success = await service.updateWidgetData();
      
      if (success) {
        print('Widget refreshed successfully after $reason');
      } else {
        print('Failed to refresh widget after $reason');
      }
    } catch (e) {
      print('Error refreshing widget after $reason: $e');
    }
  }
  
  /// 清除缓存的服务实例
  static void clearCache() {
    _cachedService = null;
  }
  
  /// 手动刷新 Widget（供开发调试使用）
  static Future<bool> manualRefresh() async {
    try {
      if (!Platform.isIOS) return false;
      
      final service = await _getService();
      service.clearCache();
      return await service.updateWidgetData();
    } catch (e) {
      print('Error in manual widget refresh: $e');
      return false;
    }
  }
}