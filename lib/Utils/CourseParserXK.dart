import 'package:flutter/material.dart' hide Element;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../Utils/States/MainState.dart';
import '../Models/CourseTableModel.dart';
import '../Models/CourseModel.dart';
import '../Resources/Constant.dart';

class CourseParser {
  final RegExp patten1 = new RegExp(r"(\d{1,2})-(\d{1,2})节");
  final RegExp patten2 = new RegExp(r"(\d{1,2})-(\d{1,2})周");
  final RegExp patten3 = new RegExp(r"从(\d{1,2})周开始");
  final RegExp patten4 = new RegExp(r"^(\d{1,2})周$");

  String html;
  Document? document;

  CourseParser(this.html) {
    document = parse(html);
  }

  String parseCourseName() {
    print(document);
    Element? element = document!.getElementsByClassName("currentTerm")[0];
    String rst = element.innerHtml;
    return rst;
  }

  Future<List<Course>> parseCourse(int tableId) async {
    List<Course> rst = [];
    Element? table = document!.getElementsByClassName("course-body")[1];
    List<Element> elements = table.children;
    for (Element e in elements) {
      //退选课程
      // String state = e.children[6].innerHtml.trim();
      // if(state.contains('已退选')) continue;

      // Time and Place
      List<Element> infos = e.children[3].children;
      String courseName = e.children[1].innerHtml;
      String courseTeacher = e.children[2].innerHtml;
      String courseInfo = e.children[6].attributes['title'] ?? '';

      // String source = e.children[3].innerHtml.trim().replaceAll('<br>', '\\n');
      // List<String> infos = source.split('\\n');

      // print(source);

      for (Element i in infos) {
        String info = i.innerHtml;
        if (info == '') continue;

        // "自由时间 2-17周 详见主页通知"
        // ATTENTION：这里是新教务系统的坑！
        if (info == '自由地点') continue;

        // Get WeekTime
        List<String> strs = info.split(' ');
        String weekStr = info.substring(0, 2);

        int weekTime = _getIntWeek(weekStr);
        if (weekTime == 0) {
          throw (courseName);
        }

        // Get Time
        int startTime, timeCount;
        String weekSeries;

        try {
          var time = patten1.firstMatch(info);
          startTime = int.parse(time!.group(1)!);
          timeCount = int.parse(time.group(2)!) - startTime;
          weekSeries = getWeekSeriesString(info);
        } catch (e) {
          continue;
          // throw (courseName);
        }

        // Get ClassRoom
        String classRoom = strs[strs.length - 1];

        Course course = new Course(
            tableId, courseName, weekSeries, weekTime, startTime, timeCount, 1,
            classroom: classRoom, teacher: courseTeacher, info: courseInfo
            );

        rst.add(course);
      }
    }
    CourseProvider courseProvider = new CourseProvider();
    for (Course course in rst) {
      await courseProvider.insert(course);
    }
    return rst;
  }

  Future<int> addCourseTable(String name, BuildContext context) async {
    CourseTableProvider courseTableProvider = new CourseTableProvider();
    CourseTable courseTable =
        await courseTableProvider.insert(new CourseTable(name));
    int id = courseTable.id!;
    MainStateModel.of(context).changeclassTable(id);
    return id;
  }

  String getWeekSeriesString(String info) {
    List<int> weekList = [];
    List<String> strs = [];

    try {
      info = info.split(' ')[2];
      strs = info.split(',');
    } catch (e){
      return '[]';
    }

    for (String str in strs) {
      var rst4 = patten4.firstMatch(str);
      if (rst4 != null) {
        weekList.add(int.parse(rst4.group(1)!));
      }

      var rst2 = patten2.firstMatch(str);
      if (rst2 != null) {
        int startWeek = int.parse(rst2.group(1)!);
        int endWeek = int.parse(rst2.group(2)!);
        if (str.contains('单'))
          weekList = weekList + _getSingleWeekSeries(startWeek, endWeek);
        else if (str.contains('双'))
          weekList = weekList + _getDoubleWeekSeries(startWeek, endWeek);
        else
          weekList = weekList + _getWeekSeries(startWeek, endWeek);
      }
      //
      // // 从第x周开始：(单周|双周)
      // var rst3 = patten3.firstMatch(str);
      // if (rst3 != null) {
      //   int startWeek = int.parse(rst3.group(1)!);
      //   bool flag = false;
      //   if (str.contains('单周')) {
      //     weekList = weekList +
      //         _getSingleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      //     flag = true;
      //   } else if (str.contains('双周')) {
      //     weekList = weekList +
      //         _getDoubleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      //     flag = true;
      //   }
      //   if (flag == false)
      //     weekList =
      //         weekList + _getWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      // }
    }

    if (weekList.length == 0) {
      // 有些课程只有单周/双周显示，无周数，故会出现找不到周数的情况
      // "周二 第3-4节 单周 逸B-101"
      if (info.contains('单周'))
        weekList = _getSingleWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
      else if (info.contains('双周'))
        weekList = _getDoubleWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
      else
        weekList = _getWeekSeries(
            Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
    }

    return weekList.toString();


    // // x-x周 (单周|双周)
    // var weeksResult = patten2.firstMatch(info);
    // if (weeksResult != null) {
    //   int startWeek = int.parse(weeksResult.group(1)!);
    //   int endWeek = int.parse(weeksResult.group(2)!);
    //   if (info.contains('单周'))
    //     weekSeries = _getSingleWeekSeries(startWeek, endWeek);
    //   else if (info.contains('双周'))
    //     weekSeries = _getDoubleWeekSeries(startWeek, endWeek);
    //   else
    //     weekSeries = _getWeekSeries(startWeek, endWeek);
    //   return weekSeries;
    // }
    //
    // // 从第x周开始：(单周|双周)
    // var fromWeekResult = patten3.firstMatch(info);
    // if (fromWeekResult != null) {
    //   int startWeek = int.parse(fromWeekResult.group(1)!);
    //   if (info.contains('单周'))
    //     weekSeries = _getSingleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
    //   else if (info.contains('双周'))
    //     weekSeries = _getDoubleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
    //   else
    //     weekSeries = _getWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
    //   return weekSeries;
    // }
    //
    // // 3周 5周 7周 9周
    // List weekResult = patten4.allMatches(info).toList();
    // if (!weekResult.isEmpty) {
    //   List<int> weekList = [];
    //   for (var match in weekResult) {
    //     weekList.add(int.parse(match.group(1)));
    //   }
    //   weekSeries = weekList.toString();
    //   return weekSeries;
    // }
    //
    // // 有些课程只有单周/双周显示，无周数，故会出现找不到周数的情况
    // // "周二 第3-4节 单周 逸B-101"
    // if (info.contains('单周'))
    //   weekSeries = _getSingleWeekSeries(
    //       Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
    // else if (info.contains('双周'))
    //   weekSeries = _getDoubleWeekSeries(
    //       Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
    // else
    //   throw '课程周数解析失败';
    // return weekSeries;
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
