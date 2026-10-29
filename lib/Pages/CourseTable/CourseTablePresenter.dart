import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../Models/CourseTableModel.dart';
import '../../generated/l10n.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseGroup.dart';
import '../../Models/ScheduleModel.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Components/Dialog.dart';
import '../../Components/Toast.dart';
import '../../Components/TransBgTextButton.dart';

import 'Widgets/CourseDetailDialog.dart';
import '../EditCourse/EditCourseView.dart';
import '../../Resources/Constant.dart';
import 'Widgets/HideFreeCourseDialog.dart';
import 'Widgets/CourseDeleteDialog.dart';
import 'Widgets/CourseWidget.dart';

class CourseTablePresenter {
  CourseProvider courseProvider = CourseProvider();
  int courseCount = 0;
  List<Course> activeCourses = [];
  List<Course> hideCourses = [];
  List<List<Course>> multiCourses = [];
  List<Course> freeCourses = [];

  refreshClasses(int tableId, int nowWeek) async {
    List allCoursesMap = await courseProvider.getAllCourses(tableId);
    courseCount = allCoursesMap.length;
    List<Course> allCourses = [];
    for (Map<String, dynamic> courseMap in allCoursesMap) {
      allCourses.add(Course.fromMap(courseMap));
    }
    ScheduleModel scheduleModel = ScheduleModel(allCourses, nowWeek);
    scheduleModel.init();

    activeCourses = scheduleModel.activeCourses;
    hideCourses = scheduleModel.hideCourses;
    multiCourses = scheduleModel.multiCourses;
    freeCourses = scheduleModel.freeCourses;
  }

  Future<List<Widget>?> getClassesWidgetList(
    BuildContext context,
    double height,
    double width,
    int nowWeek,
    bool showNonCurrentWeekCourses,
  ) async {
    List colorPool = await ColorPool.getColorPool();

    // Filter hideCourses based on setting
    List<Course> filteredHideCourses = showNonCurrentWeekCourses
        ? hideCourses
        : [];

    // Filter multiCourses - only show if the first course is for current week or setting is enabled
    List<List<Course>> filteredMultiCourses = showNonCurrentWeekCourses
        ? multiCourses
        : multiCourses
              .where((courses) => isThisWeek(courses[0], nowWeek))
              .toList();

    List<Widget> result =
        List.generate(
          filteredHideCourses.length,
          (int i) => CourseWidget(
            filteredHideCourses[i],
            Config.HIDE_CLASS_COLOR,
            height,
            width,
            false,
            1,
            () => showClassDialog(context, filteredHideCourses[i], false),
            () => showDeleteDialog(context, filteredHideCourses[i]),
          ),
        ) +
        List.generate(
          activeCourses.length,
          (int i) => CourseWidget(
            activeCourses[i],
            activeCourses[i].getColor(colorPool)!,
            height,
            width,
            true,
            1,
            () => showClassDialog(context, activeCourses[i], true),
            () => showDeleteDialog(context, activeCourses[i]),
          ),
        ) +
        List.generate(
          filteredMultiCourses.length,
          (int i) => CourseWidget(
            filteredMultiCourses[i][0],
            filteredMultiCourses[i][0].getColor(colorPool)!,
            height,
            width,
            isThisWeek(filteredMultiCourses[i][0], nowWeek),
            CourseGroup.collect(filteredMultiCourses[i]).length,
            () => showMultiClassDialog(
              context,
              multiCourses.indexOf(filteredMultiCourses[i]),
              nowWeek,
            ),
            () => showDeleteDialog(context, filteredMultiCourses[i][0]),
          ),
        );
    return result;
  }

