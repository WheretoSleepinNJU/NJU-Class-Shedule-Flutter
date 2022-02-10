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

class InitUtil {
  static Future<int> initialize() async {
    int themeIndex = await getTheme();
    await checkDataBase();
    await WeekUtil.checkWeek();
    await ColorPool.checkColorPool();
    showReview();
    return themeIndex;
  }

  static Future<int> getTheme() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? themeIndex = sp.getInt("themeIndex");
    if (themeIndex != null) {
      return themeIndex;
    }
    return 0;
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
