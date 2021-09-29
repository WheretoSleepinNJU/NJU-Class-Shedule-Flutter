import 'package:flutter/material.dart' hide Element;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../Utils/States/MainState.dart';
import '../Models/CourseTableModel.dart';
import '../Models/CourseModel.dart';
import '../Resources/Constant.dart';

class CourseParser {
  final RegExp patten1 = new RegExp(r"第(\d{1,2})-(\d{1,2})节");
  final RegExp patten2 = new RegExp(r"(\d{1,2})-(\d{1,2})周");
  final RegExp patten3 = new RegExp(r"从第(\d{1,2})周开始");
  final RegExp patten4 = new RegExp(r"第(\d{1,2})周");

  String html;
  Document? document;

  CourseParser(this.html) {
    document = parse(html);
  }

  String parseCourseName() {
    // Element? element = document!.querySelector(
    //     "body > div:nth-child(10) > table > tbody > tr:nth-child(2) > td");
    final RegExp nameExp = new RegExp("[0-9]+-[0-9]+学年第(一|二)学期");
    String name = nameExp.stringMatch(html).toString();
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
      if(state.contains('已退选')) continue;

      // Time and Place
      String source = e.children[4].innerHtml.trim().replaceAll('<br>', '\\n');
      List<String> infos = source.split('\\n');

//      print(source);

      for (String info in infos) {
        info = info.replaceAll('\\t\\t\\t\\t\\t  \\t', '');
        info = info.replaceAll('\\t\\t\\t\\t\\t', '');
        if (info == '') continue;

        String courseName = e.children[1].innerHtml;
        String courseTeacher = e.children[3].innerHtml;
        String testLocation =
            (e.children.length > 9) ? (e.children[9].innerHtml) : '';

        //TODO: 自由时间
        // "自由时间 2-17周 详见主页通知"
        if (info.contains('自由时间')) continue;
//        print(info);

//        if (!info.startsWith('周')) {
//          throw (courseName);
//        }
        // Get WeekTime
        List<String> strs = info.split(' ');
        String weekStr = info.substring(0, 2);
        // 异常测试
//        weekStr = '周零';
        int weekTime = _getIntWeek(weekStr);
        if (weekTime == 0) {
          throw (courseName);
        }
//        print(weekTime);

        // Get Time
        int startTime, timeCount;
        String weekSeries;
        // 异常测试
//        info="周四 第9节 2-17周  仙Ⅱ-301";
        try {
          var time = patten1.firstMatch(info);
          startTime = int.parse(time!.group(1)!);
          timeCount = int.parse(time.group(2)!) - startTime;
          weekSeries = _getWeekSeriesString(info);
        } catch (e) {
          continue;
//          throw (courseName);
        }
//        print(startTime.toString() + ' - ' + timeCount.toString());

        // Get ClassRoom
        String classRoom = strs[strs.length - 1];
//        print(classRoom);

        Course course = new Course(
            tableId, courseName, weekSeries, weekTime, startTime, timeCount, 1,
            classroom: classRoom,
            teacher: courseTeacher,
            testLocation: testLocation);
//        print(course.toMap().toString());

        rst.add(course);
      }
//      new Course(tableId, e.children[2].innerHtml, "[1,2,3,4,5,6,7]", 3, 5, 2, 0, '#8AD297', classroom: e.children[3].innerHtml)
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

  String _getWeekSeriesString(String info) {
    String weekSeries;

    // x-x周 (单周|双周)
    var weeksResult = patten2.firstMatch(info);
    if (weeksResult != null) {
      int startWeek = int.parse(weeksResult.group(1)!);
      int endWeek = int.parse(weeksResult.group(2)!);
      if (info.contains('单周'))
        weekSeries = _getSingleWeekSeries(startWeek, endWeek);
      else if (info.contains('双周'))
        weekSeries = _getDoubleWeekSeries(startWeek, endWeek);
      else
        weekSeries = _getWeekSeries(startWeek, endWeek);
      return weekSeries;
    }

    // 从第x周开始：(单周|双周)
    var fromWeekResult = patten3.firstMatch(info);
    if (fromWeekResult != null) {
      int startWeek = int.parse(fromWeekResult.group(1)!);
      if (info.contains('单周'))
        weekSeries = _getSingleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      else if (info.contains('双周'))
        weekSeries = _getDoubleWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      else
        weekSeries = _getWeekSeries(startWeek, Constant.DEFAULT_WEEK_END);
      return weekSeries;
    }

    // 第3周 第5周 第7周 第9周
    List weekResult = patten4.allMatches(info).toList();
    if (!weekResult.isEmpty) {
      List<int> weekList = [];
      for (var match in weekResult) {
        weekList.add(int.parse(match.group(1)));
      }
      weekSeries = weekList.toString();
      return weekSeries;
    }

    // 有些课程只有单周/双周显示，无周数，故会出现找不到周数的情况
    // "周二 第3-4节 单周 逸B-101"
    if (info.contains('单周'))
      weekSeries = _getSingleWeekSeries(
          Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
    else if (info.contains('双周'))
      weekSeries = _getDoubleWeekSeries(
          Constant.DEFAULT_WEEK_START, Constant.DEFAULT_WEEK_END);
    else
      throw '课程周数解析失败';
    return weekSeries;
  }

  int _getIntWeek(String chinaWeek) {
    for (int i = 0; i < Constant.WEEK_WITH_BIAS.length; i++) {
      if (Constant.WEEK_WITH_BIAS[i] == chinaWeek) {
        return i;
      }
    }
    return 0;
  }

  String _getWeekSeries(int start, int end) {
    List<int> list = [for (int i = start; i <= end; i += 1) i];
//    print (list.toString());
    return list.toString();
  }

  String _getSingleWeekSeries(int start, int end) {
    if (start % 2 == 0) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }

  String _getDoubleWeekSeries(int start, int end) {
    if (start % 2 == 1) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }
}
