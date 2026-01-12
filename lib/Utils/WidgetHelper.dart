import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../Models/CourseModel.dart';
import '../Models/CourseTableModel.dart';
import '../Models/ScheduleModel.dart';

class WidgetHelper {
  static const MethodChannel _channel = MethodChannel('wheretosleepinnju/widget');

  static Future<void> refreshWidget(int tableId) async {
    try {
      CourseTableProvider tableProvider = CourseTableProvider();
      List<Map> classTimeList = await tableProvider.getClassTimeList(tableId);

      String startMondayStr = await tableProvider.getSemesterStartMonday(tableId);
      int currentWeek = _calculateCurrentWeek(startMondayStr);
      
      CourseProvider courseProvider = CourseProvider();
      List rawList = await courseProvider.getAllCourses(tableId);
      List<Course> allCourses = rawList.map((e) => Course.fromMap(e)).toList();

      ScheduleModel model = ScheduleModel(allCourses, currentWeek);
      model.init(); // 执行 classify 和 deduplicate

      int todayWeekday = DateTime.now().weekday; // 1-7
      
      List<Course> todayCourses = [];
      
      todayCourses.addAll(model.activeCourses.where((c) => c.weekTime == todayWeekday));
      
      for (var list in model.multiCourses) {
        todayCourses.addAll(list.where((c) => c.weekTime == todayWeekday));
      }

      todayCourses.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

      String dateStr = _getWeekdayStr(todayWeekday);
      
      if (Platform.isAndroid) {
        await _updateAndroidWidget(todayCourses, dateStr, classTimeList);
      } else if (Platform.isIOS) {
        await _updateIOSWidget(todayCourses, dateStr, classTimeList);
      } else if (Platform.isOhos) {
        await _updateHarmonyWidget(todayCourses, dateStr, classTimeList);
      } else {
        print("This platform didn't support Widget");
      }

    } catch (e) {
      print("Flutter: Error refreshing widget: $e");
    }
  }

  static Future<void> _updateAndroidWidget(List<Course> courses, String dateStr, List<Map> classTimeList) async {
    try {
      print("Flutter[Android]: Updating widget...");
      // TODO: 实现 Android 逻辑
      // Android 通常使用 home_widget 插件，或者你自己的 MethodChannel
      // 比如：
      // await _androidChannel.invokeMethod('update', ...);
    } catch (e) {
      print("Flutter[Android]: Failed to update: $e");
    }
  }

  static Future<void> _updateIOSWidget(List<Course> courses, String dateStr, List<Map> classTimeList) async {
    try {
      print("Flutter[iOS]: Updating widget...");
      // TODO: 实现 iOS Logic (WidgetKit)
      // iOS 通常需要使用 App Groups 和 UserDefaults 共享数据
    } catch (e) {
      print("Flutter[iOS]: Failed to update: $e");
    }
  }

  static Future<void> _updateHarmonyWidget(List<Course> courses, String dateStr, List<Map> classTimeList) async {
    try {
      final List<Map<String, dynamic>> courseListJson = courses.map((course) {
        String startStr = _convertNodeToTime(course.startTime!, classTimeList);
        String endStr = _convertNodeToTime(course.startTime! + course.timeCount! - 1, classTimeList, isEnd: true);
        
        return {
          "name": course.name ?? "未知课程",
          "classroom": course.classroom ?? "",
          "color": _fixColorHex(course.color),
          "startTimeStr": startStr,
          "endTimeStr": endStr,
          "startNode": course.startTime,
          "step": course.timeCount
        };
      }).toList();

      final Map<String, dynamic> widgetData = {
        "date": dateStr,
        "courses": courseListJson
      };

      await _channel.invokeMethod('updateWidget', jsonEncode(widgetData));
      print("Flutter: Widget update sent! Weekday: $dateStr, Count: ${courses.length}");
      
    } catch (e) {
      print("Flutter: Failed to send widget data: $e");
    }
  }

  static String _convertNodeToTime(int node, List<Map> classTimeList, {bool isEnd = false}) {
    int index = node - 1;
    if (index < 0 || index >= classTimeList.length) {
      return "00:00";
    }
    
    Map timeItem = classTimeList[index];
    if (isEnd) {
      return timeItem["end"] ?? timeItem["endTime"] ?? "00:00";
    } else {
      return timeItem["start"] ?? timeItem["startTime"] ?? "00:00";
    }
  }

