import 'package:flutter/material.dart';
import '../Settings/SettingsView.dart';
import '../Resources/Strings.dart';
import '../Resources/Color.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  List<String> _WEEK = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
  int _mShowWeek = 7;
  int _mShowClass = 13;

  void _initDefaultSize() {}

  var classes = [
    {'weekday': 3, 'start': 5, 'step': 2, 'name': 'QAQ', 'color': '#8AD297'},
    {'weekday': 4, 'start': 2, 'step': 3, 'name': 'QWQ', 'color': '#F9A883'},
  ];

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
                color: Colors.deepPurpleAccent,
                height: _mWeekTitleHeight,
                child: Text(_WEEK[i]),
                padding: EdgeInsets.all(10.0),
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
          color: Colors.deepPurpleAccent,
          margin: EdgeInsets.only(top: i * _mClassTitleHeight),
          height: _mClassTitleHeight,
          width: _mClassTitleWidth,
          child: Text((i + 1).toString())),
    );

    /* FIXME: Draw Dashed Line: Padding Due to Flutter */
//    List<Widget> _classes = new List.generate(
//      _mShowClass,
//          (int i) => new Container(
//          margin: EdgeInsets.only(top: (i + 1) * _mClassTitleHeight),
//          width: _mWeekTitleWidth * _mShowWeek,
//          height: 1.5,
//          color: Colors.black,
//    ));

    /**
     * Draw Classes
     */
    List<Widget> _classes = new List.generate(
        classes.length,
        (int i) => new Container(
            color: HexColor(classes[i]['color']),
            margin: EdgeInsets.only(
                top: (classes[i]['start'] as int) * _mClassTitleHeight,
                left: (classes[i]['weekday'] as int) * _mWeekTitleWidth),
            height: (classes[i]['step'] as int) * _mClassTitleHeight,
            width: _mWeekTitleWidth,
            child: Text(classes[i]['name'])
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
            GestureDetector(
              child: Text(
                  Strings.subtitle_pre + Strings.subtitle_suf,
                  style: TextStyle(fontSize: 16)
              ),
              onTap: () {
//                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => SettingsView()));
//                print("tapped subtitle");
              },
            )
          ]),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: (){
//                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => SettingsView()));
              },
            )
          ]
        ),
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
                      height: _mClassTitleHeight * 13,
                      width: _mClassTitleWidth,
                      child: Stack(children: _classTitle)),
                  Container(
                      height: _mClassTitleHeight * 13,
                      width: _mScreenWidth - _mClassTitleWidth,
                      child: Stack(children: _classes))
                ])
              ]));
        }));
  }
}
