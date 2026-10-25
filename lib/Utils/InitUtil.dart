import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import '../Models/CourseTableModel.dart';
import '../Resources/Config.dart';
import '../Resources/Url.dart';
import '../Utils/ColorUtil.dart';
import '../Utils/WeekUtil.dart';
import '../core/widget_data/services/unified_data_service.dart';
import '../core/widget_data/utils/widget_refresh_helper.dart';

class InitUtil {
  static Future<List> initialize() async {
    int themeIndex = await getTheme();
    int themeModeIndex = await getThemeMode();
    String themeCustom = await getThemeCustom();
    await checkDataBase();
    await WeekUtil.checkWeek();
    await ColorPool.checkColorPool();

    // 初始化 Widget 数据
    await initializeWidgetData();

    showReview();
    return [themeIndex, themeModeIndex, themeCustom];
  }

  /// 初始化 Widget 数据
  static Future<void> initializeWidgetData() async {
    try {
      // 仅在具备原生小组件实现的平台执行（iOS / Android）
      if (!WidgetRefreshHelper.isSupportedPlatform) return;

      final preferences = await SharedPreferences.getInstance();
      final widgetService = UnifiedDataService(preferences: preferences);

      // 更新 Widget 数据
      final success = await widgetService.updateWidgetData();
      if (success) {
        debugPrint('Widget data initialized successfully');
      } else {
        debugPrint('Failed to initialize widget data');
      }
    } catch (e) {
      debugPrint('Error initializing widget data: $e');
    }
  }

  static Future<int> getTheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? themeIndex = sp.getInt("themeIndex");
    if (themeIndex != null) {
      return themeIndex;
    }
    return 0;
  }

  static Future<int> getThemeMode() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? themeModeIndex = sp.getInt("themeModeIndex");
    if (themeModeIndex != null) {
      return themeModeIndex;
    }
    return 0;
  }

  static Future<String> getThemeCustom() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? themeCustom = sp.getString("themeCustomColor");
    if (themeCustom != null) {
      return themeCustom;
    }
    return '';
  }

  static Future<void> checkDataBase({CourseTableProvider? provider}) async {
    final courseTableProvider = provider ?? CourseTableProvider();
    final tables = await courseTableProvider.getAllCourseTable();
    if (tables.isEmpty) {
      final table = await courseTableProvider.insert(
        CourseTable(Config.default_class_table),
      );
      tables.add(table.toMap());
    }

    // A fresh installation (or an older installation with tableId = 0) must
    // select a real table before export and widget initialization read it.
    final preferences = await SharedPreferences.getInstance();
    final selectedId = preferences.getInt('tableId');
    if (!tables.any((table) => table[columnId] == selectedId)) {
      await preferences.setInt('tableId', tables.first[columnId] as int);
    }
  }

  static Future<void> showReview({
    Future<dynamic> Function()? loadConfig,
    bool? isIOS,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final openTimes = sp.getInt('openTimes') ?? 0;
      await sp.setInt('openTimes', openTimes + 1);
      if (!(isIOS ?? Platform.isIOS) ||
          (sp.getBool('hasShowReview') ?? false)) {
        return;
      }

      final dynamic data;
      if (loadConfig != null) {
        data = await loadConfig();
      } else {
        final response = await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        ).get('${Url.UPDATE_ROOT}/showiOSReview.json');
        data = response.data;
      }
      if (data is! Map || data['showReview'] != true) return;
      final threshold =
          data['reviewTime'] is int
              ? data['reviewTime'] as int
              : Config.REVIEW_DIALOG_SHOW_TIME;
      if (openTimes < threshold) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;

      Timer(
        const Duration(seconds: Config.REVIEW_DIALOG_DELAY_SECONDS),
        () async {
          try {
            UmengCommonSdk.onEvent('review_dialog', {'action': 'show'});
            await review.requestReview();
            await sp.setBool('hasShowReview', true);
          } catch (error) {
            debugPrint('Review prompt skipped: $error');
          }
        },
      );
    } catch (error) {
      // A rating prompt must never fail the application startup isolate.
      debugPrint('Review configuration unavailable: $error');
    }
  }
}
