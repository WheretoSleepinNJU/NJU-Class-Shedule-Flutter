import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/widget_schedule_data.dart';
import '../models/live_activity_data.dart';

/// Flutter 到原生平台的数据通信桥接
/// 提供统一的数据传输接口，支持 iOS、Android、HarmonyOS 等平台
class NativeDataBridge {
  static const MethodChannel _channel = MethodChannel('com.wheretosleepinnju/widget_data');
  static const EventChannel _eventChannel = EventChannel('com.wheretosleepinnju/widget_data_events');
  
  /// 单例模式
  static final NativeDataBridge _instance = NativeDataBridge._internal();
  factory NativeDataBridge() => _instance;
  NativeDataBridge._internal();
  
  /// 发送 Widget 数据到原生平台
  Future<bool> sendWidgetData(WidgetScheduleData data) async {
    try {
      print('[NativeDataBridge] 准备发送 Widget 数据到原生平台...');
      final dataJson = data.toJson();
      print('[NativeDataBridge] JSON 序列化成功，数据大小: ${dataJson.toString().length} 字符');
      print('[NativeDataBridge] 调用 MethodChannel: sendWidgetData');

      final result = await _channel.invokeMethod('sendWidgetData', {
        'data': dataJson,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getCurrentPlatform(),
      });

      print('[NativeDataBridge] MethodChannel 调用完成，返回值: $result');
      if (result == true) {
        print('[NativeDataBridge] ✅ 原生平台确认接收成功');
      } else {
        print('[NativeDataBridge] ⚠️ 原生平台返回: $result');
      }
      return result == true;
    } catch (e, stackTrace) {
      print('[NativeDataBridge] ❌ 发送 Widget 数据失败: $e');
      print('[NativeDataBridge] StackTrace: $stackTrace');
      return false;
    }
  }
  
  /// 发送 Live Activity 数据到原生平台
  Future<bool> sendLiveActivityData(List<LiveActivityData> activities) async {
    try {
      final activitiesJson = activities.map((a) => a.toJson()).toList();
      final result = await _channel.invokeMethod('sendLiveActivityData', {
        'activities': activitiesJson,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getCurrentPlatform(),
      });
      return result == true;
    } catch (e) {
      print('发送 Live Activity 数据失败: $e');
      return false;
    }
  }
  
