import '../../AdaptiveUI/adaptive_ui.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../Resources/Constant.dart';
import '../../Utils/WidgetHelper.dart';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

//import 'package:text_view/text_view.dart';
import './CourseTablePresenter.dart';
import '../AddCourse/AddCourseView.dart';
import '../Settings/SettingsView.dart';
import '../Import/ImportView.dart';
import '../../Components/Separator.dart';
import '../../Resources/Config.dart';
import '../../Utils/States/MainState.dart';
import '../../Utils/PrivacyUtil.dart';
import '../../Utils/UpdateUtil.dart';
import '../../Utils/WeekUtil.dart';
import '../../Utils/BackgroundService.dart';
import '../../Models/CourseTableModel.dart';
import '../../Models/CourseModel.dart';

import 'Widgets/BackgroundImage.dart';
import 'Widgets/ClassTitle.dart';
import 'Widgets/WeekTitle.dart';
import 'Widgets/TimetableHeader.dart';
import 'Widgets/WeekPickerSheet.dart';

class CourseTableView extends StatefulWidget {
  const CourseTableView({Key? key}) : super(key: key);

  @override
  CourseTableViewState createState() => CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView>
    with WidgetsBindingObserver {
  final CourseTablePresenter _presenter = CourseTablePresenter();
  PageController? _weekPageController;
  ScrollController? _scrollController;
  Timer? _dateRefreshTimer;
  late Future<String> _backgroundVisit;
  bool _isFreeClassVisible = true;
  double _lastScrollOffset = 0;
  late bool _isShowWeekend;
  late bool _isShowClassTime;
  late bool _isShowFreeClass;
  late bool _isShowMonth;
  late bool _isShowDate;
  late bool _isForceZoom;
  late bool _isShowNonCurrentWeekCourses;
  late List<Map> _classTimeList;
  late bool _isShowAddButton;
  late bool? _isWhiteMode;
  late int _maxShowClasses;
  late int _maxShowDays;
  late int _tableIndex;
  late int _nowWeekNum;
  late int _nowShowWeekNum;
  late double _screenWidth;
  late double _screenHeight;
  late double _classTitleWidth;
  late double _classTitleHeight;
  late double _weekTitleHeight;
  late double _weekTitleWidth;
  late double _snackbarHeight;
  late double _toolbarHeight;
  late TextScaler _tableTextScaler;
  late String _bgImgPath;
  int _freeCourseNum = 0;

  List<Course> multiClassesDialog = [];

  Future<bool>? _getData(
    BuildContext context,
    MediaQueryData mediaQuery,
  ) async {
    //    await courseTablePresenter.insertMockData();

    _isShowWeekend =
        await ScopedModel.of<MainStateModel>(context).getShowWeekend();

    _isShowClassTime =
        await ScopedModel.of<MainStateModel>(context).getShowClassTime();
    _isShowFreeClass =
        await ScopedModel.of<MainStateModel>(context).getShowFreeClass();
    _isShowMonth = await ScopedModel.of<MainStateModel>(context).getShowMonth();
    _isShowDate = await ScopedModel.of<MainStateModel>(context).getShowDate();
    _isForceZoom = await ScopedModel.of<MainStateModel>(context).getForceZoom();
    _isShowNonCurrentWeekCourses =
        await ScopedModel.of<MainStateModel>(
          context,
        ).getShowNonCurrentWeekCourses();

    _isShowAddButton =
        await ScopedModel.of<MainStateModel>(context).getAddButton();

    await _backgroundVisit;
    _bgImgPath = await ScopedModel.of<MainStateModel>(context).getBgImgPath();

    if (_bgImgPath == '') {
      _isWhiteMode = null;
    } else {
      _isWhiteMode =
          await ScopedModel.of<MainStateModel>(context).getWhiteMode();
    }

    _maxShowDays = _isShowWeekend ? 7 : 5;
    _tableIndex = await ScopedModel.of<MainStateModel>(context).getClassTable();
    _nowWeekNum = await ScopedModel.of<MainStateModel>(context).getWeek();
    _nowShowWeekNum =
        await ScopedModel.of<MainStateModel>(context).getTmpWeek();

    await _presenter.refreshClasses(_tableIndex, _nowShowWeekNum);

    WidgetHelper.refreshWidget(_tableIndex);
    // WidgetHelper.runMockTest();

    _freeCourseNum = _presenter.freeCourses.length;

    try {
      CourseTableProvider courseTableProvider = CourseTableProvider();
      _classTimeList = await courseTableProvider.getClassTimeList(_tableIndex);
      _maxShowClasses = _classTimeList.length;
    } catch (e) {
      _classTimeList = Constant.CLASS_TIME_LIST;
      _maxShowClasses = Config.MAX_CLASSES;
    }

    // The timetable is inside SafeArea; landscape iPhones reserve horizontal
    // space for the sensor housing on both sides of the content.
    _screenWidth = mediaQuery.size.width - mediaQuery.padding.horizontal;
    _screenHeight = mediaQuery.size.height;
    // Seven day columns share a fixed width. Keep this compact overview
    // readable without letting period labels squeeze out the courses.
    // Settings and course details retain the full system text scale.
    _tableTextScaler = mediaQuery.textScaler.clamp(maxScaleFactor: 1.4);
    final textScale = _tableTextScaler.scale(12) / 12;
    _toolbarHeight = TimetableHeader.toolbarHeight(mediaQuery.textScaler);
    _weekTitleHeight = 30 * textScale;
    _classTitleWidth = 40 * textScale;
    _snackbarHeight = 55;
    _weekTitleWidth = (_screenWidth - _classTitleWidth) / _maxShowDays;
    int height = await ScopedModel.of<MainStateModel>(context).getClassHeight();

    if (_isForceZoom) {
      // 强制缩放时，课程表填满整个屏幕，FreeClass 浮动覆盖在上方
      _classTitleHeight =
          (_screenHeight -
              _toolbarHeight -
              mediaQuery.padding.top -
              (_isShowDate ? _weekTitleHeight * 1.2 : _weekTitleHeight)) /
          _maxShowClasses;
    } else if (height.toDouble() != 0) {
      _classTitleHeight = height.toDouble();
    } else {
      _classTitleHeight = 52;
    }
    // Keep period labels readable at accessibility font sizes. The timetable
    // already scrolls vertically, so fitting every row must not clip labels.
    final minimumRowHeight = (_isShowClassTime ? 52.0 : 24.0) * textScale;
    if (_classTitleHeight < minimumRowHeight) {
      _classTitleHeight = minimumRowHeight;
    }

    return true;
  }

  Future<List<Widget>> _buildClassesWidgetListByWeek(
    BuildContext context,
    int weekNum,
  ) async {
    final CourseTablePresenter presenter = CourseTablePresenter();
    await presenter.refreshClasses(_tableIndex, weekNum);
    return (await presenter.getClassesWidgetList(
          context,
          _classTitleHeight,
          _weekTitleWidth,
          weekNum,
          _isShowNonCurrentWeekCourses,
        )) ??
        [];
  }

  void _syncWeekPageController() {
    final int targetPage = _nowShowWeekNum - 1;
    if (_weekPageController == null) {
      _weekPageController = PageController(initialPage: targetPage);
      return;
    }
    if (!_weekPageController!.hasClients) {
      return;
    }
    final double currentPage =
        _weekPageController!.page ??
        _weekPageController!.initialPage.toDouble();
    final bool isScrolling =
        _weekPageController!.position.isScrollingNotifier.value;
    if (!isScrolling && (currentPage - targetPage).abs() > 0.001) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _weekPageController == null) {
          return;
        }
        if (_weekPageController!.hasClients &&
            !_weekPageController!.position.isScrollingNotifier.value) {
          _weekPageController!.jumpToPage(targetPage);
        }
      });
    }
  }

  basicCheck() async {
    UpdateUtil updateUtil = UpdateUtil();
    await updateUtil.checkUpdate(context, false);
    PrivacyUtil privacyUtil = PrivacyUtil();
    bool privacyRst = await privacyUtil.checkPrivacy(context, false);
    if (!privacyRst) return;
    //初始化组件化基础库, 所有友盟业务SDK都必须调用此初始化接口。
    UmengCommonSdk.initCommon(
      '5f8ef217fac90f1c19a7b0f3',
      '5f9e1efa1c520d30739d2737',
      'Umeng',
    );
    UmengCommonSdk.setPageCollectionModeAuto();
    // UmengCommonSdk.onEvent("privacy_accept", {"result":"accept"});
    bool rst =
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const ImportView(),
          ),
        ) ??
        false;
    if (!rst) return;
    await _presenter.showAfterImport(context);
    setState(() {
      ScopedModel.of<MainStateModel>(context).refresh();
    });
  }

  void _onScroll() {
    if (_scrollController == null) return;
    final currentOffset = _scrollController!.offset;
    final direction = currentOffset - _lastScrollOffset;

    // 下滑（内容向上滚动）隐藏，上滑（内容向下滚动）显示
    if (direction > 2) {
      // 下滑超过阈值，隐藏
      if (_isFreeClassVisible) {
        setState(() {
          _isFreeClassVisible = false;
        });
      }
    } else if (direction < -2) {
      // 上滑超过阈值，显示
      if (!_isFreeClassVisible) {
        setState(() {
          _isFreeClassVisible = true;
        });
      }
    }
    _lastScrollOffset = currentOffset;
  }

  Future<void> _chooseWeek(BuildContext context, MainStateModel model) async {
    final selection = await showWeekPickerSheet(
      context,
      currentWeek: _nowWeekNum,
      displayedWeek: _nowShowWeekNum,
    );
    if (selection == null || !mounted) return;
    if (selection.changesCurrentWeek) {
      await model.changeWeek(selection.week);
    } else {
      await model.changeTmpWeek(selection.week);
    }
    UmengCommonSdk.onEvent('week_choose', {
      'action': selection.changesCurrentWeek ? 'set_current' : 'view',
    });
  }

  void _scheduleDateRefresh() {
    _dateRefreshTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _dateRefreshTimer = Timer(
      midnight.difference(now) + const Duration(seconds: 1),
      _refreshCalendarDate,
    );
  }

  Future<void> _refreshCalendarDate({bool newVisit = false}) async {
    _backgroundVisit = BackgroundService.instance.ensureCurrent(
      newVisit: newVisit,
    );
    await _backgroundVisit;
    await WeekUtil.checkWeek();
    if (!mounted) return;
    setState(() {});
    _scheduleDateRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCalendarDate(newVisit: ModalRoute.of(context)?.isCurrent == true);
    }
  }

  @override
  void initState() {
    super.initState();
    _backgroundVisit = BackgroundService.instance.ensureCurrent(newVisit: true);
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRefresh();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    basicCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRefreshTimer?.cancel();
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    _weekPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read here so system font/viewport changes rebuild the row geometry,
    // rather than only rescaling labels inside the existing timetable.
    final mediaQuery = MediaQuery.of(context);
    return ScopedModel<MainStateModel>(
      model: MainStateModel(),
      child: ScopedModelDescendant<MainStateModel>(
        builder: (context, child, model) {
          UmengCommonSdk.onEvent("course_refresh", {"action": "refresh"});
          debugPrint('CourseTableView refreshed.');

          return FutureBuilder<bool>(
            future: _getData(context, mediaQuery),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData) {
                return Container(color: Colors.white);
              } else {
                _syncWeekPageController();

                // double height = MediaQuery.of(context).size.height;
                FlutterNativeSplash.remove();

                Color? mainColor;
                if (_isWhiteMode == null) {
                  mainColor = null;
                } else {
                  mainColor = _isWhiteMode! ? Colors.white : Colors.black;
                }

                SystemUiOverlayStyle overlayStyle;
                if (_isWhiteMode == null) {
                  overlayStyle =
                      Theme.of(context).brightness == Brightness.dark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark;
                } else {
                  overlayStyle =
                      _isWhiteMode!
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark;
                }
                overlayStyle = overlayStyle.copyWith(
                  statusBarColor: Colors.transparent,
                  systemStatusBarContrastEnforced: false,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                  systemNavigationBarIconBrightness:
                      _isWhiteMode == null
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark)
                          : (_isWhiteMode!
                              ? Brightness.light
                              : Brightness.dark),
                );

                Color? appBarColor;
                if (_isWhiteMode == null) {
                  appBarColor = null;
                } else {
                  appBarColor = Colors.transparent;
                }

                return AdaptiveScaffold(
                  extendBodyBehindAppBar: true,
                  appBar: AdaptiveTopAppBar(
                    backgroundColor: appBarColor,
                    systemOverlayStyle: overlayStyle,
                    iconTheme: IconThemeData(color: mainColor),
                    centerTitle: false,
                    automaticallyImplyLeading: false,
                    titleSpacing: 16,
                    toolbarHeight: _toolbarHeight,
                    title: TimetableHeader(
                      displayedWeek: _nowShowWeekNum,
                      currentWeek: _nowWeekNum,
                      date: DateTime.now(),
                      foregroundColor: mainColor,
                      onTap: () => _chooseWeek(context, model),
                    ),
                    actions: <Widget>[
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          // color: Colors.white,
                        ),
                        onPressed: () async {
                          UmengCommonSdk.onEvent("setting_click", {
                            "action": "success",
                          });
                          bool? status = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (BuildContext context) =>
                                      const SettingsView(),
                            ),
                          );
                          _backgroundVisit = BackgroundService.instance
                              .ensureCurrent();
                          await _backgroundVisit;
                          if (!mounted) return;
                          if (status == true) {
                            await _presenter.showAfterImport(context);
                          }
                          ScopedModel.of<MainStateModel>(context).refresh();
                        },
                      ),
                    ],
                  ),
                  body: Stack(
                    children: [
                      Positioned.fill(child: BackgroundImage(_bgImgPath)),
                      SafeArea(
                        top: false,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.4,
                          child: Stack(
                            children: [
                              //   Container(
                              // decoration: _bgImgPath == ""
                              //     ? BoxDecoration()
                              //     : BoxDecoration(
                              //         image: DecorationImage(
                              //           image: AssetImage(_bgImgPath),
                              //           fit: BoxFit.cover,
                              //         ),
                              //       ),
                              Padding(
                                padding: EdgeInsets.only(
                                  top:
                                      MediaQuery.of(context).padding.top +
                                      _toolbarHeight,
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        WeekTitle(
                                          _maxShowDays,
                                          _weekTitleHeight,
                                          _classTitleWidth,
                                          _isShowMonth,
                                          _isShowDate,
                                          _isWhiteMode,
                                          _nowShowWeekNum - _nowWeekNum,
                                        ),
                                        Flexible(
                                          child: PageView.builder(
                                            controller: _weekPageController,
                                            itemCount: math.max(
                                              Config.MAX_WEEKS,
                                              math.max(
                                                _nowWeekNum,
                                                _nowShowWeekNum,
                                              ),
                                            ),
                                            onPageChanged: (int index) {
                                              final int targetWeek = index + 1;
                                              if (targetWeek !=
                                                  _nowShowWeekNum) {
                                                model.changeTmpWeek(targetWeek);
                                                UmengCommonSdk.onEvent(
                                                  "week_choose",
                                                  {"action": "swipe"},
                                                );
                                                // 切换周次时重置 FreeClass 显示状态
                                                if (!_isFreeClassVisible) {
                                                  setState(() {
                                                    _isFreeClassVisible = true;
                                                    _lastScrollOffset = 0;
                                                  });
                                                }
                                              }
                                            },
                                            itemBuilder: (
                                              BuildContext context,
                                              int pageIndex,
                                            ) {
                                              final int weekNum = pageIndex + 1;
                                              return FutureBuilder<
                                                List<Widget>
                                              >(
                                                future:
                                                    _buildClassesWidgetListByWeek(
                                                      context,
                                                      weekNum,
                                                    ),
                                                builder: (
                                                  BuildContext context,
                                                  AsyncSnapshot<List<Widget>>
                                                  classesSnapshot,
                                                ) {
                                                  if (!classesSnapshot
                                                      .hasData) {
                                                    return const SizedBox.expand();
                                                  }
                                                  List<Widget>
                                                  divider = List.generate(
                                                    _maxShowClasses,
                                                    (int i) => Container(
                                                      margin: EdgeInsets.only(
                                                        top:
                                                            (i + 1) *
                                                            _classTitleHeight,
                                                      ),
                                                      width:
                                                          _weekTitleWidth *
                                                          _maxShowDays,
                                                      child: const Separator(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                  return SingleChildScrollView(
                                                    controller:
                                                        _scrollController,
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        ClassTitle(
                                                          _maxShowClasses,
                                                          _classTitleHeight,
                                                          _classTitleWidth,
                                                          _isShowClassTime,
                                                          _isWhiteMode,
                                                          classTimeList:
                                                              _classTimeList,
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              _classTitleHeight *
                                                              _maxShowClasses,
                                                          width:
                                                              _screenWidth -
                                                              _classTitleWidth,
                                                          child: Stack(
                                                            clipBehavior:
                                                                Clip.none,
                                                            children:
                                                                divider +
                                                                classesSnapshot
                                                                    .data!,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    // FreeClass 浮动在底部，不遮挡课程内容
                                    if ((_isShowFreeClass) &&
                                        (_freeCourseNum > 0))
                                      AnimatedPositioned(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        left: 0,
                                        right: 0,
                                        bottom:
                                            _isFreeClassVisible ? 30.0 : -100.0,
                                        child: Padding(
                                          // 1. 侧边 Padding，让组件不贴屏幕边缘，产生悬浮感
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Material(
                                            // 2. 悬浮阴影高度
                                            elevation: 6.0,
                                            // 3. 胶囊型圆角
                                            shape: const StadiumBorder(),
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                            // 限制高度
                                            child: SizedBox(
                                              height: _snackbarHeight,
                                              // 内部 Padding，避免文字和按钮贴紧胶囊边缘
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    // 左侧文本区域 (Expanded 保证撑开空间，FittedBox 保证文字不越界)
                                                    Expanded(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        alignment:
                                                            Alignment
                                                                .centerLeft,
                                                        child: Text(
                                                          S
                                                              .of(context)
                                                              .free_class_banner(
                                                                _freeCourseNum
                                                                    .toString(),
                                                              ),
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500, // 稍微加粗一点会让现代感更强（可选）
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // 右侧文字区域
                                                    const SizedBox(width: 12),
                                                    // 文本和文字之间的间距
                                                    InkWell(
                                                      onTap: () {
                                                        _presenter
                                                            .showFreeClassDialog(
                                                              context,
                                                              _nowShowWeekNum,
                                                            );
                                                      },
                                                      child: Text(
                                                        S
                                                            .of(context)
                                                            .free_class_button,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // 两个文字之间的间距
                                                    InkWell(
                                                      onTap:
                                                          () => _presenter
                                                              .showHideFreeCourseDialog(
                                                                context,
                                                              ),
                                                      child: Text(
                                                        S
                                                            .of(context)
                                                            .hide_free_class_button,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  floatingActionButton:
                      _isShowAddButton
                          ? Padding(
                            padding: const EdgeInsets.only(
                              bottom: 50.0,
                              left: 10.0,
                            ),
                            child: FloatingActionButton(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              onPressed: () async {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder:
                                            (BuildContext context) =>
                                                const AddView(),
                                      ),
                                    )
                                    .then(
                                      (val) =>
                                          ScopedModel.of<MainStateModel>(
                                            context,
                                          ).refresh(),
                                    );
                              },
                              child: Icon(
                                Icons.add,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                          : Container(),
                );
              }
            },
          );
        },
      ),
    );
  }
}
