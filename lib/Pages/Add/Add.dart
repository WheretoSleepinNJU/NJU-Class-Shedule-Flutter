import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import '../../Resources/Constant.dart';
import '../../Resources/Config.dart';
import '../../Resources/Strings.dart';
import '../../Models/CourseModel.dart';
import '../../Utils/States/MainState.dart';
import 'package:numberpicker/numberpicker.dart';

//import 'ImportPresenter.dart';
import 'dart:convert';
import 'dart:math';

//class Dialog extends StatefulWidget{
//  @override
//  _DialogState createState() => new _DialogState();
//}
//
//class _DialogState extends State<Dialog> {
//  @override
//  void initState() {
//    super.initState();
//    WidgetsBinding.instance.addPostFrameCallback((_){_showDialog();});
//  }
//
//  _showDialog() async {
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return new Container();
//  }
//}

class AddView extends StatefulWidget {
  AddView() : super();
  final String title = '添加课程';

  @override
  _AddViewState createState() => _AddViewState();
}

class _AddViewState extends State<AddView> {
//  AddPresenter _presenter = new AddPresenter();

  TextEditingController _nameController = new TextEditingController();
  TextEditingController _teacherController = new TextEditingController();
  TextEditingController _classroomController = new TextEditingController();
  final FocusNode nameTextFieldNode = FocusNode();
  final FocusNode teacherTextFieldNode = FocusNode();
  final FocusNode classroomTextFieldNode = FocusNode();

