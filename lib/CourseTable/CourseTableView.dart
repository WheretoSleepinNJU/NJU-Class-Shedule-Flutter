import 'package:flutter/material.dart';

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
    {'weekday': 3, 'start': 5, 'step': 2, 'name': 'QAQ'},
    {'weekday': 4, 'start': 2, 'step': 3, 'name': 'QWQ'},
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

    var qwq = classes[0]['start'];

    List<Widget> _classes = new List.generate(
        classes.length,
        (int i) => new Container(
            color: Colors.deepPurpleAccent,
            margin: EdgeInsets.only(
                top: (classes[i]['start'] as int) * _mClassTitleHeight,
                left: (classes[i]['weekday'] as int) * _mWeekTitleWidth),
            height: (classes[i]['step'] as int) * _mClassTitleHeight,
            width: _mWeekTitleWidth,
            child: Text(classes[i]['name'])
        ));
    _classes.insert(
        0,
        Positioned.fill(
          child: Container(color: Colors.grey),
        ));

//    _classes.add(new Container(
//        color: Colors.deepPurpleAccent,
//        margin: EdgeInsets.only(
//            top: 5 * _mClassTitleHeight, left: 3 * _mWeekTitleWidth),
//        height: _mClassTitleHeight,
//        width: _mWeekTitleWidth,
//        child: Text(' qwqwqwqw')));

    return Scaffold(
        appBar: AppBar(
          title: Text('hello world'),
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
