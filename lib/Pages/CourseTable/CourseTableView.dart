import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import './CourseTablePresenter.dart';
import '../Settings/SettingsView.dart';
import '../../Components/Separator.dart';
import '../../Resources/Strings.dart';
import '../../Resources/Constant.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseModel.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  List<String> _WEEK = ["一", "二", "三", "四", "五", "六", "日"];
  int _mShowWeek = 7;
  int _mShowClass = 13;
  String hideColor = '#cccccc';

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
    setState(() {
      activeClasses = courseTablePresenter.activeCourses;
      hideClasses = courseTablePresenter.hideCourses;
      nowWeek = tmpNowWeek;
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
                Text(course.classroom),
              ]),
              Row(children: [
                Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                Text(course.teacher ?? ''),
              ]),
              Row(children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).primaryColor),
                Text(course.weekTime.toString()),
              ]),
              Row(children: [
                Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                Text(course.importType == Constant.ADD_BY_IMPORT
                    ? '自动导入'
                    : '手动导入'),
              ]),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(Strings.ok),
              onPressed: () {
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
                          child: Text(_WEEK[i], textAlign: TextAlign.center)),
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
//                        onTap: () => print(classes[i][DbHelper.COURSE_COLUMN_NAME]),
                            onTap: () =>
                                showClassDialog(hideClasses[i], context),
                            child: Text(
                                '[非本周]' +
                                    hideClasses[i].name +
                                    '@' +
                                    hideClasses[i].classroom,
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
                            color: HexColor(activeClasses[i].color),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
//                        onTap: () => print(classes[i][DbHelper.COURSE_COLUMN_NAME]),
                            onTap: () =>
                                showClassDialog(activeClasses[i], context),
                            child: Text(
                                activeClasses[i].name +
                                    '@' +
                                    activeClasses[i].classroom,
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
                          Strings.app_name,
                        ),
                        // TODO: 点击副标题选择周数
                        GestureDetector(
                          child: Text(
                              Strings.subtitle_pre +
                                  nowWeek.toString() +
                                  Strings.subtitle_suf,
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
                                        25,
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
                                                  '第' +
                                                      (i + 1).toString() +
                                                      '周',
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
