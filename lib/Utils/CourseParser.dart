import 'package:flutter/material.dart' hide Element;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import '../Utils/States/MainState.dart';
import '../Models/CourseTableModel.dart';
import '../Models/CourseModel.dart';
import '../Resources/Constant.dart';
import '../Utils/ColorUtil.dart';

class CourseParser {
  final RegExp patten1 = new RegExp(r"第(\d{1,2})-(\d{1,2})节");
  final RegExp patten2 = new RegExp(r"(\d{1,2})-(\d{1,2})周");
  final RegExp patten3 = new RegExp(r"第(\d{1,2})周");

  String html;
  Document document;

  CourseParser(this.html) {
    document = parse(html);
  }

  String parseCourseName() {
    Element element = document.querySelector(
        "body > div:nth-child(10) > table > tbody > tr:nth-child(2) > td");
//    print(element.innerHtml);
    return element.innerHtml;
  }

  Future<List<Course>> parseCourse(int tableId) async {
    List<Course> rst = [];
    List<Element> elements = document.getElementsByClassName("TABLE_TR_01") +
        document.getElementsByClassName("TABLE_TR_02");
    for (Element e in elements) {
      // Time and Place
      String source = e.children[5].innerHtml.trim().replaceAll('<br>', '\n');
      List<String> infos = source.split('\n');

//      print(source);

      // Get Color
      String color = HexColor.getRandomColor();

      for (String info in infos) {
        if (info == '') continue;
        print(info);

        // Get WeekTime
        List<String> strs = info.split(' ');
        if (!info.startsWith('周')) {}
        String weekStr = info.substring(0, 2);
        int weekTime = _getIntWeek(weekStr);
//        print(weekTime);

        // Get Time
        var time = patten1.firstMatch(info);
        int startTime = int.parse(time.group(1));
        int timeCount = int.parse(time.group(2)) - startTime;
//        print(startTime.toString() + ' - ' + timeCount.toString());

        String weekSeries;

        var weeksResult = patten2.firstMatch(info);
//        print(weeksResult.group(1));
//        print(weeksResult.group(2));
        if (weeksResult != null) {
          int startWeek = int.parse(weeksResult.group(1));
          int endWeek = int.parse(weeksResult.group(2));
          if (info.contains('单周'))
            weekSeries = _getSingleWeekSeries(startWeek, endWeek);
          else if (info.contains('双周'))
            weekSeries = _getDoubleWeekSeries(startWeek, endWeek);
          else
            weekSeries = _getWeekSeries(startWeek, endWeek);
        } else {
          List weekResult = patten3.allMatches(info).toList();
          if(weekResult.isEmpty) throw '课程周数解析失败';
          List<int> weekList = [];
          for(var match in weekResult){
            weekList.add(int.parse(match.group(1)));
          }
          weekSeries = weekList.toString();
        }

        // Get ClassRoom
        String classRoom = strs[strs.length - 1];
//        print(classRoom);

        Course course = new Course(tableId, e.children[2].innerHtml, weekSeries,
            weekTime, startTime, timeCount, 1, color,
            classroom: classRoom,
            teacher: e.children[4].innerHtml,
            testLocation: e.children[10].innerHtml ?? '');
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
    // 减1的原因：SQL中id从1开始计
    int id = courseTable.id - 1;
    MainStateModel.of(context).changeclassTable(id);
    return id;
  }

  int _getIntWeek(String chinaWeek) {
    for (int i = 0; i < Constant.WEEK.length; i++) {
      if (Constant.WEEK[i] == chinaWeek) {
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
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }

  String _getDoubleWeekSeries(int start, int end) {
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }
}
