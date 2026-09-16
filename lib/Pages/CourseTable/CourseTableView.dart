import 'dart:async';

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
import '../../Models/CourseTableModel.dart';
import '../../Models/CourseModel.dart';

import 'Widgets/BackgroundImage.dart';
import 'Widgets/ClassTitle.dart';
import 'Widgets/WeekTitle.dart';

class CourseTableView extends StatefulWidget {
  const CourseTableView({Key? key}) : super(key: key);

  @override
  CourseTableViewState createState() => CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  final CourseTablePresenter _presenter = CourseTablePresenter();
  PageController? _weekPageController;
  ScrollController? _scrollController;
  Timer? _swipeHintTimer;
  bool _isFreeClassVisible = true;
  bool _shouldPlayImportSwipeHint = false;
  bool _isSwipeHintVisible = false;
  bool _isPlayingSwipeHint = false;
  double _lastScrollOffset = 0;
  int _swipeHintToken = 0;
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
  late String _bgImgPath;
  int _freeCourseNum = 0;

  List<Course> multiClassesDialog = [];

  Future<bool>? _getData(BuildContext context) async {
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
    _isShowNonCurrentWeekCourses = await ScopedModel.of<MainStateModel>(context)
        .getShowNonCurrentWeekCourses();

    _isShowAddButton =
        await ScopedModel.of<MainStateModel>(context).getAddButton();

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

    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _weekTitleHeight = 30;
    _classTitleWidth = 40;
    _snackbarHeight = 55;
    _weekTitleWidth = (_screenWidth - _classTitleWidth) / _maxShowDays;
    int height = await ScopedModel.of<MainStateModel>(context).getClassHeight();

    if (_isForceZoom) {
      // 强制缩放时，课程表填满整个屏幕，FreeClass 浮动覆盖在上方
      _classTitleHeight = (_screenHeight -
              kToolbarHeight -
              MediaQuery.of(context).padding.top -
              (_isShowDate ? _weekTitleHeight * 1.2 : _weekTitleHeight)) /
          _maxShowClasses;
    } else if (height.toDouble() != 0) {
      _classTitleHeight = height.toDouble();
    } else {
      _classTitleHeight = 52;
    }

    return true;
  }

