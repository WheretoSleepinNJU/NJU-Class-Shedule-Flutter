import '../../../generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/Config.dart';
import '../../../Components/Dialog.dart';

class NodeDialog extends StatefulWidget {
  NodeDialog() : super();

  @override
  _NodeDialogState createState() => _NodeDialogState();
}

class _NodeDialogState extends State<NodeDialog> {
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
    return mDialog(
      S.of(context).choose_class_time_dialog_title,
      Container(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(top: 10.0),
                icon: Icon(Icons.code, color: Theme.of(context).primaryColor),
                hintText: S.of(context).class_room,
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
                          scrollController: new FixedExtentScrollController(
                            initialItem: _node['weekTime'],
                          ),
                          itemExtent: 32.0,
                          backgroundColor: Colors.white,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _node['weekTime'] = index;
                            });
                          },
                          children: new List<Widget>.generate(
                              Constant.WEEK_WITHOUT_BIAS.length, (int index) {
                            return new Center(
                              child: new Text(
                                Constant.WEEK_WITHOUT_BIAS[index],
                                style: TextStyle(fontSize: 16),
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
                          scrollController: new FixedExtentScrollController(
                            initialItem: _node['startTime'],
                          ),
                          itemExtent: 32.0,
                          backgroundColor: Colors.white,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _node['startTime'] = index;
                            });
                          },
                          children: new List<Widget>.generate(
                              Config.MAX_CLASSES, (int index) {
                            return new Center(
                              child: new Text(
                                S
                                    .of(context)
                                    .class_single((index + 1).toString()),
                                style: TextStyle(fontSize: 13),
                              ),
                            );
                          })),
                    ),
                    Flexible(
                      flex: 1,
                      child: Center(child: Text(S.of(context).to)),
                    ),
                    Flexible(
                        flex: 2,
                        child: CupertinoPicker(
                            scrollController: new FixedExtentScrollController(
                              initialItem: _node['endTime'],
                            ),
                            itemExtent: 32.0,
                            backgroundColor: Colors.white,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                _node['endTime'] = index;
                              });
                            },
                            children:
                                new List<Widget>.generate(Config.MAX_CLASSES,
//                              - _node['startTime'],
                                    (int index) {
                              return new Center(
                                child: new Text(
                                  S
                                      .of(context)
                                      .class_single((index + 1).toString()),
                                  style: TextStyle(fontSize: 13),
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
                          scrollController: new FixedExtentScrollController(
                            initialItem: _node['weekType'],
                          ),
                          itemExtent: 32.0,
                          backgroundColor: Colors.white,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _node['weekType'] = index;
                            });
                          },
                          children: new List<Widget>.generate(
                              Constant.WEEK_TYPES.length, (int index) {
                            return new Center(
                              child: new Text(
                                Constant.WEEK_TYPES[index],
                                style: TextStyle(fontSize: 16),
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
                          scrollController: new FixedExtentScrollController(
                            initialItem: _node['startWeek'],
                          ),
                          itemExtent: 32.0,
                          backgroundColor: Colors.white,
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              _node['startWeek'] = index;
                            });
                          },
                          children: new List<Widget>.generate(Config.MAX_WEEKS,
                              (int index) {
                            return new Center(
                              child: new Text(
                                S.of(context).week((index + 1).toString()),
                                style: TextStyle(fontSize: 13),
                              ),
                            );
                          })),
                    ),
                    Flexible(
                      flex: 1,
                      child: Center(child: Text(S.of(context).to)),
                    ),
                    Flexible(
                        flex: 2,
                        child: CupertinoPicker(
                            scrollController: new FixedExtentScrollController(
                              initialItem: _node['endWeek'],
                            ),
                            itemExtent: 32.0,
                            backgroundColor: Colors.white,
                            onSelectedItemChanged: (int index) {
                              setState(() {
                                _node['endWeek'] = index;
                              });
                            },
                            children:
                                new List<Widget>.generate(Config.MAX_WEEKS,
//                                                          - _node['startTime'],
                                    (int index) {
                              return new Center(
                                child: new Text(
                                  S.of(context).week((index + 1).toString()),
                                  style: TextStyle(fontSize: 13),
                                ),
                              );
                            })))
                  ]),
            ),
          ],
        ),
      ),
      <Widget>[
        FlatButton(
          child: Text(S.of(context).ok),
          onPressed: () {
            Navigator.of(context).pop(_node);
          },
        ),
      ],
    );
  }
}
