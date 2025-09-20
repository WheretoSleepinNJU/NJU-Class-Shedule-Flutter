import 'package:flutter/material.dart' hide Element;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../Utils/States/MainState.dart';
import '../Models/CourseTableModel.dart';
import '../Models/CourseModel.dart';
import '../Resources/Constant.dart';

class CourseParser {
  final RegExp patten1 = RegExp(r"第(\d{1,2})-(\d{1,2})节");
  final RegExp patten2 = RegExp(r"^(\d{1,2})-(\d{1,2})周$");
  final RegExp patten3 = RegExp(r"从第(\d{1,2})周开始");
  final RegExp patten4 = RegExp(r"^第(\d{1,2})周$");

  String html;
  Document? document;

  CourseParser(this.html) {
    document = parse(html);
  }

  String parseCourseName() {
    // Element? element = document!.querySelector(
    //     "body > div:nth-child(10) > table > tbody > tr:nth-child(2) > td");
    final RegExp nameExp = RegExp("[0-9]+-[0-9]+学年第(一|二)学期");
    String name = nameExp.stringMatch(html).toString();
    if (name == "null") {
      throw Exception("Didn't find course table.");
    }
    //    print(element.innerHtml);
    return name;
  }

  Future<List<Course>> parseCourse(int tableId) async {
    List<Course> rst = [];
    List<Element> elements = document!.getElementsByClassName("TABLE_TR_01") +
        document!.getElementsByClassName("TABLE_TR_02");
    for (Element e in elements) {
      //退选课程
      String state = e.children[6].innerHtml.trim();
      if (state.contains('已退选')) continue;

      // Time and Place
      String source = e.children[4].innerHtml.trim().replaceAll('<br>', '\\n');
      List<String> infos = source.split('\\n');

      String courseName = e.children[1].innerHtml;
      String courseTeacher = e.children[3].innerHtml;
      String testLocation =
          (e.children.length > 9) ? (e.children[9].innerHtml) : '';
      String testTime =
          (e.children.length > 9) ? (e.children[8].innerHtml) : '';
      String courseInfo = (e.children.length > 9) ? (e.children[10].text) : '';

      for (String info in infos) {
        info = info.replaceAll('\\t\\t\\t\\t\\t  \\t', '');
        info = info.replaceAll('\\t\\t\\t\\t\\t', '');
        info = info.trim();
        if (info == '') continue;
        List<String> strs = info.split(' ');

        //自由时间缺省值
        int weekTime = 0;
        int startTime = 0;
        int timeCount = 0;

        //TODO: 自由时间
        // "自由时间 2-17周 详见主页通知"
        if (!info.contains('自由时间')) {
          // Get WeekTime
          String weekStr = info.substring(0, 2);
          // 异常测试
          // weekStr = '周零';
          weekTime = _getIntWeek(weekStr);
          if (weekTime == 0) {
            throw (courseName);
          }

          // 异常测试
          // info="周四 第9节 2-17周  仙Ⅱ-301";
          try {
            var time = patten1.firstMatch(info);
            startTime = int.parse(time!.group(1)!);
            timeCount = int.parse(time.group(2)!) - startTime;
          } catch (e) {
            continue;
            // throw (courseName);
          }
        }

        // Get Time
        String weekSeries;
        weekSeries = getWeekSeriesString(info);

        // Get ClassRoom
        String classRoom = strs[strs.length - 1];
        // print(classRoom);

        Course course = Course(
            tableId, courseName, weekSeries, weekTime, startTime, timeCount, 1,
            classroom: classRoom,
            teacher: courseTeacher,
            testLocation: testLocation,
            testTime: testTime,
            info: courseInfo);
        // print(course.toMap().toString());
        rst.add(course);
      }
      // new Course(tableId, e.children[2].innerHtml, "[1,2,3,4,5,6,7]", 3, 5, 2, 0, '#8AD297', classroom: e.children[3].innerHtml)
    }
    CourseProvider courseProvider = CourseProvider();
    for (Course course in rst) {
      await courseProvider.insert(course);
    }
    return rst;
  }

  Future<int> addCourseTable(String name, BuildContext context) async {
    CourseTableProvider courseTableProvider = CourseTableProvider();
    CourseTable courseTable =
        await courseTableProvider.insert(CourseTable(name));
    int id = courseTable.id!;
    MainStateModel.of(context).changeclassTable(id);
    return id;
  }

  String getWeekSeriesString(String info) {
    List<int> weekList = [];
    List<String> strs = info.split(' ');

    for (String str in strs) {
      var rst4 = patten4.firstMatch(str);
      if (rst4 != null) {
        weekList.add(int.parse(rst4.group(1)!));
      }

      var rst2 = patten2.firstMatch(str);
      if (rst2 != null) {
        int startWeek = int.parse(rst2.group(1)!);
        int endWeek = int.parse(rst2.group(2)!);
        bool flag = false;
        for (String sstr in strs) {
          if (sstr == '单周') {
            weekList = weekList + _getSingleWeekSeries(startWeek, endWeek);
            flag = true;
            break;
          } else if (sstr == '双周') {
            weekList = weekList + _getDoubleWeekSeries(startWeek, endWeek);
            flag = true;
            break;
          }
        }
        if (flag == false) {
          weekList = weekList + _getWeekSeries(startWeek, endWeek);
        }
      }

      // 从第x周开始：(单周|双周)
      var rst3 = patten3.firstMatch(str);
      if (rst3 != null) {
        int startWeek = int.parse(rst3.group(1)!);
        bool flag = false;
        if (str.contains('单周')) {
          weekList = weekList +
              _getSingleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
          flag = true;
        } else if (str.contains('双周')) {
          weekList = weekList +
              _getDoubleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
          flag = true;
        }
        if (flag == false) {
          weekList =
              weekList + _getWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
        }
      }
    }

    if (weekList.isEmpty) {
      // 有些课程只有单周/双周显示，无周数，故会出现找不到周数的情况
      // "周二 第3-4节 单周 逸B-101"
      if (info.contains('单周')) {
        weekList = _getSingleWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
      } else if (info.contains('双周')) {
        weekList = _getDoubleWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
      } else {
        weekList = _getWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
      }
    }

    return weekList.toString();
  }

  int _getIntWeek(String chinaWeek) {
    for (int i = 0; i < Constant.WEEK_WITH_BIAS.length; i++) {
      if (Constant.WEEK_WITH_BIAS[i] == chinaWeek) {
        return i;
      }
    }
    return 0;
  }

  List<int> _getWeekSeries(int start, int end) {
    List<int> list = [for (int i = start; i <= end; i += 1) i];
    // print (list.toString());
    return list;
  }

  List<int> _getSingleWeekSeries(int start, int end) {
    if (start % 2 == 0) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
    return list;
  }

  List<int> _getDoubleWeekSeries(int start, int end) {
    if (start % 2 == 1) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
    // print (list.toString());
    return list;
  }
}
