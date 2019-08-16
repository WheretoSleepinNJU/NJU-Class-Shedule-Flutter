import 'package:flutter/material.dart';
import '../Settings/SettingsView.dart';
import '../../Components/Separator.dart';
import '../../Resources/Strings.dart';
import '../../Resources/Color.dart';
import './CourseTablePresenter.dart';
import '../../Models/Db/DbHelper.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  List<String> _WEEK = ["一", "二", "三", "四", "五", "六", "日"];
  int _mShowWeek = 7;
  int _mShowClass = 13;

  CourseTablePresenter courseTablePresenter = new CourseTablePresenter();
  List<Map> classes = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setClassData();
  }

  //TODO: mock data
//  var classes = [
//    {'weekday': 3, 'start': 5, 'step': 2, 'name': 'QAQ', 'color': '#8AD297'},
//    {'weekday': 4, 'start': 2, 'step': 3, 'name': 'QWQ', 'color': '#F9A883'},
////    {'weekday': 4, 'start': 3, 'step': 3, 'name': 'QWQ', 'color': '#8AD297'},
//  ];

  setClassData() async {
    await courseTablePresenter.insertMockData();
    List<Map> tmp = await courseTablePresenter.getClasses();
    setState(() {
      classes = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    double _mScreenWidth = MediaQuery.of(context).size.width;
    double _mClassTitleWidth = 20;
    double _mClassTitleHeight = 50;
    double _mWeekTitleHeight = 30;
    double _mWeekTitleWidth = (_mScreenWidth - _mClassTitleWidth) / _mShowWeek;

    List<Widget> _weekTitle = new List.generate(
        _mShowWeek,
        (int i) => new Expanded(
              child: Container(
//                color: Colors.deepPurpleAccent,
                height: _mWeekTitleHeight,
                child:
                    Center(child: Text(_WEEK[i], textAlign: TextAlign.center)),
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
              child: Text((i + 1).toString(), textAlign: TextAlign.center))),
    );

    //TODO: fix bug in stack
//    List<Widget> _divider = new List.generate(
//        _mShowClass,
//        (int i) => new Container(
//              margin: EdgeInsets.only(top: (i + 1) * _mClassTitleHeight),
//              width: _mWeekTitleWidth * _mShowWeek,
//              child: Separator(color: Colors.grey),
//            ));
    List<Widget> _divider = new List.generate(
        _mShowClass,
        (int i) => new Container(
              margin: EdgeInsets.only(top: (i + 1) * _mClassTitleHeight),
              width: _mWeekTitleWidth * _mShowWeek,
              child: Divider(color: Colors.grey),
            ));

    /**
     * Draw Classes
     */
    List<Widget> _classes = new List.generate(
        classes.length,
        (int i) => new Container(
              margin: EdgeInsets.only(
                  top: (classes[i][DbHelper.COURSE_COLUMN_START_TIME] as int) * _mClassTitleHeight,
                  left: (classes[i][DbHelper.COURSE_COLUMN_WEEK_TIME] as int) * _mWeekTitleWidth),
              height: (classes[i][DbHelper.COURSE_COLUMN_TIME_COUNT] as int) * _mClassTitleHeight,
              width: _mWeekTitleWidth,
              child: Ink(
                decoration: BoxDecoration(
//                  color: Colors.red,
                  color: HexColor(classes[i][DbHelper.COURSE_COLUMN_COLOR]),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  onTap: () {},
                  child: Text(classes[i][DbHelper.COURSE_COLUMN_NAME],
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ));

    /**
     * Draw Background
     */
//    _classes.insert(
//        0,
//        Positioned.fill(
//          child: Container(color: Colors.white),
//        ));

    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Column(children: [
              Text(
                Strings.app_name,
              ),
              // TODO: 点击副标题选择周数
              GestureDetector(
                child: Text(Strings.subtitle_pre + Strings.subtitle_suf,
                    style: TextStyle(fontSize: 16)),
                onTap: () {
//                Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => SettingsView()));
                },
              )
            ]),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.lightbulb_outline),
                onPressed: () {
//                Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => SettingsView()));
                },
              )
            ]),
        body: LayoutBuilder(builder:
            (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
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
                          overflow: Overflow.visible))
//                      child: Stack(children: _classes))
                ])
              ]));
        }));
  }
}
