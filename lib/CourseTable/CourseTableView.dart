import 'package:flutter/material.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  double _mWeekHeight = 40;
  double _mWeekhWidth;
  double _mClassTitleWidth = 20;

  List<String> _WEEK = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
  int _mShowWeek = 7;
  int _mShowClass = 13;

  void _initDefaultSize() {}

  @override
  Widget build(BuildContext context) {
    List<Widget> _weekTitle = new List.generate(
        _mShowWeek,
        (int i) => new Expanded(
              child: Container(
                color: Colors.deepPurpleAccent,
//        margin: EdgeInsets.all(10.0),
                height: _mClassTitleWidth,
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
//          margin: EdgeInsets.all(10.0),
          height: _mWeekHeight,
          width: _mClassTitleWidth,
          child: Text((i + 1).toString())),
    );

    List<Widget> _classes = new List();
    _classes.add(new Container(
        color: Colors.deepPurpleAccent,
        padding: const EdgeInsets.only(left: 60, top: 20),
//          margin: EdgeInsets.all(10.0),
        height: _mWeekHeight,
        width: 80,
        child: Text('QAQ')));

    _classes.add(new Container(
        color: Colors.deepPurpleAccent,
        padding: const EdgeInsets.only(left: 200, top: 0),
//          margin: EdgeInsets.all(10.0),
        height: 0,
        width: 80,
        child: Text('QAQ')));

//    List<Widget> _day(int i) {
//      List<Widget> rst = new List.generate(
//          _mShowClass,
//              (int i) =>
//          new Container(
//              padding: EdgeInsets.all(10.0),
//              height: 48,
//              child: Text((i + 1).toString())));
//      rst.insert(
//          0,
//          Container(
//            color: Colors.deepPurpleAccent,
////              margin: EdgeInsets.all(10.0),
//            height: 20,
//            child: Text(_WEEK[i]), padding: EdgeInsets.all(10.0),));
//      return rst;
//    }
//
//    List<Widget> _week = new List.generate(_mShowWeek, (int i) =>
//    new Expanded(
//        child: Column(
//          children: _day(i),
//        ),
//        flex: 2);
//    );

    return Scaffold(
        appBar: AppBar(
          title: Text('hello world'),
        ),
        body: SingleChildScrollView(
            child: Column(children: <Widget>[
          Row(children: _weekTitle),
          Row(children: [
            Column(children: _classTitle),
            Container(
//                width: 8000,
                alignment: new FractionalOffset(1.0, 0.0),
                padding: const EdgeInsets.only(left: 0, top: 0),
                child: Stack(
//                    alignment: new FractionalOffset(1.0, 0.0),
                    children: _classes
//                    children: <Widget>[
//                      Positioned.fill(
//                        child: Container(color: Colors.grey, child: Text('foo')),
//                      )
//                    ]
//                children: <Widget>[
//                  Positioned(
//                    left:0,
//                    top: 0,
//                    child: _classes[0]
//                  )
//                ],
                    ))
          ])
        ]))
    );
  }
}
