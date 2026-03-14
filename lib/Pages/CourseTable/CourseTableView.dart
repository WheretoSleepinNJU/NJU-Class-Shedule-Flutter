import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/Config.dart';
import '../../Resources/Constant.dart';
import '../../Resources/PrototypePalette.dart';
import '../../Utils/PrivacyUtil.dart';
import '../../Utils/UpdateUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Utils/WidgetHelper.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../About/AboutView.dart';
import '../AddCourse/AddCourseView.dart';
import '../Import/ImportView.dart';
import '../Lecture/LecturesView.dart';
import '../ManageTable/ManageTableView.dart';
import '../Settings/MoreSettingsView.dart';
import '../Settings/WidgetSettingsView.dart';
import '../Share/ShareView.dart';
import 'CourseTablePresenter.dart';
import 'Widgets/BackgroundImage.dart';

class CourseTableView extends StatefulWidget {
  const CourseTableView({Key? key}) : super(key: key);

  @override
  CourseTableViewState createState() => CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  final CourseTablePresenter _presenter = CourseTablePresenter();
  final ScrollController _scrollController = ScrollController();
  PageController? _weekPageController;

  bool _startupHandled = false;
  bool _isFreeClassVisible = true;
  double _lastScrollOffset = 0;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupChecks();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _weekPageController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double currentOffset = _scrollController.offset;
    final double delta = currentOffset - _lastScrollOffset;
    if (delta > 2 && _isFreeClassVisible) {
      setState(() => _isFreeClassVisible = false);
    } else if (delta < -2 && !_isFreeClassVisible) {
      setState(() => _isFreeClassVisible = true);
    }
    _lastScrollOffset = currentOffset;
  }

  Future<void> _runStartupChecks() async {
    if (_startupHandled || !mounted) {
      return;
    }
    _startupHandled = true;

    await UpdateUtil().checkUpdate(context, false);
    final bool privacyPassed = await PrivacyUtil().checkPrivacy(context, false);
    if (!privacyPassed || !mounted) {
      return;
    }

    final CourseTableProvider provider = CourseTableProvider();
    final List tables = await provider.getAllCourseTable();
    if (tables.isNotEmpty || !mounted) {
      return;
    }

    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (BuildContext context) => const ImportView()),
    );
    if (result == true && mounted) {
      await _presenter.showAfterImport(context);
      ScopedModel.of<MainStateModel>(context).refresh();
      setState(() {});
    }
  }

  Future<_HomeData> _loadData(BuildContext context) async {
    final MainStateModel model = MainStateModel.of(context);
    final bool showWeekend = await model.getShowWeekend();
    final bool showClassTime = await model.getShowClassTime();
    final bool showFreeClass = await model.getShowFreeClass();
    final bool showMonth = await model.getShowMonth();
    final bool showDate = await model.getShowDate();
    final bool forceZoom = await model.getForceZoom();
    final bool showNonCurrentWeekCourses =
        await model.getShowNonCurrentWeekCourses();
    final String bgImgPath = await model.getBgImgPath();
    final bool? isWhiteMode =
        bgImgPath.isEmpty ? null : await model.getWhiteMode();
    final int classHeight = await model.getClassHeight();
    final int tableIndex = await model.getClassTable();
    final int nowWeekNum = await model.getWeek();
    int nowShowWeekNum = await model.getTmpWeek();
    if (nowShowWeekNum < 1) {
      nowShowWeekNum = 1;
    }
    if (nowShowWeekNum > Config.MAX_WEEKS) {
      nowShowWeekNum = Config.MAX_WEEKS;
    }

    await _presenter.refreshClasses(tableIndex, nowShowWeekNum);
    WidgetHelper.refreshWidget(tableIndex);

    final CourseTableProvider tableProvider = CourseTableProvider();
    final List<Map> rawTables =
        List<Map>.from(await tableProvider.getAllCourseTable());
    List<Map> classTimeList;
    try {
      classTimeList = await tableProvider.getClassTimeList(tableIndex);
    } catch (e) {
      classTimeList = Constant.CLASS_TIME_LIST;
    }

    final CourseProvider courseProvider = CourseProvider();
    final List rawCourses = await courseProvider.getAllCourses(tableIndex);
    final List<Course> allCourses = rawCourses
        .map((dynamic item) => Course.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final List<Course> activeCourses =
        List<Course>.from(_presenter.activeCourses);
    final List<Course> freeCourses = List<Course>.from(_presenter.freeCourses);

    final int todayWeekday = DateTime.now().weekday;
    final List<Course> todayCourses = activeCourses
        .where((Course course) =>
            _isThisWeek(course, nowShowWeekNum) &&
            course.weekTime == todayWeekday)
        .toList()
      ..sort((Course a, Course b) => a.startTime!.compareTo(b.startTime!));

    final List<Course> examCourses = allCourses
        .where((Course course) =>
            (course.testTime?.trim().isNotEmpty ?? false) ||
            (course.testLocation?.trim().isNotEmpty ?? false))
        .toList();
    /*

    String currentTableName = '还没有课表';
    // * /
    String currentTableName = '还没有课表';
    */
    String currentTableName = '还没有课表';
    for (final Map item in rawTables) {
      if (item['id'] == tableIndex) {
        currentTableName = item['name']?.toString() ?? currentTableName;
        break;
      }
    }

    return _HomeData(
      showWeekend: showWeekend,
      showClassTime: showClassTime,
      showFreeClass: showFreeClass,
      showMonth: showMonth,
      showDate: showDate,
      forceZoom: forceZoom,
      showNonCurrentWeekCourses: showNonCurrentWeekCourses,
      classHeight: classHeight == 0 ? 52 : classHeight,
      bgImgPath: bgImgPath,
      isWhiteMode: isWhiteMode,
      tableIndex: tableIndex,
      currentTableName: currentTableName,
      nowWeekNum: nowWeekNum,
      nowShowWeekNum: nowShowWeekNum,
      maxShowDays: showWeekend ? 7 : 5,
      maxShowClasses: classTimeList.length,
      classTimeList: classTimeList,
      activeCourses: activeCourses,
      freeCourses: freeCourses,
      allCourses: allCourses,
      todayCourses: todayCourses.isEmpty
          ? activeCourses.take(3).toList(growable: false)
          : todayCourses,
      examCourses: examCourses,
      courseTables: rawTables,
    );
  }

  bool _isThisWeek(Course course, int weekNum) {
    final List<dynamic> weeks = json.decode(course.weeks!);
    return weeks.contains(weekNum);
  }

  void _syncWeekPageController(int nowShowWeekNum) {
    final int targetPage = nowShowWeekNum - 1;
    if (_weekPageController == null) {
      _weekPageController = PageController(initialPage: targetPage);
      return;
    }
    if (!_weekPageController!.hasClients) {
      return;
    }
    final double currentPage = _weekPageController!.page ??
        _weekPageController!.initialPage.toDouble();
    if ((currentPage - targetPage).abs() < 0.001) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _weekPageController == null) {
        return;
      }
      if (_weekPageController!.hasClients) {
        _weekPageController!.jumpToPage(targetPage);
      }
    });
  }

  Future<List<Widget>> _buildCourseWidgetsForWeek(
    BuildContext context,
    _HomeData data,
    double classHeight,
    double dayWidth,
    int weekNum,
  ) async {
    final CourseTablePresenter presenter = CourseTablePresenter();
    await presenter.refreshClasses(data.tableIndex, weekNum);
    return (await presenter.getClassesWidgetList(
          context,
          classHeight,
          dayWidth,
          weekNum,
          data.showNonCurrentWeekCourses,
        )) ??
        <Widget>[];
  }

  Future<void> _openPage(
    Widget page, {
    bool refreshOnReturn = true,
  }) async {
    final dynamic result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (BuildContext context) => page),
    );
    if (!mounted || !refreshOnReturn) {
      return;
    }
    if (result == true) {
      await _presenter.showAfterImport(context);
    }
    ScopedModel.of<MainStateModel>(context).refresh();
    setState(() {});
  }

  Future<void> _showQuickActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: DuckPalette.page,
                borderRadius: BorderRadius.circular(32),
                boxShadow: DuckPalette.softShadow(0.12),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: DuckPalette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ActionTile(
                    icon: Icons.draw_rounded,
                    iconBg: DuckPalette.orangeSoft,
                    iconColor: DuckPalette.orangeText,
                    title: '手动添加',
                    subtitle: '直接创建新课程',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPage(const AddView());
                    },
                  ),
                  _ActionTile(
                    icon: Icons.cloud_download_rounded,
                    iconBg: DuckPalette.duckYellowSoft,
                    iconColor: DuckPalette.textMain,
                    title: '导入课表',
                    subtitle: '从教务系统快速同步',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPage(const ImportView());
                    },
                  ),
                  _ActionTile(
                    icon: Icons.celebration_rounded,
                    iconBg: DuckPalette.aquaSoft,
                    iconColor: DuckPalette.aquaText,
                    title: '校园讲座',
                    subtitle: '查看现有讲座数据',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openPage(const LectureView(), refreshOnReturn: false);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSettingsSheet(_HomeData data, MainStateModel model) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: DuckPalette.page,
                borderRadius: BorderRadius.circular(32),
                boxShadow: DuckPalette.softShadow(0.12),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(
                      child: Text(
                        '上课鸭设置',
                        style: TextStyle(
                          color: DuckPalette.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SurfaceInfoCard(
                      title: '当前课表',
                      value: data.currentTableName,
                    ),
                    const SizedBox(height: 12),
                    _StepperTile(
                      label: '当前周次',
                      value: '${data.nowShowWeekNum}',
                      onDecrease: () {
                        model.changeTmpWeek(
                            math.max(1, data.nowShowWeekNum - 1));
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      onIncrease: () {
                        model.changeTmpWeek(math.min(
                            Config.MAX_WEEKS, data.nowShowWeekNum + 1));
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _ToggleTile(
                      label: '显示周末',
                      value: data.showWeekend,
                      onChanged: (bool value) {
                        model.setShowWeekend(value);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      label: '显示节次时间',
                      value: data.showClassTime,
                      onChanged: (bool value) {
                        model.setShowClassTime(value);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      label: '显示日期',
                      value: data.showDate,
                      onChanged: (bool value) {
                        model.setShowDate(value);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      label: '显示月份',
                      value: data.showMonth,
                      onChanged: (bool value) {
                        model.setShowMonth(value);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      label: '铺满课表',
                      value: data.forceZoom,
                      onChanged: (bool value) {
                        model.setForceZoom(value);
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildWeekTitle(BuildContext context, _HomeData data) {
    String title = S.of(context).week(data.nowShowWeekNum.toString());
    if (data.nowWeekNum < 1) {
      title = '${S.of(context).not_open} $title';
    } else if (data.nowWeekNum != data.nowShowWeekNum) {
      title = '${S.of(context).not_this_week} $title';
    }
    return title;
  }

  String _buildDateLabel(BuildContext context, int weekBias) {
    final Locale locale = Localizations.localeOf(context);
    final String localeKey = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    final DateTime date = DateTime.now().add(Duration(days: weekBias * 7));
    if (locale.languageCode == 'zh') {
      return DateFormat('yyyy年M月d日 · EEEE', localeKey).format(date);
    }
    return DateFormat('MMM d, y · EEEE', localeKey).format(date);
  }

  String _buildCourseSubtitle(Course course) {
    final List<String> parts = <String>[];
    if (course.teacher?.isNotEmpty == true) {
      parts.add(course.teacher!);
    }
    if (course.classroom?.isNotEmpty == true) {
      parts.add(course.classroom!);
    }
    if (parts.isEmpty) {
      parts.add('点击查看课程详情');
    }
    return parts.join(' · ');
  }

  Widget _buildSchedulePage(
      BuildContext context, _HomeData data, MainStateModel model) {
    final int weekBias = data.nowShowWeekNum - data.nowWeekNum;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: BackgroundImage(data.bgImgPath)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ChipButton(
                      icon: Icons.menu_rounded,
                      onTap: () => _showSettingsSheet(data, model),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(
                            _buildWeekTitle(context, data),
                            style: const TextStyle(
                              color: DuckPalette.textMain,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildDateLabel(context, weekBias),
                            style: const TextStyle(
                              color: DuckPalette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ChipButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () =>
                          _openPage(const ShareView(), refreshOnReturn: false),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: _weekPageController,
                    itemCount: Config.MAX_WEEKS,
                    onPageChanged: (int index) {
                      model.changeTmpWeek(index + 1);
                      if (!_isFreeClassVisible) {
                        setState(() {
                          _isFreeClassVisible = true;
                          _lastScrollOffset = 0;
                        });
                      }
                    },
                    itemBuilder: (BuildContext context, int pageIndex) {
                      return _buildScheduleWeek(
                        context,
                        data,
                        pageIndex + 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleWeek(BuildContext context, _HomeData data, int weekNum) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double leftWidth = 44;
        const double headerHeight = 50;
        final double dayWidth =
            (constraints.maxWidth - leftWidth) / data.maxShowDays;
        final double classHeight = data.forceZoom
            ? math.max(
                44,
                (constraints.maxHeight - headerHeight - 12) /
                    data.maxShowClasses,
              )
            : data.classHeight.toDouble();
        final List<String> dayList =
            WeekUtil.getTmpDayList(weekNum - data.nowWeekNum);
        final int todayWeekday = DateTime.now().weekday;

        return Column(
          children: <Widget>[
            Container(
              height: headerHeight,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DuckPalette.pageSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: leftWidth),
                  for (int index = 0; index < data.maxShowDays; index++)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: weekNum == data.nowWeekNum &&
                                  todayWeekday == index + 1
                              ? DuckPalette.duckYellowSoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              Constant.WEEK_WITHOUT_BIAS_WITHOUT_PRE[index],
                              style: TextStyle(
                                color: weekNum == data.nowWeekNum &&
                                        todayWeekday == index + 1
                                    ? const Color(0xFFB98500)
                                    : DuckPalette.textMain,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayList[index],
                              style: const TextStyle(
                                color: DuckPalette.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Widget>>(
                future: _buildCourseWidgetsForWeek(
                  context,
                  data,
                  classHeight,
                  dayWidth,
                  weekNum,
                ),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<Widget>> snapshot,
                ) {
                  final List<Widget> courseWidgets =
                      snapshot.data ?? <Widget>[];
                  return Container(
                    decoration: BoxDecoration(
                      color: DuckPalette.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: DuckPalette.softShadow(),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: SizedBox(
                          height: classHeight * data.maxShowClasses,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: leftWidth,
                                child: Column(
                                  children: List<Widget>.generate(
                                    data.maxShowClasses,
                                    (int index) {
                                      final Map time =
                                          data.classTimeList[index];
                                      return SizedBox(
                                        width: leftWidth,
                                        height: classHeight,
                                        child: Center(
                                          child: data.showClassTime
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: DuckPalette
                                                            .textMain,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${time['start']}\n${time['end']}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: DuckPalette
                                                            .textMuted,
                                                        fontSize: 9,
                                                        height: 1.15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: DuckPalette.textMain,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth - leftWidth,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    for (int col = 0;
                                        col < data.maxShowDays;
                                        col++)
                                      Positioned(
                                        left: dayWidth * col,
                                        top: 0,
                                        width: dayWidth,
                                        height:
                                            classHeight * data.maxShowClasses,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: weekNum == data.nowWeekNum &&
                                                    todayWeekday == col + 1
                                                ? DuckPalette.duckYellowSoft
                                                    .withValues(alpha: 0.35)
                                                : Colors.transparent,
                                            border: Border(
                                              left: BorderSide(
                                                color: DuckPalette.line
                                                    .withValues(alpha: 0.65),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    for (int row = 1;
                                        row < data.maxShowClasses;
                                        row++)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: classHeight * row - 0.5,
                                        child: Container(
                                          height: 1,
                                          color: DuckPalette.line.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ...courseWidgets,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodoPage(BuildContext context, _HomeData data) {
    final List<Course> courses = data.todayCourses.take(3).toList();
    final List<Course> exams = data.examCourses.take(2).toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: Text(
                '待办',
                style: TextStyle(
                  color: DuckPalette.textMain,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                '今天也要把课程和考试安排得明明白白',
                style: TextStyle(
                  color: DuckPalette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FilterWrap(),
            const SizedBox(height: 22),
            const _SectionLabel('作业'),
            const SizedBox(height: 12),
            if (courses.isEmpty)
              _TodoCard(
                icon: Icons.calendar_month_rounded,
                title: '今天没有待办课程',
                subtitle: '去课表页看看完整安排吧',
                onTap: () => setState(() => _tabIndex = 0),
              ),
            for (final Course course in courses)
              _TodoCard(
                icon: Icons.radio_button_unchecked_rounded,
                title: course.name ?? '',
                subtitle: _buildCourseSubtitle(course),
                onTap: () => _presenter.showClassDialog(context, course, true),
              ),
            const SizedBox(height: 20),
            const _SectionLabel('考试'),
            const SizedBox(height: 12),
            if (exams.isEmpty)
              _TodoCard(
                icon: Icons.event_note_rounded,
                title: '还没有考试提醒',
                subtitle: '导入包含考试信息的课表后会显示在这里',
                onTap: () => _openPage(const ImportView()),
              ),
            for (final Course course in exams)
              _TodoCard(
                icon: Icons.radio_button_unchecked_rounded,
                title: course.name ?? '',
                subtitle: (course.testTime?.isNotEmpty ?? false)
                    ? '${course.testTime} · ${course.testLocation ?? '地点待定'}'
                    : (course.testLocation ?? '考试信息待补充'),
                onTap: () => _presenter.showClassDialog(context, course, true),
              ),
            const SizedBox(height: 20),
            const _SectionLabel('讲座'),
            const SizedBox(height: 12),
            _TodoCard(
              icon: Icons.radio_button_unchecked_rounded,
              title: '浏览校园讲座',
              subtitle: '查看现有讲座与活动数据',
              onTap: () =>
                  _openPage(const LectureView(), refreshOnReturn: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage(BuildContext context, _HomeData data) {
    final int todayCount = data.todayCourses.length;
    final String mood = todayCount >= 5
        ? '充实'
        : todayCount >= 3
            ? '很棒'
            : '轻松';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: Text(
                '我的鸭窝',
                style: TextStyle(
                  color: DuckPalette.textMain,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                '上课鸭',
                style: TextStyle(
                  color: DuckPalette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DuckPalette.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: DuckPalette.softShadow(0.07),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _StatItem(
                      value: '${data.allCourses.length}',
                      label: '已导入课程',
                      color: DuckPalette.textMain,
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _StatItem(
                      value: '${data.examCourses.length}',
                      label: '考试提醒',
                      color: DuckPalette.duckYellow,
                    ),
                  ),
                  _VerticalDivider(),
                  Expanded(
                    child: _StatItem(
                      value: mood,
                      label: '今日状态',
                      color: const Color(0xFF5B9A55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '设置',
              style: TextStyle(
                color: DuckPalette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileRow(
              title: '外观与主题',
              icon: Icons.palette_outlined,
              onTap: () => _openPage(const MoreSettingsView()),
            ),
            _ProfileRow(
              title: '提醒与通知',
              icon: Icons.notifications_none_rounded,
              onTap: () => _openPage(
                Platform.isIOS
                    ? const WidgetSettingsView()
                    : const MoreSettingsView(),
              ),
            ),
            _ProfileRow(
              title: '课表管理',
              icon: Icons.view_week_outlined,
              onTap: () => _openPage(const ManageTableView()),
            ),
            _ProfileRow(
              title: '分享课表',
              icon: Icons.ios_share_rounded,
              onTap: () => _openPage(const ShareView(), refreshOnReturn: false),
            ),
            _ProfileRow(
              title: '关于上课鸭',
              icon: Icons.info_outline_rounded,
              onTap: () => _openPage(const AboutView(), refreshOnReturn: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeClassBanner(BuildContext context, _HomeData data) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: 18,
      right: 84,
      bottom: _isFreeClassVisible ? 104 + bottomInset : -100,
      child: Material(
        color: DuckPalette.duckYellowSoft,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () =>
              _presenter.showFreeClassDialog(context, data.nowShowWeekNum),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.hourglass_empty_rounded,
                  color: DuckPalette.textMain,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    S
                        .of(context)
                        .free_class_banner(data.freeCourses.length.toString()),
                    style: const TextStyle(
                      color: DuckPalette.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  S.of(context).free_class_button,
                  style: const TextStyle(
                    color: Color(0xFFB98500),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 28,
      right: 28,
      bottom: 24 + bottomInset,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: DuckPalette.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: DuckPalette.softShadow(0.08),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: <Widget>[
            _BottomNavItem(
              icon: Icons.calendar_month_rounded,
              label: '课表',
              active: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            _BottomNavItem(
              icon: Icons.fact_check_rounded,
              label: '待办',
              active: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            _BottomNavItem(
              icon: Icons.person_rounded,
              label: '我的',
              active: _tabIndex == 2,
              onTap: () => setState(() => _tabIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Positioned(
      right: 32,
      bottom: 104 + bottomInset,
      child: GestureDetector(
        onTap: _showQuickActions,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: DuckPalette.duckYellow,
            borderRadius: BorderRadius.circular(28),
            boxShadow: DuckPalette.floatingShadow(),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
      child: ScopedModelDescendant<MainStateModel>(
        builder: (BuildContext context, Widget? child, MainStateModel model) {
          return FutureBuilder<_HomeData>(
            future: _loadData(context),
            builder: (
              BuildContext context,
              AsyncSnapshot<_HomeData> snapshot,
            ) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  backgroundColor: DuckPalette.page,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final _HomeData data = snapshot.data!;
              _syncWeekPageController(data.nowShowWeekNum);
              FlutterNativeSplash.remove();

              return Scaffold(
                backgroundColor: DuckPalette.page,
                body: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _tabIndex == 0
                          ? _buildSchedulePage(context, data, model)
                          : _tabIndex == 1
                              ? _buildTodoPage(context, data)
                              : _buildProfilePage(context, data),
                    ),
                    if (_tabIndex == 0 &&
                        data.showFreeClass &&
                        data.freeCourses.isNotEmpty)
                      _buildFreeClassBanner(context, data),
                    _buildBottomNavigation(),
                    _buildFloatingActionButton(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.showWeekend,
    required this.showClassTime,
    required this.showFreeClass,
    required this.showMonth,
    required this.showDate,
    required this.forceZoom,
    required this.showNonCurrentWeekCourses,
    required this.classHeight,
    required this.bgImgPath,
    required this.isWhiteMode,
    required this.tableIndex,
    required this.currentTableName,
    required this.nowWeekNum,
    required this.nowShowWeekNum,
    required this.maxShowDays,
    required this.maxShowClasses,
    required this.classTimeList,
    required this.activeCourses,
    required this.freeCourses,
    required this.allCourses,
    required this.todayCourses,
    required this.examCourses,
    required this.courseTables,
  });

  final bool showWeekend;
  final bool showClassTime;
  final bool showFreeClass;
  final bool showMonth;
  final bool showDate;
  final bool forceZoom;
  final bool showNonCurrentWeekCourses;
  final int classHeight;
  final String bgImgPath;
  final bool? isWhiteMode;
  final int tableIndex;
  final String currentTableName;
  final int nowWeekNum;
  final int nowShowWeekNum;
  final int maxShowDays;
  final int maxShowClasses;
  final List<Map> classTimeList;
  final List<Course> activeCourses;
  final List<Course> freeCourses;
  final List<Course> allCourses;
  final List<Course> todayCourses;
  final List<Course> examCourses;
  final List<Map> courseTables;
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DuckPalette.duckYellowSofter,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: DuckPalette.textMain, size: 20),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        active ? const Color(0xFFD89B00) : DuckPalette.textMuted;
    return Expanded(
      child: Material(
        color: active ? DuckPalette.duckYellowSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterWrap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DuckPalette.softShadow(0.05),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(child: _FilterPill(active: true, label: '未完成')),
          Expanded(child: _FilterPill(active: false, label: '已完成')),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    Key? key,
    required this.active,
    required this.label,
  }) : super(key: key);

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? DuckPalette.duckYellowSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? DuckPalette.textMain : DuckPalette.textMuted,
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {Key? key}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: DuckPalette.textMain,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: DuckPalette.softShadow(0.06),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Icon(icon, color: DuckPalette.textMuted, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: DuckPalette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: DuckPalette.softShadow(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: DuckPalette.textMain),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: DuckPalette.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DuckPalette.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    Key? key,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DuckPalette.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFE5DED4),
    );
  }
}

class _SurfaceInfoCard extends StatelessWidget {
  const _SurfaceInfoCard({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: DuckPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: DuckPalette.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DuckPalette.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    Key? key,
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  }) : super(key: key);

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DuckPalette.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _MiniIconButton(
            icon: Icons.remove_rounded,
            onTap: onDecrease,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DuckPalette.textMain,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniIconButton(
            icon: Icons.add_rounded,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DuckPalette.duckYellowSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: DuckPalette.textMain),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    Key? key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DuckPalette.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: DuckPalette.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: DuckPalette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DuckPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
