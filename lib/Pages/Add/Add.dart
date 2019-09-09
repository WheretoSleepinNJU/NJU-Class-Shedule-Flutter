import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Resources/Constant.dart';
import '../../Resources/Config.dart';
import '../../Resources/Strings.dart';
import '../../Models/CourseModel.dart';
import '../../Utils/States/MainState.dart';

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

//  TextEditingController _classroomController = new TextEditingController();
  final FocusNode nameTextFieldNode = FocusNode();
  final FocusNode teacherTextFieldNode = FocusNode();
  final FocusNode classroomTextFieldNode = FocusNode();
  bool _classNameIsValid = true;

  Map _node = {
    'weekTime': 0,
    'startTime': 0,
    'endTime': 0,
    'classroom': '',
    'startWeek': 0,
    'endWeek': Config.MAX_WEEKS - 1,
    'weekType': Constant.FULL_WEEKS
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Builder(builder: (BuildContext context) {
          return Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              child: Column(children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(5),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      icon: Icon(Icons.book,
                          color: Theme.of(context).primaryColor),
                      hintText: '课程名称',
                      errorText: _classNameIsValid ? null : '请输入课程名称'),
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(teacherTextFieldNode),
                ),
                Padding(
                  padding: EdgeInsets.all(5),
                ),
                TextField(
                  controller: _teacherController,
                  decoration: InputDecoration(
                    icon: Icon(Icons.account_circle,
                        color: Theme.of(context).primaryColor),
                    hintText: '上课老师',
                  ),
                  onEditingComplete: () => FocusScope.of(context)
                      .requestFocus(classroomTextFieldNode),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                ),
                Row(children: <Widget>[
                  Icon(
                    Icons.code,
                    color: Theme.of(context).primaryColor,
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  InkWell(
                      child: Text(
                        Constant.WEEK_WITHOUT_BIAS[_node['weekTime']] +
                            ' 第' +
                            (_node['startTime'] + 1).toString() +
                            '-' +
                            (_node['endTime'] + 1).toString() +
                            '节' +
                            ' ' +
                            (_node['classroom']) +
                            ' ' +
                            Constant.WEEK_TYPES[_node['weekType']],
                        style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor),
                      ),
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
//                                    controller: _classroomController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.only(top: 10.0),
                                          icon: Icon(Icons.code,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          hintText: '上课地点',
                                        ),
                                        onChanged: (String text) {
                                          _node['classroom'] = text;
                                        },
                                      ),
                                      Padding(padding: EdgeInsets.all(8.0)),
                                      Container(
                                        height: 32,
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
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (int index) {
                                                      setState(() {
                                                        _node['weekTime'] =
                                                            index;
                                                      });
                                                    },
                                                    children: new List<
                                                            Widget>.generate(
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
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (int index) {
                                                      setState(() {
                                                        _node['startTime'] =
                                                            index;
                                                      });
                                                    },
                                                    children: new List<
                                                            Widget>.generate(
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
                                                      backgroundColor:
                                                          Colors.white,
                                                      onSelectedItemChanged:
                                                          (int index) {
                                                        setState(() {
                                                          _node['endTime'] =
                                                              index;
                                                        });
                                                      },
                                                      children: new List<
                                                              Widget>.generate(
                                                          Config.MAX_CLASSES,
//                                                              - _node['startTime'],
                                                          (int index) {
                                                        return new Center(
                                                          child: new Text(
                                                            '第' +
//                                                            '${index + _node['startTime'] + 1}' +
                                                                '${index + 1}' +
                                                                '节',
                                                            style: TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                        );
                                                      })))
                                            ]),
                                      ),
                                      Padding(padding: EdgeInsets.all(8.0)),
                                      Container(
                                        height: 32,
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
                                                          _node['weekType'],
                                                    ),
                                                    itemExtent: 32.0,
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (int index) {
                                                      setState(() {
                                                        _node['weekType'] =
                                                            index;
                                                      });
                                                    },
                                                    children: new List<
                                                            Widget>.generate(
                                                        Constant
                                                            .WEEK_TYPES.length,
                                                        (int index) {
                                                      return new Center(
                                                        child: new Text(
                                                          Constant.WEEK_TYPES[
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
                                                          _node['startWeek'],
                                                    ),
                                                    itemExtent: 32.0,
                                                    backgroundColor:
                                                        Colors.white,
                                                    onSelectedItemChanged:
                                                        (int index) {
                                                      setState(() {
                                                        _node['startWeek'] =
                                                            index;
                                                      });
                                                    },
                                                    children: new List<
                                                            Widget>.generate(
                                                        Config.MAX_WEEKS,
                                                        (int index) {
                                                      return new Center(
                                                        child: new Text(
                                                          '第' +
                                                              '${index + 1}' +
                                                              '周',
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
                                                            _node['endWeek'],
                                                      ),
                                                      itemExtent: 32.0,
                                                      backgroundColor:
                                                          Colors.white,
                                                      onSelectedItemChanged:
                                                          (int index) {
                                                        setState(() {
                                                          _node['endWeek'] =
                                                              index;
                                                        });
                                                      },
                                                      children: new List<
                                                              Widget>.generate(
                                                          Config.MAX_WEEKS,
//                                                          - _node['startTime'],
                                                          (int index) {
                                                        return new Center(
                                                          child: new Text(
                                                            '第' +
//                                                                '${index + _node['startTime'] + 1}' +
                                                                '${index + 1}' +
                                                                '周',
                                                            style: TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                        );
                                                      })))
                                            ]),
                                      ),
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
                Padding(
                  padding: EdgeInsets.all(10),
                ),
                Container(
                    width: double.infinity,
                    child: FlatButton(
                        color: Theme.of(context).primaryColor,
                        child: Text('导入'),
                        textColor: Colors.white,
                        onPressed: () async {
                          if (_nameController.text == '') {
                            setState(() {
                              _classNameIsValid = false;
                            });
                            return;
                          }
                          if (_node['startTime'] > _node['endTime']) {
                            showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('课程节数不合法'),
                                    content: Text('课程结束节数应大于起始节数'),
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
                            return;
                          }
                          if (_node['startWeek'] > _node['endWeek']) {
                            showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('课程周数不合法'),
                                    content: Text('课程结束周数应大于起始周数'),
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
                            return;
                          }
                          int tableId =
                              await MainStateModel.of(context).getClassTable();
                          Course course;
                          course = new Course(
                              tableId,
                              _nameController.text,
                              _generateWeekSeries(_node['startWeek'] + 1,
                                  _node['endWeek'] + 1, _node['weekType']),
                              _node['weekTime'] + 1,
                              _node['startTime'] + 1,
                              _node['endTime'] - _node['startTime'],
                              Constant.ADD_MANUALLY,
//                            classroom: _classroomController.text);
                              classroom: _node['classroom'] == ''
                                  ? null
                                  : _node['classroom'],
                              teacher: _teacherController.text == ''
                                  ? null
                                  : _teacherController.text);
//                      if (_classroomController.text == '') {
//                        course = new Course(
//                            tableId,
//                            _nameController.text,
//                            '[1, 2, 3]',
//                            _node['weekTime'] + 1,
//                            _node['startTime'] + 1,
//                            _node['endTime'] - _node['startTime'],
//                            Constant.ADD_MANUALLY);
//                      } else {
//                        course = new Course(
//                            tableId,
//                            _nameController.text,
//                            '[1, 2, 3]',
//                            _node['weekTime'] + 1,
//                            _node['startTime'] + 1,
//                            _node['endTime'] - _node['startTIme'],
//                            Constant.ADD_MANUALLY,
////                            classroom: _classroomController.text);
//                            classroom: _node['classroom']);
//                      }
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
              ]));
        }));
  }

  String _generateWeekSeries(int start, int end, int weekType) {
    if (weekType == Constant.FULL_WEEKS)
      return _getWeekSeries(start, end);
    else if (weekType == Constant.SINGLE_WEEKS)
      return _getSingleWeekSeries(start, end);
    else if (weekType == Constant.DOUBLE_WEEKS)
      return _getDoubleWeekSeries(start, end);
    else
      return '';
  }

  String _getWeekSeries(int start, int end) {
    List<int> list = [for (int i = start; i <= end; i += 1) i];
//    print (list.toString());
    return list.toString();
  }

  String _getSingleWeekSeries(int start, int end) {
    if (start % 2 == 0) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }

  String _getDoubleWeekSeries(int start, int end) {
    if (start % 2 == 1) start++;
    List<int> list = [for (int i = start; i <= end; i += 2) i];
//    print (list.toString());
    return list.toString();
  }
}
