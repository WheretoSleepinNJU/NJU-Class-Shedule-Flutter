import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../Resources/Colors.dart';
import './CourseModel.dart';

class Lecture extends Course {
  int lectureId;
  String? realTime;
  bool isAccurate;

  Lecture(
      int tableId,
      String name,
      String weeks,
      int weekTime,
      int startTime,
      int timeCount,
      int importType,
      this.lectureId,
      this.realTime,
      this.isAccurate,
      {int? id,
      String? classroom,
      String? classNumber,
      String? teacher,
      String? testTime,
      String? testLocation,
      String? link,
      String? color,
      int? courseId,
      String? info})
      : super(tableId, name, weeks, weekTime, startTime, timeCount, importType,
            id: id,
            classroom: classroom,
            classNumber: classNumber,
            teacher: teacher,
            testTime: testTime,
            testLocation: testLocation,
            link: link,
            color: color,
            courseId: courseId,
            info: info);
}
