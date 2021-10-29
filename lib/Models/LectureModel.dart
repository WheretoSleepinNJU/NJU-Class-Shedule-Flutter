import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../Resources/Colors.dart';
import './CourseModel.dart';

class Lecture extends Course {
  int? id;
  String? name;
  int? tableId;

  String? classroom;
  String? classNumber;
  String? teacher;
  String? testTime;
  String? testLocation;
  String? link;
  String? info;

  String? weeks;
  int? weekTime;
  int? startTime;
  int? timeCount;
  int? importType;
  String? color;
  int? courseId;

  Lecture(this.tableId, this.name, this.weeks, this.weekTime, this.startTime,
      this.timeCount, this.importType,
      {this.id,
      this.classroom,
      this.classNumber,
      this.teacher,
      this.testTime,
      this.testLocation,
      this.link,
      this.color,
      this.courseId,
      this.info})
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