  Future<bool> showAfterImport(BuildContext context) async {
    if (!await _shouldShowDonate()) {
      return true;
    }
    Dio dio = Dio();
    String url = Url.UPDATE_ROOT + '/complete.json';
    Response response = await dio.get(url);
    String welcomeTitle = '';
    String welcomeContent = '';
    int delaySeconds = Config.DONATE_DIALOG_DELAY_SECONDS;
    if (response.statusCode == HttpStatus.ok) {
      welcomeTitle = response.data['title'];
      welcomeContent = response.data['content_html'];
      delaySeconds = response.data['delay'];
      String semesterStartMonday = response.data['semester_start_monday'];
      int index = await ScopedModel.of<MainStateModel>(context).getClassTable();
      CourseTableProvider courseTableProvider = CourseTableProvider();
      String tmpSemesterStartMonday = await courseTableProvider
          .getSemesterStartMonday(index);
      if (tmpSemesterStartMonday != "") {
        semesterStartMonday = tmpSemesterStartMonday;
      }
      bool isSameWeek = await WeekUtil.isSameWeek(semesterStartMonday, 1);
      if (!isSameWeek) {
        await changeWeek(context, semesterStartMonday);
      }
    } else {
      welcomeTitle = S.of(context).welcome_title;
      welcomeContent = S.of(context).welcome_content_html;
    }
    Timer(Duration(seconds: delaySeconds), () {
      showDonateDialog(context, welcomeTitle, welcomeContent);
    });
    return true;
  }

