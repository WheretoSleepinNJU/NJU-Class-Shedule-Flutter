import 'dart:io';
import 'dart:async';
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
      // 仅在 iOS 平台执行
      if (!Platform.isIOS) return;
      
      final preferences = await SharedPreferences.getInstance();
      final widgetService = UnifiedDataService(preferences: preferences);
      
      // 更新 Widget 数据
      final success = await widgetService.updateWidgetData();
      if (success) {
        print('Widget data initialized successfully');
      } else {
        print('Failed to initialize widget data');
      }
    } catch (e) {
      print('Error initializing widget data: $e');
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

  static checkDataBase() async {
    CourseTableProvider courseTableProvider = CourseTableProvider();
    List c = await courseTableProvider.getAllCourseTable();
    if (c.isEmpty) {
      courseTableProvider.insert(CourseTable(Config.default_class_table));
    }
  }

  static showReview() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int openTimes = sp.getInt("openTimes") ?? 0;
    await sp.setInt("openTimes", openTimes + 1);

    if (!Platform.isIOS) return;

    Dio dio = Dio();
    String url = Url.UPDATE_ROOT + '/showiOSReview.json';
    Response response = await dio.get(url);
    if (response.statusCode != HttpStatus.ok) return;

    // print(response.data['showReview']);
    // print(response.data['reviewTime']);

    bool showReview = response.data['showReview'] ?? false;
    if (!showReview) return;

    int reviewTime =
        response.data['reviewTime'] ?? Config.REVIEW_DIALOG_SHOW_TIME;
    bool needsShowReview = (openTimes >= reviewTime);
    if (!needsShowReview) return;

    final InAppReview inAppReview = InAppReview.instance;
    bool hasShowReview = sp.getBool("hasShowReview") ?? false;
    int delaySeconds = Config.REVIEW_DIALOG_DELAY_SECONDS;

    // for test
    // print(openTimes);
    // print(reviewTime);
    // print(hasShowReview);
    // hasShowReview = false;
    // delaySeconds = 1;

    if (hasShowReview) return;

    bool inAppReviewAvailable = await inAppReview.isAvailable();
    if (!inAppReviewAvailable) return;

    Timer(Duration(seconds: delaySeconds), () {
      UmengCommonSdk.onEvent("review_dialog", {"action": "show"});
      inAppReview.requestReview();
      sp.setBool("hasShowReview", true);
    });
  }
}
