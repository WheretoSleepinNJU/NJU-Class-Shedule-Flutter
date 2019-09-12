import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wheretosleepinnju/Resources/Colors.dart';
import './CourseTablePresenter.dart';
import '../Settings/SettingsView.dart';
import '../../Components/Separator.dart';
import '../../Resources/Config.dart';
import '../../Resources/Constant.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseModel.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  int _mShowWeek = 7;
  int _mShowClass = Config.MAX_CLASSES;
  String hideColor = HIDE_CLASS_COLOR;
  List colorPool;

  CourseTablePresenter courseTablePresenter = new CourseTablePresenter();
  List<Course> activeClasses = [];
  List<Course> hideClasses = [];
  bool weekSelectorVisibility = false;
  int nowWeek = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  getData(MainStateModel model) async {
//    await courseTablePresenter.insertMockData();
    int index = await model.getClassTable();
    int tmpNowWeek = await model.getWeek();
    await courseTablePresenter.refreshClasses(index, tmpNowWeek);
    List tmpColorPool = await ColorPool.getColorPool();
    setState(() {
      activeClasses = courseTablePresenter.activeCourses;
      hideClasses = courseTablePresenter.hideCourses;
      nowWeek = tmpNowWeek;
      colorPool = tmpColorPool;
    });
  }

