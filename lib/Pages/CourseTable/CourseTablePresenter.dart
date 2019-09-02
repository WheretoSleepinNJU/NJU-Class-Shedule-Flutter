import 'package:flutter/material.dart';
import '../../Models/CourseModel.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = new CourseProvider();

  Future<List<Map>> getClasses(int tableId) async {

    //TODO
    List tmp = await courseProvider.getAllCourses(tableId);
    return tmp;
//    return [
//      {'weekday': 3, 'start': 5, 'step': 2, 'name': tmp[0]['name'], 'color': '#8AD297'},
//      {'weekday': 4, 'start': 2, 'step': 3, 'name': 'QWQ', 'color': '#F9A883'},
////    {'weekday': 4, 'start': 3, 'step': 3, 'name': 'QWQ', 'color': '#8AD297'},
//    ];
//    setState(() {
//      courseTableWidgetList = List.generate(
//          tmp.length,
//              (int i) => ListTile(
//            title: Text(tmp[i]['name']),
//            onTap: () {
//              Navigator.of(context).push(MaterialPageRoute(
//                  builder: (BuildContext context) => ImportView()));
//            },
//          ));
//    });
  }

  Future insertMockData() async {
    await courseProvider
        .insert(new Course(0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0, '#8AD297', classroom: 'QAQ'));
    await courseProvider
        .insert(new Course(0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0, '#F9A883', classroom: '仙林校区不知道哪个教室'));
    await courseProvider.insert(new Course(
        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0, '#F9A883',
        classroom: 'QAQ'));
  }
}