  Map _node = {'weekTime': 0, 'startTime': 0, 'endTime': 0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Column(children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.account_circle,
                    color: Theme.of(context).primaryColor),
                hintText: '课程名称',
              ),
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(teacherTextFieldNode),
            ),
            TextField(
              controller: _teacherController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                hintText: '上课老师',
              ),
              obscureText: true,
              onEditingComplete: () =>
                  FocusScope.of(context).requestFocus(classroomTextFieldNode),
            ),
            Row(children: <Widget>[
              Icon(
                Icons.ac_unit,
                color: Theme.of(context).primaryColor,
              ),
              InkWell(
                  child: Text(Constant.WEEK_WITHOUT_BIAS[_node['weekTime']] +
                      ' 第' +
                      (_node['startTime'] + 1).toString() +
                      '-' +
                      (_node['endTime'] + 1).toString() +
                      '节'),
                  onTap: () {
                    showDialog<String>(
                        context: context,
//                        barrierDismissible: false,
                        // dialog is dismissible with a tap on the barrier
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("选择上课时间"),
                            content: Container(
                              child: new Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: _classroomController,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.only(top: 10.0),
                                      icon: Icon(Icons.code,
                                          color:
                                              Theme.of(context).primaryColor),
                                      hintText: '上课地点',
                                    ),
                                  ),
                                  Padding(padding: EdgeInsets.all(8.0)),
                                  Container(
                                    height: 50,
                                    child: Flex(
                                        mainAxisSize: MainAxisSize.min,
                                        direction: Axis.horizontal,
                                        children: <Widget>[
                                          Flexible(
                                            flex: 2,
                                            child: CupertinoPicker(
                                                scrollController:
                                                    new FixedExtentScrollController(
                                                  initialItem:
                                                      _node['weekTime'],
                                                ),
                                                itemExtent: 32.0,
                                                backgroundColor: Colors.white,
                                                onSelectedItemChanged:
                                                    (int index) {
                                                  setState(() {
                                                    _node['weekTime'] = index;
                                                  });
                                                },
                                                children:
                                                    new List<Widget>.generate(
                                                        Constant
                                                            .WEEK_WITHOUT_BIAS
                                                            .length,
                                                        (int index) {
                                                  return new Center(
                                                    child: new Text(
                                                      Constant.WEEK_WITHOUT_BIAS[
                                                          index],
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  );
                                                })),
                                          ),
                                          Flexible(
                                            flex: 1,
                                            child: Container(),
                                          ),
                                          Flexible(
                                            flex: 2,
                                            child: CupertinoPicker(
                                                scrollController:
                                                    new FixedExtentScrollController(
                                                  initialItem:
                                                      _node['startTime'],
                                                ),
                                                itemExtent: 32.0,
                                                backgroundColor: Colors.white,
                                                onSelectedItemChanged:
                                                    (int index) {
                                                  setState(() {
                                                    _node['startTime'] = index;
                                                  });
                                                },
                                                children:
                                                    new List<Widget>.generate(
                                                        Config.MAX_CLASSES,
                                                        (int index) {
                                                  return new Center(
                                                    child: new Text(
                                                      '第' +
                                                          '${index + 1}' +
                                                          '节',
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  );
                                                })),
                                          ),
                                          Flexible(
                                            flex: 1,
                                            child: Center(child: Text('-')),
                                          ),
                                          Flexible(
                                              flex: 2,
                                              child: CupertinoPicker(
                                                  scrollController:
                                                      new FixedExtentScrollController(
                                                    initialItem:
                                                        _node['endTime'],
                                                  ),
                                                  itemExtent: 32.0,
                                                  backgroundColor: Colors.white,
                                                  onSelectedItemChanged:
                                                      (int index) {
                                                    setState(() {
                                                      _node['endTime'] = index;
                                                    });
                                                  },
                                                  children:
                                                      new List<Widget>.generate(
                                                          Config.MAX_CLASSES -
                                                              _node[
                                                                  'startTime'],
                                                          (int index) {
                                                    return new Center(
                                                      child: new Text(
                                                        '第' +
                                                            '${index + _node['startTime'] + 1}' +
                                                            '节',
                                                        style: TextStyle(
                                                            fontSize: 16),
                                                      ),
                                                    );
                                                  })))
                                        ]),
                                  ),
//                                  Row(
//                                    mainAxisSize: MainAxisSize.min,
////                                    crossAxisAlignment: CrossAxisAlignment.start,
//                                    children: <Widget>[
//                                      new Container(
//                                        height: 40,
//                                        width: 40,
//                                        child: CupertinoPicker(
//                                            scrollController:
//                                                new FixedExtentScrollController(
//                                              initialItem: _node['weekTime'],
//                                            ),
//                                            itemExtent: 32.0,
//                                            backgroundColor: Colors.white,
//                                            onSelectedItemChanged: (int index) {
//                                              setState(() {
//                                                _node['weekTime'] = index;
//                                              });
//                                            },
//                                            children: new List<Widget>.generate(
//                                                Constant.WEEK_WITHOUT_BIAS
//                                                    .length, (int index) {
//                                              return
//                                            new Center(
//                                            child:
//                                                  new Text(
//                                                Constant
//                                                    .WEEK_WITHOUT_BIAS[index],
//                                                style: TextStyle(fontSize: 16),
//                                            ),
//                                              );
//                                            })),
//                                      ),
//                                      Text(' 第'),
//                                      new Container(
//                                        height: 40,
//                                        width: 40,
//                                        child: CupertinoPicker(
//                                            scrollController:
//                                                new FixedExtentScrollController(
//                                              initialItem: _node['startTime'],
//                                            ),
//                                            itemExtent: 32.0,
//                                            backgroundColor: Colors.white,
//                                            onSelectedItemChanged: (int index) {
//                                              setState(() {
//                                                _node['startTime'] = index;
//                                              });
//                                            },
//                                            children: new List<Widget>.generate(
//                                                Config.MAX_CLASSES,
//                                                (int index) {
//                                              return new Center(
//                                                child: new Text(
//                                                  '${index + 1}',
//                                                  style:
//                                                      TextStyle(fontSize: 16),
//                                                ),
//                                              );
//                                            })),
//                                      ),
//                                      Text('节 - 第'),
//                                      new Container(
//                                        height: 40,
//                                        width: 40,
//                                        child: CupertinoPicker(
//                                            scrollController:
//                                                new FixedExtentScrollController(
//                                              initialItem: _node['endTime'],
//                                            ),
//                                            itemExtent: 32.0,
//                                            backgroundColor: Colors.white,
//                                            onSelectedItemChanged: (int index) {
//                                              setState(() {
//                                                _node['endTime'] = index;
//                                              });
//                                            },
//                                            children: new List<Widget>.generate(
//                                                Config.MAX_CLASSES -
//                                                    _node['startTime'],
//                                                (int index) {
////                                              print('QAQ');
//                                              return new Center(
//                                                child: new Text(
//                                                  '${index + _node['startTime'] + 1}',
//                                                  style:
//                                                      TextStyle(fontSize: 16),
//                                                ),
//                                              );
//                                            })
////                                        children: new List<Widget>.generate(
////                                            Config.MAX_CLASSES, (int index) {
////                                          return new Center(
////                                            child: new Text(
////                                              '${index + 1}',
////                                              style: TextStyle(fontSize: 16),
////                                            ),
////                                          );
////                                        })
//                                            ),
//                                      ),
//                                      Text('节'),
//                                    ],
//                                  )
                                ],
                              ),
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
                        });
                  })
            ]),