//
//  getWeek(MainStateModel model) async {
//    nowWeek = await model.getWeek();
//  }

  showClassDialog(Course course, BuildContext context) {
    return showDialog<String>(
      context: context,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(course.name),
          content: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                Flexible(child: Text(course.classroom)),
              ]),
              Row(children: [
                Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                Flexible(child: Text(course.teacher ?? '')),
              ]),
              Row(children: [
                Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                Flexible(
                    child: Text(Constant.WEEK_WITH_BIAS[course.weekTime] +
                        course.startTime.toString() +
                        '-' +
                        (course.startTime + course.timeCount).toString() +
                        '节')),
              ]),
              Row(children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).primaryColor),
                Flexible(child: Text(course.weeks)),
              ]),
              Row(children: [
                Icon(Icons.android, color: Theme.of(context).primaryColor),
                Flexible(
                    child: Text(course.importType == Constant.ADD_BY_IMPORT
                        ? S.of(context).import_auto
                        : S.of(context).import_manually)),
              ]),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  showDeleteDialog(Course course, BuildContext context, int id) {
//    print(course.toMap().toString());
    return showDialog<String>(
      context: context,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).delete_class_dialog_title),
          content: Text(S.of(context).delete_class_dialog_content(course.name)),
          actions: <Widget>[
            FlatButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(S.of(context).ok),
              onPressed: () {
                CourseProvider courseProvider = new CourseProvider();
                courseProvider.delete(course.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double _mScreenWidth = MediaQuery.of(context).size.width;
    double _mClassTitleWidth = 20;
    double _mClassTitleHeight = 50;
    double _mWeekTitleHeight = 30;
    double _mWeekTitleWidth = (_mScreenWidth - _mClassTitleWidth) / _mShowWeek;

    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
            builder: (context, child, model) {
          getData(model);
          List<Widget> _weekTitle = new List.generate(
              _mShowWeek,
              (int i) => new Expanded(
                    child: Container(
//                color: Colors.deepPurpleAccent,
                      height: _mWeekTitleHeight,
                      child: Center(
                          child: Text(Constant.WEEK_WITHOUT_BIAS_WITHOUT_PRE[i],
                              textAlign: TextAlign.center)),
                      padding: EdgeInsets.all(0.0),
                    ),
                  ));

          _weekTitle.insert(
              0,
              Container(
                width: _mClassTitleWidth,
              ));

          List<Widget> _classTitle = new List.generate(
            _mShowClass,
            (int i) => new Container(
//          color: Colors.deepPurpleAccent,
                margin: EdgeInsets.only(top: i * _mClassTitleHeight),
                height: _mClassTitleHeight,
                width: _mClassTitleWidth,
                child: Center(
                    child:
                        Text((i + 1).toString(), textAlign: TextAlign.center))),
          );

          //TODO: fix bug in stack
          List<Widget> _divider = new List.generate(
              _mShowClass,
              (int i) => new Container(
                    margin: EdgeInsets.only(top: (i + 1) * _mClassTitleHeight),
                    width: _mWeekTitleWidth * _mShowWeek,
                    child: Separator(color: Colors.grey),
                  ));
//          List<Widget> _divider = new List.generate(
//              _mShowClass,
//              (int i) => new Container(
//                    margin: EdgeInsets.only(top: (i + 1) * _mClassTitleHeight),
//                    width: _mWeekTitleWidth * _mShowWeek,
//                    child: Divider(color: Colors.grey, height: 0),
//                  ));

          //Draw Classes: unused classes are on bottom
          List<Widget> _classes = new List.generate(
                  hideClasses.length,
                  (int i) => new Container(
                        margin: EdgeInsets.only(
                            top: (hideClasses[i].startTime - 1) *
                                _mClassTitleHeight,
                            left: (hideClasses[i].weekTime - 1) *
                                _mWeekTitleWidth),
                        padding: EdgeInsets.all(0.5),
                        height:
                            (hideClasses[i].timeCount + 1) * _mClassTitleHeight,
                        width: _mWeekTitleWidth,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: HexColor(hideColor),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            onLongPress: () =>
                                showDeleteDialog(hideClasses[i], context, i),
                            onTap: () =>
                                showClassDialog(hideClasses[i], context),
                            child: Text(
                                S.of(context).not_this_week +
                                    hideClasses[i].name +
                                    S.of(context).at +
                                    (hideClasses[i].classroom ??
                                        S.of(context).unknown_place),
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      )) +
              new List.generate(
                  activeClasses.length,
                  (int i) => new Container(
                        margin: EdgeInsets.only(
                            top: (activeClasses[i].startTime - 1) *
                                _mClassTitleHeight,
                            left: (activeClasses[i].weekTime - 1) *
                                _mWeekTitleWidth),
                        padding: EdgeInsets.all(0.5),
                        height: (activeClasses[i].timeCount + 1) *
                            _mClassTitleHeight,
                        width: _mWeekTitleWidth,
                        child: Ink(
                          decoration: BoxDecoration(
                            color:
                                HexColor(activeClasses[i].getColor(colorPool)),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            onLongPress: () =>
                                showDeleteDialog(activeClasses[i], context, i),
                            onTap: () =>
                                showClassDialog(activeClasses[i], context),
                            child: Text(
                                activeClasses[i].name +
                                    S.of(context).at +
                                    (activeClasses[i].classroom ??
                                        S.of(context).unknown_place),
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ));

          return Scaffold(
              appBar: AppBar(
                  centerTitle: true,
                  title: Column(
//                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.of(context).app_name,
                        ),
                        // TODO: 点击副标题选择周数
                        GestureDetector(
                          child: Text(S.of(context).week(nowWeek.toString()),
                              style: TextStyle(fontSize: 16)),
                          onTap: () {
                            weekSelectorVisibility = !weekSelectorVisibility;
                          },
                        )
                      ]),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.lightbulb_outline),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => SettingsView()));
                      },
                    )
                  ]),
              body: LayoutBuilder(builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                //TODO: 背景图片
                return Stack(children: [
//                  Container(
//                      decoration: BoxDecoration(
//                      color: Colors.grey,
////                      image: DecorationImage(
////                        image: AssetImage("assets/images/bulb.jpg"),
////                        fit: BoxFit.cover,
////                      ),
//                          )),
                  SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                        Visibility(
                            visible: weekSelectorVisibility,
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: ClampingScrollPhysics(),
                                child: Row(
                                    children: List.generate(
                                        Config.MAX_WEEKS,
                                        (int i) => new Container(
                                            color:
                                                Theme.of(context).primaryColor,
                                            padding: EdgeInsets.only(
                                                left: 5,
                                                top: 10,
                                                right: 5,
                                                bottom: 10),
                                            child: InkWell(
                                                onTap: () =>
                                                    model.changeWeek(i + 1),
                                                child: Text(
                                                  S
                                                      .of(context)
                                                      .week((i + 1).toString()),
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15),
                                                ))))))),
                        Container(child: Row(children: _weekTitle)),
                        Row(children: [
                          Container(
                              height: _mClassTitleHeight * _mShowClass,
                              width: _mClassTitleWidth,
                              child: Stack(children: _classTitle)),
                          Container(
                              height: _mClassTitleHeight * _mShowClass,
                              width: _mScreenWidth - _mClassTitleWidth,
                              //TODO: fix bug in stack
                              child: Stack(
                                  children: _divider + _classes,
//                                  children: _classes,
                                  overflow: Overflow.visible))
                        ])
                      ]))
                ]);
              }));
        }));
  }
}
