import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

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
import '../../Models/CourseModel.dart';

import 'Widgets/BackgroundImage.dart';
import 'Widgets/WeekSelector.dart';
import 'Widgets/ClassTitle.dart';
import 'Widgets/WeekTitle.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  CourseTablePresenter _presenter = new CourseTablePresenter();
  late bool _isShowWeekend;
  late bool _isShowClassTime;
  late bool _isShowFreeClass;
  late bool _isShowMonth;
  late bool _isShowDate;
  late bool _isForceZoom;
  late bool _isShowAddButton;
  late bool _isWhiteMode;
  late int _maxShowClasses;
  late int _maxShowDays;
  late int _nowWeekNum;
  late int _nowShowWeekNum;
  late double _screenWidth;
  late double _screenHeight;
  late double _classTitleWidth;
  late double _classTitleHeight;
  late double _weekTitleHeight;
  late double _weekTitleWidth;
  late String _bgImgPath;
  int _freeCourseNum = 0;

  bool weekSelectorVisibility = false;

  List<Course> multiClassesDialog = [];

  Future<List<Widget>>? _getData(BuildContext context) async {
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

    _isShowAddButton =
        await ScopedModel.of<MainStateModel>(context).getAddButton();
    _isWhiteMode = await ScopedModel.of<MainStateModel>(context).getWhiteMode();

    _bgImgPath = await ScopedModel.of<MainStateModel>(context).getBgImgPath();
    _maxShowClasses = Config.MAX_CLASSES;
    _maxShowDays = _isShowWeekend ? 7 : 5;
    int index = await ScopedModel.of<MainStateModel>(context).getClassTable();
    _nowWeekNum = await ScopedModel.of<MainStateModel>(context).getWeek();
    _nowShowWeekNum =
        await ScopedModel.of<MainStateModel>(context).getTmpWeek();

    await _presenter.refreshClasses(index, _nowShowWeekNum);
    _freeCourseNum = _presenter.freeCourses.length;

    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _weekTitleHeight = 30;
    _classTitleWidth = 40;
    _weekTitleWidth = (_screenWidth - _classTitleWidth) / _maxShowDays;
    if (_isForceZoom)
      _classTitleHeight = (_screenHeight -
              kToolbarHeight -
              MediaQuery.of(context).padding.top -
              (_isShowDate ? _weekTitleHeight * 1.2 : _weekTitleHeight)) /
          _maxShowClasses;
    else
      _classTitleHeight = 52;

    List<Widget>? classWidgets = await _presenter.getClassesWidgetList(
        context, _classTitleHeight, _weekTitleWidth, _nowShowWeekNum);

    return classWidgets!;
  }

  basicCheck() async {
    UpdateUtil updateUtil = new UpdateUtil();
    await updateUtil.checkUpdate(context, false);
    PrivacyUtil privacyUtil = new PrivacyUtil();
    bool privacyRst = await privacyUtil.checkPrivacy(context, false);
    if (!privacyRst) return;
    bool rst = await Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => ImportView())) ??
        false;
    if (!rst) return;
    await _presenter.showAfterImport(context);
    ScopedModel.of<MainStateModel>(context).refresh();
  }

  @override
  void initState() {
    super.initState();
    basicCheck();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
            builder: (context, child, model) {
          print('CourseTableView refreshed.');

          return FutureBuilder<List<Widget>>(
              future: _getData(context),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
                if (!snapshot.hasData) {
                  return Container(color: Colors.white);
                } else {
                  // TODO: fix bug in stack
                  List<Widget> _divider = new List.generate(
                      _maxShowClasses,
                      (int i) => new Container(
                            margin: EdgeInsets.only(
                                top: (i + 1) * _classTitleHeight),
                            width: _weekTitleWidth * _maxShowDays,
                            child: Separator(color: Colors.grey),
                          ));

                  String nowWeek =
                      S.of(context).week(_nowShowWeekNum.toString());

                  if (_nowWeekNum < 1) {
                    nowWeek = S.of(context).not_open + ' ' + nowWeek;
                  } else if (_nowWeekNum != _nowShowWeekNum) {
                    nowWeek = S.of(context).not_this_week + ' ' + nowWeek;
                  }
                  double height = MediaQuery.of(context).size.height;

                  return Scaffold(
                    appBar: AppBar(
                        centerTitle: true,
                        title: Column(children: [
//                          TextView(),
                          Text(S.of(context).app_name),
                          GestureDetector(
                            child:
                                Text((nowWeek), style: TextStyle(fontSize: 14)),
                            onTap: () => setState(() {
                              weekSelectorVisibility = !weekSelectorVisibility;
                            }),
                          )
                        ]),
                        actions: <Widget>[
                          IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () async {
                              bool? status = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          SettingsView()));
                              if (status == true) {
                                await _presenter.showAfterImport(context);
                              }
                              ScopedModel.of<MainStateModel>(context).refresh();
                            },
                          )
                        ]),
                    body: Stack(children: [
                      _bgImgPath == null
                          ? Container()
                          : BackgroundImage(_bgImgPath),
                      //   Container(
                      // decoration: _bgImgPath == ""
                      //     ? BoxDecoration()
                      //     : BoxDecoration(
                      //         image: DecorationImage(
                      //           image: AssetImage(_bgImgPath),
                      //           fit: BoxFit.cover,
                      //         ),
                      //       ),
                      // child:
                      Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
                        WeekSelector(model, weekSelectorVisibility),
                        WeekTitle(
                            _maxShowDays,
                            _weekTitleHeight,
                            _classTitleWidth,
                            _isShowMonth,
                            _isShowDate,
                            _isWhiteMode,
                            _nowShowWeekNum - _nowWeekNum),
                        Flexible(
                            child: SingleChildScrollView(
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                              ClassTitle(
                                  _maxShowClasses,
                                  _classTitleHeight,
                                  _classTitleWidth,
                                  _isShowClassTime,
                                  _isWhiteMode),
                              Container(
                                  height: _classTitleHeight * _maxShowClasses,
                                  width: _screenWidth - _classTitleWidth,
                                  // TODO: fix bug in stack
                                  child: Stack(
                                      children: _divider + snapshot.data!,
                                      overflow: Overflow.visible))
                            ]))),
                        ((!_isShowFreeClass) || (_freeCourseNum == 0))
                            ? Container()
                            : MaterialBanner(
                                content: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        S.of(context).free_class_banner(
                                            _freeCourseNum.toString()),
                                        style: TextStyle(color: Colors.white))),
                                backgroundColor: Theme.of(context).primaryColor,
                                actions: [
                                  Row(
                                    children: [
                                      TextButton(
                                        child: Text(
                                            S.of(context).free_class_button,
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () =>
                                            _presenter.showFreeClassDialog(
                                                context, _nowShowWeekNum),
                                        style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.zero),
                                      ),
                                      TextButton(
                                        child: Text(
                                            S
                                                .of(context)
                                                .hide_free_class_button,
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () => _presenter
                                            .showHideFreeCourseDialog(context),
                                        style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.zero),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                      ]),
                      // ),
                    ]),
                    floatingActionButton: _isShowAddButton
                        ? Padding(
                            padding:
                                const EdgeInsets.only(bottom: 50.0, left: 10.0),
                            child: FloatingActionButton(
                              backgroundColor: Theme.of(context).primaryColor,
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          AddView())),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ))
                        : Container(),
                  );
                }
              });
        }));
  }
}