  Future<bool> _shouldShowDonate() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final dio = Dio();
      final response = await dio.get('${Url.UPDATE_ROOT}/showDonate.json');
      return response.data[currentVersion] ?? false;
    } catch (e) {
      return false;
    }
  }

  void showDonateDialog(
    BuildContext context,
    String welcomeTitle,
    String welcomeContent,
  ) async {
    UmengCommonSdk.onEvent("import_dialog", {"action": "show"});
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MDialog(
        welcomeTitle,
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Html(data: welcomeContent),
              Container(
                alignment: Alignment.centerRight,
                child: TransBgTextButton(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  child: Text(S.of(context).love_and_donate),
                  onPressed: () async {
                    UmengCommonSdk.onEvent("import_dialog", {
                      "action": "donate",
                    });
                    if (Platform.isIOS) {
                      _launchURL(Url.URL_APPLE);
                    } else if (Platform.isAndroid) {
                      _launchURL(Url.URL_ANDROID);
                    } else if (Platform.operatingSystem == 'ohos') {
                      _launchURL(Url.URL_OHOS);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Container(
                alignment: Alignment.centerRight,
                child: TransBgTextButton(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor
                      : Colors.white,
                  child: Text(S.of(context).bug_and_report),
                  onPressed: () {
                    UmengCommonSdk.onEvent("import_dialog", {"action": "bug"});
                    if (Platform.isIOS) {
                      _launchURL(Url.QQ_GROUP_APPLE_URL);
                    } else if (Platform.isAndroid) {
                      _launchURL(Url.QQ_GROUP_ANDROID_URL);
                    } else if (Platform.operatingSystem == 'ohos') {
                      _launchURL(Url.QQ_GROUP_OHOS_URL);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Container(
                alignment: Alignment.centerRight,
                child: TransBgTextButton(
                  color: Colors.grey,
                  child: Text(
                    S.of(context).love_but_no_money,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onPressed: () async {
                    UmengCommonSdk.onEvent("import_dialog", {
                      "action": "noMoney",
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
        overrideActions: const [],
      ),
    );
  }

  Future<bool> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> changeWeek(
    BuildContext context,
    String semesterStartMonday,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MDialog(
        S.of(context).fix_week_dialog_title,
        Text(S.of(context).fix_week_dialog_content),
        widgetCancelAction: () {
          Navigator.of(context).pop();
        },
        widgetOKAction: () async {
          await WeekUtil.initWeek(semesterStartMonday, 1);
          ScopedModel.of<MainStateModel>(context).refresh();
          Toast.showToast(S.of(context).fix_week_toast_success, context);
          Navigator.of(context).pop(true);
        },
      ),
    );
    return true;
  }

  Future<void> _showCourseDetails(
    BuildContext context,
    List<Course> courses,
    bool Function(Course) isActive,
  ) async {
    if (courses.isEmpty) return;
    final all = courses.first.tableId == null
        ? courses
        : (await courseProvider.getAllCourses(courses.first.tableId!))
              .map((row) => Course.fromMap(Map<String, dynamic>.from(row)))
              .toList();
    final groups = CourseGroup.collect(courses).map((clicked) {
      final first = clicked.first;
      return [
        first,
        ...all.where(
          (c) => c.id != first.id && CourseGroup.sameCourse(first, c),
        ),
      ];
    }).toList();
    final representatives = groups.map((g) => g.first).toList();
    final times = courses.first.tableId == null
        ? Constant.CLASS_TIME_LIST
        : await CourseTableProvider().getClassTimeList(courses.first.tableId!);
    if (!context.mounted) return;
    final selected = await showDialog<Course>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.45),
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();
        void edit(Course course) => Navigator.of(dialogContext).pop(course);
        if (representatives.length == 1) {
          return CourseDetailDialog(
            representatives.first,
            groups.first.any(isActive),
            close,
            meetings: groups.first,
            classTimeList: times,
            onEdit: () => edit(representatives.first),
          );
        }
        return CourseDetailsDialog(
          courses: representatives,
          groups: groups,
          isActive: (course) =>
              groups.firstWhere((g) => g.first.id == course.id).any(isActive),
          classTimeList: times,
          onClose: close,
          onEdit: edit,
        );
      },
    );
    if (selected == null || !context.mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCourseView(
          course: selected,
          classTimeList: times,
          meetings: groups.firstWhere((g) => g.first.id == selected.id),
        ),
      ),
    );
    if (saved == true && context.mounted) MainStateModel.of(context).refresh();
  }

  Future<void> showClassDialog(
    BuildContext context,
    Course course,
    bool isActive,
  ) {
    UmengCommonSdk.onEvent('class_click', {'type': 'single'});
    return _showCourseDetails(context, [course], (_) => isActive);
  }

  Future<void> showMultiClassDialog(BuildContext context, int i, int nowWeek) {
    UmengCommonSdk.onEvent('class_click', {'type': 'multi'});
    return _showCourseDetails(
      context,
      List.of(multiCourses[i]),
      (course) => isThisWeek(course, nowWeek),
    );
  }

  Future<void> showFreeClassDialog(BuildContext context, int nowWeek) {
    UmengCommonSdk.onEvent('class_click', {'type': 'free'});
    return _showCourseDetails(
      context,
      List.of(freeCourses),
      (course) => isThisWeek(course, nowWeek),
    );
  }

  showDeleteDialog(BuildContext context, Course course) {
    UmengCommonSdk.onEvent("class_delete", {"action": "show"});
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CourseDeleteDialog(course);
      },
    ).then((val) => ScopedModel.of<MainStateModel>(context).refresh());
  }

  showHideFreeCourseDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const HideFreeCourseDialog();
      },
    ).then((val) => ScopedModel.of<MainStateModel>(context).refresh());
  }

  bool isThisWeek(Course course, int nowWeek) {
    List weeks = json.decode(course.weeks!);
    return weeks.contains(nowWeek);
  }

  //TEST: 测试用函数
  //  Future insertMockData() async {
  //    await courseProvider.insert(new Course(
  //        0, "微积分", "[1,2,3,4,5,6,7]", 3, 5, 2, 0,
  //        color: '#8AD297', classroom: 'QAQ'));
  //    await courseProvider.insert(new Course(
  //        0, "线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
  //        color: '#F9A883', classroom: '仙林校区不知道哪个教室'));
  //    await courseProvider.insert(new Course(
  //        1, "并不是线性代数", "[1,2,3,4,5,6,7]", 4, 2, 3, 0,
  //        color: '#F9A883', classroom: 'QAQ'));
  //  }
}