  Future<List<Widget>> _buildClassesWidgetListByWeek(
      BuildContext context, int weekNum) async {
    final CourseTablePresenter presenter = CourseTablePresenter();
    await presenter.refreshClasses(_tableIndex, weekNum);
    return (await presenter.getClassesWidgetList(context, _classTitleHeight,
            _weekTitleWidth, weekNum, _isShowNonCurrentWeekCourses)) ??
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
    final double currentPage = _weekPageController!.page ??
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

  void _queueImportSwipeHint() {
    _shouldPlayImportSwipeHint = true;
  }

  void _scheduleImportSwipeHint() {
    if (!_shouldPlayImportSwipeHint || _isPlayingSwipeHint) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldPlayImportSwipeHint || _isPlayingSwipeHint) {
        return;
      }
      _swipeHintTimer?.cancel();
      _swipeHintTimer = Timer(
        const Duration(milliseconds: 600),
        _playImportSwipeHint,
      );
    });
  }

  void _cancelImportSwipeHint() {
    if (!_shouldPlayImportSwipeHint &&
        !_isSwipeHintVisible &&
        !_isPlayingSwipeHint) {
      return;
    }
    _swipeHintToken++;
    _shouldPlayImportSwipeHint = false;
    _swipeHintTimer?.cancel();
    if (_isSwipeHintVisible && mounted) {
      setState(() {
        _isSwipeHintVisible = false;
      });
    }
  }

  void _releaseImportSwipeHintToUserGesture() {
    _cancelImportSwipeHint();
    _isPlayingSwipeHint = false;
  }

  Future<void> _playImportSwipeHint() async {
    if (!mounted || !_shouldPlayImportSwipeHint) {
      return;
    }
    final PageController? controller = _weekPageController;
    if (controller == null || !controller.hasClients) {
      _scheduleImportSwipeHint();
      return;
    }

    final position = controller.position;
    if (position.viewportDimension <= 0 || position.isScrollingNotifier.value) {
      _scheduleImportSwipeHint();
      return;
    }

    final int startPage =
        (_nowShowWeekNum - 1).clamp(0, Config.MAX_WEEKS - 1).toInt();
    final bool canTurnNext = startPage < Config.MAX_WEEKS - 1;
    final bool canTurnPrevious = startPage > 0;
    if (!canTurnNext && !canTurnPrevious) {
      _shouldPlayImportSwipeHint = false;
      return;
    }

    final int token = ++_swipeHintToken;
    final int targetPage = canTurnNext ? startPage + 1 : startPage - 1;

    setState(() {
      _isSwipeHintVisible = true;
    });
    _isPlayingSwipeHint = true;

    try {
      if (mounted && token == _swipeHintToken && _shouldPlayImportSwipeHint) {
        await controller.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
        );
      }
      if (mounted && token == _swipeHintToken && _shouldPlayImportSwipeHint) {
        await Future.delayed(const Duration(milliseconds: 280));
      }
      if (mounted && token == _swipeHintToken && _shouldPlayImportSwipeHint) {
        await controller.animateToPage(
          startPage,
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
        );
      }
    } finally {
      if (token == _swipeHintToken) {
        _shouldPlayImportSwipeHint = false;
      }
      _isPlayingSwipeHint = false;
      if (mounted && token == _swipeHintToken) {
        setState(() {
          _isSwipeHintVisible = false;
        });
      }
    }
  }

  Widget _buildSwipeHint(BuildContext context) {
    final int backgroundAlpha =
        Theme.of(context).brightness == Brightness.light ? 235 : 219;
    final Color backgroundColor =
        Theme.of(context).colorScheme.surface.withAlpha(backgroundAlpha);
    final Color foregroundColor = Theme.of(context).colorScheme.onSurface;

    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(46),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 18, color: foregroundColor),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context).swipe_week_hint_title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      S.of(context).swipe_week_hint_subtitle,
                      style: TextStyle(
                        color: foregroundColor.withAlpha(173),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, size: 18, color: foregroundColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  basicCheck() async {
    UpdateUtil updateUtil = UpdateUtil();
    await updateUtil.checkUpdate(context, false);
    PrivacyUtil privacyUtil = PrivacyUtil();
    bool privacyRst = await privacyUtil.checkPrivacy(context, false);
    if (!privacyRst) return;
    //初始化组件化基础库, 所有友盟业务SDK都必须调用此初始化接口。
    UmengCommonSdk.initCommon(
        '5f8ef217fac90f1c19a7b0f3', '5f9e1efa1c520d30739d2737', 'Umeng');
    UmengCommonSdk.setPageCollectionModeAuto();
    // UmengCommonSdk.onEvent("privacy_accept", {"result":"accept"});
    bool rst = await Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => const ImportView())) ??
        false;
    if (!rst) return;
    await _presenter.showAfterImport(context);
    _queueImportSwipeHint();
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    basicCheck();
  }

  @override
  void dispose() {
    _swipeHintTimer?.cancel();
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    _weekPageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
            builder: (context, child, model) {
          UmengCommonSdk.onEvent("course_refresh", {"action": "refresh"});
          debugPrint('CourseTableView refreshed.');

          return FutureBuilder<bool>(
              future: _getData(context),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (!snapshot.hasData) {
                  return Container(color: Colors.white);
                } else {
                  _syncWeekPageController();
                  _scheduleImportSwipeHint();

                  String nowWeek =
                      S.of(context).week(_nowShowWeekNum.toString());

                  if (_nowWeekNum < 1) {
                    nowWeek = S.of(context).not_open + ' ' + nowWeek;
                  } else if (_nowWeekNum != _nowShowWeekNum) {
                    nowWeek = S.of(context).not_this_week + ' ' + nowWeek;
                  }
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
                    overlayStyle = _isWhiteMode!
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark;
                  }

                  Color? appBarColor;
                  if (_isWhiteMode == null) {
                    appBarColor = null;
                  } else {
                    appBarColor = Colors.transparent;
                  }

                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                        backgroundColor: appBarColor,
                        systemOverlayStyle: overlayStyle,
                        iconTheme: IconThemeData(color: mainColor),
                        centerTitle: true,
                        title: Column(children: [
//                          TextView(),
                          Text(S.of(context).app_name,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: mainColor)),
                          Text((nowWeek),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: mainColor))
                        ]),
                        actions: <Widget>[
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              // color: Colors.white,
                            ),
                            onPressed: () async {
                              _cancelImportSwipeHint();
                              UmengCommonSdk.onEvent(
                                  "setting_click", {"action": "success"});
                              bool? status = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          const SettingsView()));
                              if (status == true) {
                                await _presenter.showAfterImport(context);
                                _queueImportSwipeHint();
                              }
                              ScopedModel.of<MainStateModel>(context).refresh();
                            },
                          )
                        ]),
                    body: Stack(children: [
                      Positioned.fill(child: BackgroundImage(_bgImgPath)),
                      SafeArea(
                        top: false,
                        child: Stack(children: [
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
                                top: MediaQuery.of(context).padding.top +
                                    kToolbarHeight),
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
                                          _nowShowWeekNum - _nowWeekNum),
                                      Flexible(
                                          child: Listener(
                                              onPointerDown: (_) =>
                                                  _cancelImportSwipeHint(),
                                              child: NotificationListener<
                                                      ScrollStartNotification>(
                                                  onNotification:
                                                      (notification) {
                                                    if (notification
                                                            .dragDetails !=
                                                        null) {
                                                      _releaseImportSwipeHintToUserGesture();
                                                    }
                                                    return false;
                                                  },
                                                  child: PageView.builder(
                                                      controller:
                                                          _weekPageController,
                                                      itemCount:
                                                          Config.MAX_WEEKS,
                                                      onPageChanged:
                                                          (int index) {
                                                        final int targetWeek =
                                                            index + 1;
                                                        if (targetWeek !=
                                                            _nowShowWeekNum) {
                                                          _nowShowWeekNum =
                                                              targetWeek;
                                                          if (_isPlayingSwipeHint) {
                                                            model.changeTmpWeek(
                                                                targetWeek);
                                                            return;
                                                          }
                                                          _cancelImportSwipeHint();
                                                          model.changeTmpWeek(
                                                              targetWeek);
                                                          UmengCommonSdk
                                                              .onEvent(
                                                                  "week_choose",
                                                                  {
                                                                "action":
                                                                    "swipe"
                                                              });
                                                          // 切换周次时重置 FreeClass 显示状态
                                                          if (!_isFreeClassVisible) {
                                                            setState(() {
                                                              _isFreeClassVisible =
                                                                  true;
                                                              _lastScrollOffset =
                                                                  0;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int pageIndex) {
                                                        final int weekNum =
                                                            pageIndex + 1;
                                                        return FutureBuilder<
                                                                List<Widget>>(
                                                            future:
                                                                _buildClassesWidgetListByWeek(
                                                                    context,
                                                                    weekNum),
                                                            builder: (BuildContext
                                                                    context,
                                                                AsyncSnapshot<
                                                                        List<
                                                                            Widget>>
                                                                    classesSnapshot) {
                                                              if (!classesSnapshot
                                                                  .hasData) {
                                                                return const SizedBox
                                                                    .expand();
                                                              }
                                                              List<Widget>
                                                                  divider =
                                                                  List.generate(
                                                                      _maxShowClasses,
                                                                      (int i) =>
                                                                          Container(
                                                                            margin:
                                                                                EdgeInsets.only(top: (i + 1) * _classTitleHeight),
                                                                            width:
                                                                                _weekTitleWidth * _maxShowDays,
                                                                            child:
                                                                                const Separator(color: Colors.grey),
                                                                          ));
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
                                                                                _classTimeList),
                                                                        SizedBox(
                                                                            height: _classTitleHeight *
                                                                                _maxShowClasses,
                                                                            width: _screenWidth -
                                                                                _classTitleWidth,
                                                                            child:
                                                                                Stack(clipBehavior: Clip.none, children: divider + classesSnapshot.data!))
                                                                      ]));
                                                            });
                                                      })))),
                                    ]),
                                // FreeClass 浮动在底部，不遮挡课程内容
                                if ((_isShowFreeClass) && (_freeCourseNum > 0))
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    left: 0,
                                    right: 0,
                                    bottom: _isFreeClassVisible ? 30.0 : -100.0,
                                    child: Padding(
                                      // 1. 侧边 Padding，让组件不贴屏幕边缘，产生悬浮感
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Material(
                                        // 2. 悬浮阴影高度
                                        elevation: 6.0,
                                        // 3. 胶囊型圆角
                                        shape: const StadiumBorder(),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        // 限制高度
                                        child: SizedBox(
                                          height: _snackbarHeight,
                                          // 内部 Padding，避免文字和按钮贴紧胶囊边缘
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0),
                                            child: Row(
                                              children: [
                                                // 左侧文本区域 (Expanded 保证撑开空间，FittedBox 保证文字不越界)
                                                Expanded(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      S
                                                          .of(context)
                                                          .free_class_banner(
                                                              _freeCourseNum
                                                                  .toString()),
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                        fontWeight: FontWeight
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
                                                    _cancelImportSwipeHint();
                                                    _presenter
                                                        .showFreeClassDialog(
                                                            context,
                                                            _nowShowWeekNum);
                                                  },
                                                  child: Text(
                                                    S
                                                        .of(context)
                                                        .free_class_button,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
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
                                                  onTap: () {
                                                    _cancelImportSwipeHint();
                                                    _presenter
                                                        .showHideFreeCourseDialog(
                                                            context);
                                                  },
                                                  child: Text(
                                                    S
                                                        .of(context)
                                                        .hide_free_class_button,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
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
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  left: 0,
                                  right: 0,
                                  bottom: (_isShowFreeClass &&
                                          _freeCourseNum > 0 &&
                                          _isFreeClassVisible)
                                      ? _snackbarHeight + 46.0
                                      : 30.0,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    opacity: _isSwipeHintVisible ? 1 : 0,
                                    child: _buildSwipeHint(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ]),
                    floatingActionButton: _isShowAddButton
                        ? Padding(
                            padding:
                                const EdgeInsets.only(bottom: 50.0, left: 10.0),
                            child: FloatingActionButton(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              onPressed: () async {
                                _cancelImportSwipeHint();
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            const AddView()))
                                    .then((val) =>
                                        ScopedModel.of<MainStateModel>(context)
                                            .refresh());
                              },
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ))
                        : Container(),
                  );
                }
              });
        }));
  }
}