  static String _fixColorHex(dynamic colorRaw) {
    if (colorRaw == null) return "#FF9800"; 
    if (colorRaw is String) {
      return colorRaw.startsWith("#") ? colorRaw : "#$colorRaw";
    }
    // 如果 color 是 int (例如 0xFF0000FF)，转为 Hex String
    if (colorRaw is int) {
       return '#${colorRaw.toRadixString(16).padLeft(8, '0').substring(2)}';
    }
    return "#2196F3"; 
  }

  static int _calculateCurrentWeek(String startMondayStr) {
    if (startMondayStr.isEmpty) return 1;
    try {
      DateTime start = DateTime.parse(startMondayStr);
      // 将时间重置为当天的 00:00:00，避免时分秒影响计算
      start = DateTime(start.year, start.month, start.day);
      DateTime now = DateTime.now();
      now = DateTime(now.year, now.month, now.day);
      
      int daysDiff = now.difference(start).inDays;
      if (daysDiff < 0) return 1; // 还没开学
      
      return (daysDiff / 7).floor() + 1;
    } catch (e) {
      print("Flutter: Calc week error: $e");
      return 1;
    }
  }

  static String _getWeekdayStr(int day) {
    const days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    if (day >= 1 && day <= 7) return days[day - 1];
    return "今日";
  }

  static Future<void> runMockTest() async {
    print("Flutter: Starting Mock Test...");
    
    List<Map<String, String>> mockTimeList = [
      {"start": "08:00", "end": "08:50"}, // Node 1
      {"start": "09:00", "end": "09:50"}, // Node 2
      {"start": "10:10", "end": "11:00"}, // Node 3
      {"start": "11:10", "end": "12:00"}, // Node 4
      {"start": "14:00", "end": "14:50"}, // Node 5
      {"start": "15:00", "end": "15:50"}, // Node 6
      {"start": "16:10", "end": "17:00"}, // Node 7
      {"start": "17:10", "end": "18:00"}, // Node 8
      {"start": "18:30", "end": "19:20"}, // Node 9
      {"start": "19:30", "end": "20:20"}, // Node 10
      {"start": "20:30", "end": "21:20"}, // Node 11
      {"start": "21:30", "end": "22:20"}, // Node 12
    ];

    int todayWeekday = DateTime.now().weekday; 

    List<Course> mockCourses = [
      // 课程 A: 早上的课 (8:00 - 9:50)
      Course(
        0, // tableId
        "高等数学 (Mock)", // name
        "[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]", // weeks
        todayWeekday, // weekTime (强制今天)
        1, // startTime (第1节)
        2, // timeCount (2节课)
        0, // importType
        classroom: "仙I-101",
        color: "#FF5722", // 橙色
      ),

      // 课程 B: 下午的课 (14:00 - 15:50)
      Course(
        0,
        "Flutter 跨端开发",
        "[1,2,3]",
        todayWeekday,
        5, // startTime (第5节)
        2, // timeCount
        0,
        classroom: "费曼咖啡厅",
        color: "#2196F3", // 蓝色
      ),

      // 课程 C: 晚上的课 (18:30 - 21:20)
      Course(
        0,
        "鸿蒙原生应用",
        "[1,2,3]",
        todayWeekday,
        9, // startTime (第9节)
        3, // timeCount
        0,
        classroom: "计算机楼 202",
        color: "#9C27B0", // 紫色
      ),
    ];

    // 3. 直接调用发送逻辑
    print("Flutter: Sending ${mockCourses.length} mock courses to Native...");
    String dateStr = _getWeekdayStr(todayWeekday) + " (测试)";
    
    if (Platform.isAndroid) {
      await _updateAndroidWidget(mockCourses, dateStr, mockTimeList);
    } else if (Platform.isIOS) {
      await _updateIOSWidget(mockCourses, dateStr, mockTimeList);
    } else if (Platform.isOhos) {
      await _updateHarmonyWidget(mockCourses, dateStr, mockTimeList);
    } else {
      print("This platform didn't support widget");
    }
  }
}