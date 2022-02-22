import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wheretosleepinnju/Resources/Constant.dart';
import '../Models/CourseModel.dart';
import '../Models/Db/DbHelper.dart';

class HomeWidgetUtil {
  final now = DateTime.now();

  // final now = DateTime.parse("1970-01-01 17:00:00");

  updateWidget() async {
    int nowWeek = await _getWeekOrder();
    int tableId = await _getClassTableId();
    String title = "";
    String content = "";
    List tac = await _getNextCourse(tableId, nowWeek);
    title = tac[0];
    content = tac[1];
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'title',
        title,
      ),
      HomeWidget.saveWidgetData(
        'content',
        content,
      ),
      HomeWidget.updateWidget(
        name: 'SingleCourseWidgetProvider',
        androidName: 'SingleCourseWidgetProvider',
        iOSName: 'SingleCourseWidget',
      ),
    ]).then((value) {
      return !value.contains(false);
    });
  }

  _getCoursesToday(int tableId, nowWeek) async {
    List<Course> coursesToday = [];
    List<Course> allCourses = [];
    List allCoursesMap = [];
    dynamic dbbasePath = await getDatabasesPath();
    String path = join(dbbasePath, DbHelper.DATABASE_NAME);
    Database db = await openDatabase(path, readOnly: true);

    List<Map> rst = await db.query(DbHelper.COURSE_TABLE_NAME,
        where: '${DbHelper.COURSE_COLUMN_COURSETABLEID} = ?',
        whereArgs: [tableId]);
    allCoursesMap = rst.toList();
    // List allCoursesMap = await CourseProvider().getAllCourses(tableId);

    for (Map<String, dynamic> courseMap in allCoursesMap) {
      allCourses.add(Course.fromMap(courseMap));
    }
    for (Course course in allCourses) {
      List weeks = json.decode(course.weeks!);
      if (weeks.contains(nowWeek) && course.weekTime == 1) {
        coursesToday.add(course);
      }
    }
    return coursesToday;
  }

  _getNextCourse(tableId, nowWeek) async {
    String title = "";
    String content = "";
    List<Map> l = Constant.CLASS_TIME_LIST;

    List<Course> courses = await _getCoursesToday(tableId, nowWeek);
    courses.sort((a, b) => _s2t(l[a.startTime! - 1]['start'])
        .compareTo(_s2t(l[b.startTime! - 1]['start'])));

    if (courses.isEmpty) {
      title = '${now.year}-${now.month}-${now.day}';
      content = '今天没有课哦╰(*°▽°*)╯';
    } else {
      if (now.isBefore(_c2t(courses[0]))) {
        // 如果在第一节课之前
        title = '${courses[0].name}';
        content =
        '${l[courses[0].startTime! - 1]['start']}-${l[courses[0].startTime! + courses[0].timeCount! - 1]['end']} 第${courses[0].startTime}-${courses[0].startTime! + courses[0].timeCount!}节 @${courses[0].classroom}';
      }
      if (now.isAfter(_c2t(courses[courses.length - 1])) &&
          now.isBefore(_c2t(courses[courses.length - 1], mode: 'end'))) {
        //如果在最后一节课之中
        title = '${courses[courses.length - 1].name}';
        content =
        '${l[courses[courses.length - 1].startTime! - 1]['start']}-${l[courses[courses.length - 1].startTime! + courses[courses.length - 1].timeCount! - 1]['end']} 第${courses[courses.length - 1].startTime}-${courses[courses.length - 1].startTime! + courses[courses.length - 1].timeCount!}节 @${courses[courses.length - 1].classroom}';
      }
      if (now.isAfter(_c2t(courses[courses.length - 1], mode: 'end'))) {
        //如果在最后一节课之后
        title = '${now.year}-${now.month}-${now.day}';
        content = '今天课上完了哦╰(*°▽°*)╯';
      }
      for (int i = 1; i < courses.length; i++) {
        if (now.isAfter(_c2t(courses[i - 1])) &&
            now.isBefore(_c2t(courses[i]))) {
          //如果在上节课上课后且在下节课上课前
          title = '${courses[i].name}';
          content =
          '${l[courses[i].startTime! - 1]['start']}-${l[courses[i].startTime! + courses[i].timeCount! - 1]['end']} 第${courses[i].startTime}-${courses[i].startTime! + courses[i].timeCount!}节 @${courses[i].classroom}';
        }
      }
    }

    if (kDebugMode) {
      title = title + " " + DateTime.now().toString().split('-').last.split('.').first;
    }

    return [title, content];
  }

  Future<int> _getWeekOrder() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? weekIndex = sp.getInt("weekIndex");
    if (weekIndex != null) {
      return weekIndex;
    }
    return 1;
  }

  Future<int> _getClassTableId() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    int? classTableIndex = sp.getInt("tableId");
    if (classTableIndex != null) {
      return classTableIndex;
    }
    return 0;
  }

  DateTime _c2t(Course course, {String mode = 'start'}) {
    List<Map> l = Constant.CLASS_TIME_LIST;
    if (mode == 'start') {
      return _s2t(l[course.startTime! - 1]['start']);
    } else {
      return _s2t(l[course.startTime! + course.timeCount! - 1]['end']);
    }
  }

  DateTime _s2t(String? time24) {
    // 22:00格式转换为今天22:00:00的DateTime
    String yymmddhhmm = '${now.toString().split(" ").first} $time24:00';
    return DateTime.parse(yymmddhhmm);
  }
}