//            Container(
//              width: double.infinity,
//              margin: EdgeInsets.all(10),
//              child: FlatButton(
//                  color: Theme.of(context).primaryColor,
//                  child: Text('导入'),
//                  textColor: Colors.white,
//                  onPressed: () {
//                    showDialog<String>(
//                        context: context,
//                        barrierDismissible: false,
//                        // dialog is dismissible with a tap on the barrier
//                        builder: (BuildContext context) {
//                          return AlertDialog(
//                            title: Text("选择上课时间"),
//                            content: new Container(
//                              height: 60,
//                              child: new Row(
//                                children: <Widget>[
//                                  new Expanded(
//                                    child: CupertinoPicker(
//                                        scrollController:
//                                            new FixedExtentScrollController(
//                                          initialItem: _node['weekTime'],
//                                        ),
//                                        itemExtent: 32.0,
//                                        backgroundColor: Colors.white,
//                                        onSelectedItemChanged: (int index) {
//                                          setState(() {
//                                            _node['weekTime'] = index;
//                                          });
//                                        },
//                                        children: new List<Widget>.generate(
//                                            Constant.WEEK_WITHOUT_BIAS.length,
//                                            (int index) {
//                                          return new Center(
//                                            child: new Text(
//                                              Constant.WEEK_WITHOUT_BIAS[index],
//                                              style: TextStyle(fontSize: 16),
//                                            ),
//                                          );
//                                        })),
//                                  ),
//                                  Text(' 第'),
//                                  new Expanded(
//                                    child: CupertinoPicker(
//                                        scrollController:
//                                            new FixedExtentScrollController(
//                                          initialItem: _node['startTime'],
//                                        ),
//                                        itemExtent: 32.0,
//                                        backgroundColor: Colors.white,
//                                        onSelectedItemChanged: (int index) {
//                                          setState(() {
//                                            _node['startTime'] = index;
//                                          });
//                                        },
//                                        children: new List<Widget>.generate(
//                                            Config.MAX_CLASSES, (int index) {
//                                          return new Center(
//                                            child: new Text(
//                                              '${index + 1}',
//                                              style: TextStyle(fontSize: 16),
//                                            ),
//                                          );
//                                        })),
//                                  ),
//                                  Text('节 - 第'),
//                                  new Expanded(
//                                    child: CupertinoPicker(
//                                        scrollController:
//                                            new FixedExtentScrollController(
//                                          initialItem: _node['endTime'],
//                                        ),
//                                        itemExtent: 32.0,
//                                        backgroundColor: Colors.white,
//                                        onSelectedItemChanged: (int index) {
//                                          setState(() {
//                                            _node['endTime'] = index;
//                                          });
//                                        },
//                                        children: new List<Widget>.generate(
//                                            Config.MAX_CLASSES, (int index) {
//                                          return new Center(
//                                            child: new Text(
//                                              '${index + 1}',
//                                              style: TextStyle(fontSize: 16),
//                                            ),
//                                          );
//                                        })),
//                                  ),
//                                  Text('节'),
//                                ],
//                              ),
//                            ),
//                            actions: <Widget>[
//                              FlatButton(
//                                child: Text(Strings.ok),
//                                onPressed: () {
//                                  Navigator.of(context).pop();
//                                },
//                              ),
//                            ],
//                          );
//                        });
//                  }),
//            ),
            Container(
                width: double.infinity,
                margin: EdgeInsets.all(10),
                child: FlatButton(
                    color: Theme.of(context).primaryColor,
                    child: Text('导入'),
                    textColor: Colors.white,
                    onPressed: () async {
                      int tableId =
                          await MainStateModel.of(context).getClassTable();
                      Course course;
                      if (_classroomController.text == '') {
                        course = new Course(
                            tableId,
                            _nameController.text,
                            '[1, 2, 3]',
                            _node['weekTime'] + 1,
                            _node['startTime'] + 1,
                            _node['endTime'] - _node['startTime'],
                            Constant.ADD_MANUALLY);
                      } else {
                        course = new Course(
                            tableId,
                            _nameController.text,
                            '[1, 2, 3]',
                            _node['weekTime'] + 1,
                            _node['startTime'] + 1,
                            _node['endTime'] - _node['startTIme'],
                            Constant.ADD_MANUALLY,
                            classroom: _classroomController.text);
                      }
                      CourseProvider courseProvider = new CourseProvider();
                      course = await courseProvider.insert(course);
                      if (course.id != null)
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('添加成功！>v<'),
                          backgroundColor: Theme.of(context).primaryColor,
                        ));
                      print(course.toMap());
                      Navigator.of(context).pop();
                    }))
          ]);
        }));
  }
}
