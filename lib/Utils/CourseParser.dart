import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:scoped_model/scoped_model.dart';
import '../Utils/States/MainState.dart';
import '../Models/CourseTableModel.dart';
import '../Models/CourseModel.dart';
import '../Resources/Constant.dart';
import '../Utils/ColorUtil.dart';

class CourseParser {
  final RegExp patten1 = new RegExp(r"第\d{1,2}.*节");
  final RegExp patten2 = new RegExp(r"(\d{1,2})-(\d{1,2})周");
  final RegExp patten3 = new RegExp(r"第\d{1,2}周");

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
//      print(e.children[0].innerHtml);
//      print(e.children[1].innerHtml);
//      print(e.children[2].innerHtml);
//      print(e.children[3].innerHtml);
      // Time and Place
      String source = e.children[5].innerHtml.trim().replaceAll('<br>', '\n');
//      print(source);
      String color = HexColor.getRandomColor();
      List<String> infos = source.split('\n');
      for (String info in infos) {
        if (info == '') continue;
        print(info);

        List<String> strs = info.split(' ');
        if (!info.startsWith('周')) {}
        String weekStr = info.substring(0, 2);
        int weekTime = _getIntWeek(weekStr);
        print(weekTime);
        String time = patten1.stringMatch(info);
        List<String> times = time.substring(1, time.length - 1).split('-');
        int startTime = int.parse(times[0]);
        int timeCount = int.parse(times[1]) - startTime;
        print(startTime.toString() + ' - ' + timeCount.toString());
        String classRoom = strs[strs.length - 1];
        print(classRoom);
//        final match = patten1.firstMatch(info);
//        print(match.group(0));
//        print(match.group(1));

//        print(patten1.stringMatch(info));
//        print(patten2.stringMatch(info));
//        print(patten3.stringMatch(info));

        // 减1的原因：SQL中id从1开始计
        Course course = new Course(tableId-1, e.children[2].innerHtml,
            "[1,2,3,4,5,6,7]", weekTime, startTime, timeCount, 1, color,
            classroom: classRoom);
        print(course.toMap().toString());
        rst.add(course);
      }

//      new Course(tableId, e.children[2].innerHtml, "[1,2,3,4,5,6,7]", 3, 5, 2, 0, '#8AD297', classroom: e.children[3].innerHtml)
//      print(e.innerHtml);
    }
    CourseProvider courseProvider = new CourseProvider();
    for (Course course in rst) {
      await courseProvider.insert(course);
    }
    return rst;
  }

  Future<int> addCourseTable(String name) async {
    CourseTableProvider courseTableProvider = new CourseTableProvider();
    CourseTable courseTable =
        await courseTableProvider.insert(new CourseTable(name));
    return courseTable.id;
//    MainStateModel.of(context);
  }

  int _getIntWeek(String chinaWeek) {
    for (int i = 0; i < Constant.WEEK.length; i++) {
      if (Constant.WEEK[i] == chinaWeek) {
        return i;
      }
    }
    return 0;
  }
}