  /// 发送统一数据包（包含所有类型的数据）
  Future<bool> sendUnifiedDataPackage({
    WidgetScheduleData? widgetData,
    List<LiveActivityData>? liveActivities,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final package = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getCurrentPlatform(),
        'data': {
          if (widgetData != null) 'widget': widgetData.toJson(),
          if (liveActivities != null) 'liveActivities': {
            'activities': liveActivities.map((a) => a.toJson()).toList(),
            'count': liveActivities.length,
          },
          if (customData != null) 'custom': customData,
        },
        'meta': {
          'hasWidgetData': widgetData != null,
          'hasLiveActivityData': liveActivities != null,
          'hasCustomData': customData != null,
          'totalSize': 0, // 将在序列化后填充
        },
      };
      
      final result = await _channel.invokeMethod('sendUnifiedDataPackage', package);
      return result == true;
    } catch (e) {
      print('发送统一数据包失败: $e');
      return false;
    }
  }
  
  /// 请求原生平台刷新 Widget
  Future<bool> refreshWidgets() async {
    try {
      final result = await _channel.invokeMethod('refreshWidgets');
      return result == true;
    } catch (e) {
      print('刷新 Widget 失败: $e');
      return false;
    }
  }
  
  /// 请求原生平台刷新 Live Activities
  Future<bool> refreshLiveActivities() async {
    try {
      final result = await _channel.invokeMethod('refreshLiveActivities');
      return result == true;
    } catch (e) {
      print('刷新 Live Activities 失败: $e');
      return false;
    }
  }
  
  /// 获取原生平台的数据接收状态
  Future<Map<String, dynamic>?> getNativeDataStatus() async {
    try {
      final result = await _channel.invokeMethod('getDataStatus');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      print('获取原生数据状态失败: $e');
      return null;
    }
  }
  
  /// 监听原生平台的事件
  Stream<Map<String, dynamic>?> get nativeEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event != null) {
        return Map<String, dynamic>.from(event);
      }
      return null;
    });
  }
  
  /// 发送压缩数据（大数据包时使用）
  Future<bool> sendCompressedData(Uint8List compressedData) async {
    try {
      final result = await _channel.invokeMethod('sendCompressedData', {
        'data': compressedData,
        'originalSize': compressedData.length,
        'compression': 'gzip',
      });
      return result == true;
    } catch (e) {
      print('发送压缩数据失败: $e');
      return false;
    }
  }
  
  /// 请求原生平台清理缓存数据
  Future<bool> clearNativeCache() async {
    try {
      final result = await _channel.invokeMethod('clearCache');
      return result == true;
    } catch (e) {
      print('清理原生缓存失败: $e');
      return false;
    }
  }

  /// 调试：从原生端读取 Widget 数据
  Future<Map<String, dynamic>?> debugReadWidgetData() async {
    try {
      print('[NativeDataBridge] 🔍 调试：从原生端读取 Widget 数据');
      final result = await _channel.invokeMethod('debugReadWidgetData');
      if (result != null) {
        print('[NativeDataBridge] ✅ 成功读取数据');
        return Map<String, dynamic>.from(result);
      }
      print('[NativeDataBridge] ⚠️ 未找到数据');
      return null;
    } catch (e) {
      print('[NativeDataBridge] ❌ 读取失败: $e');
      return null;
    }
  }
  
  /// 获取当前平台
  String _getCurrentPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isFuchsia) return 'fuchsia';
    // 对 HarmonyOS 的判断通常依赖特定的环境标记，如果 dart:io 标准库未更新支持
    // 可以通过其他方式或保持默认，这里假设可能是 android 或 linux 内核，
    // 或者通过 Platform.operatingSystem 判断字符串
    if (Platform.operatingSystem == 'ohos') return 'ohos';
    
    return Platform.operatingSystem;
  }
  
  /// 创建数据包头部信息
  Map<String, dynamic> _createPackageHeader(String dataType) {
    return {
      'type': dataType,
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'platform': _getCurrentPlatform(),
      'compression': 'none', // 或 'gzip'
      'encryption': 'none',
    };
  }
  
  /// 验证数据包完整性
  bool _validateDataPackage(Map<String, dynamic> package) {
    try {
      // 检查必需字段
      if (!package.containsKey('version')) return false;
      if (!package.containsKey('timestamp')) return false;
      if (!package.containsKey('data')) return false;
      
      // 检查数据格式
      final data = package['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 计算数据包大小
  int _calculatePackageSize(Map<String, dynamic> package) {
    final jsonString = jsonEncode(package);
    return utf8.encode(jsonString).length;
  }
}

/// 数据通信异常
class DataCommunicationException implements Exception {
  final String message;
  final String? platform;
  final dynamic originalError;
  
  DataCommunicationException(this.message, {this.platform, this.originalError});
  
  @override
  String toString() => 'DataCommunicationException: $message' + 
      (platform != null ? ' (Platform: $platform)' : '') +
      (originalError != null ? ' Original: $originalError' : '');
}

/// 原生平台响应
class NativePlatformResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? error;
  
  NativePlatformResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });
  
  factory NativePlatformResponse.fromJson(Map<String, dynamic> json) {
    return NativePlatformResponse(
      success: json['success'] == true,
      message: json['message'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      error: json['error'],
    );
  }
}

/// 平台类型枚举
enum NativePlatform {
  ios,
  android,
  harmonyos,
  web,
  unknown,
}

/// 数据类型枚举
enum DataType {
  widgetData,
  liveActivityData,
  unifiedPackage,
  customData,
}