import '../../../generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/Config.dart';
import '../../../Components/Dialog.dart';

class NodeDialog extends StatefulWidget {
  final Map node ;
  static const Map map = {
    'weekTime': 0,
    'startTime': 0,
    'endTime': 0,
    'classroom': '',
    'startWeek': 0,
    'endWeek': Config.MAX_WEEKS - 1,
    'weekType': Constant.FULL_WEEKS
  };
  const NodeDialog({this.node = map, Key? key}) : super(key: key);

  @override
  _NodeDialogState createState() => _NodeDialogState();
}

class _NodeDialogState extends State<NodeDialog> {

  @override
  Widget build(BuildContext context) {
    Map _node = widget.node;
    TextEditingController _classroomController = TextEditingController();
    _classroomController.text = _node['classroom'];
    return MDialog(
      S.of(context).choose_class_time_dialog_title,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              // contentPadding: const EdgeInsets.only(top: 10.0),
              icon: Icon(Icons.code, color: Theme.of(context).primaryColor),
              hintText: S.of(context).class_room,
            ),
            controller: _classroomController,
            onChanged: (String text) {
              _node['classroom'] = text;
            },
          ),
          const Padding(padding: EdgeInsets.only(bottom: 30)),
          SizedBox(
            height: 32,
            child: Flex(
                mainAxisSize: MainAxisSize.min,
                direction: Axis.horizontal,
                children: <Widget>[
                  Flexible(
                    flex: 2,
                    child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _node['weekTime'],
                        ),
                        itemExtent: 32.0,
                        backgroundColor: Colors.white,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _node['weekTime'] = index;
                          });
                        },
                        children: List<Widget>.generate(
                            Constant.WEEK_WITHOUT_BIAS.length, (int index) {
                          return Center(
                            child: Text(
                              Constant.WEEK_WITHOUT_BIAS[index],
                              style: const TextStyle(fontSize: 16),
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
                        scrollController: FixedExtentScrollController(
                          initialItem: _node['startTime'],
                        ),
                        itemExtent: 32.0,
                        backgroundColor: Colors.white,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _node['startTime'] = index;
                          });
                        },
                        children: List<Widget>.generate(
                            Config.MAX_CLASSES, (int index) {
                          return Center(
                            child: Text(
                              S
                                  .of(context)
                                  .class_single((index + 1).toString()),
                              style: const TextStyle(fontSize: 13),
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
                          scrollController: FixedExtentScrollController(
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
                              List<Widget>.generate(Config.MAX_CLASSES,
//                              - _node['startTime'],
                                  (int index) {
                            return Center(
                              child: Text(
                                S
                                    .of(context)
                                    .class_single((index + 1).toString()),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          })))
                ]),
          ),
          const Padding(padding: EdgeInsets.all(8.0)),
          SizedBox(
            height: 32,
            child: Flex(
                mainAxisSize: MainAxisSize.min,
                direction: Axis.horizontal,
                children: <Widget>[
                  Flexible(
                    flex: 2,
                    child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _node['weekType'],
                        ),
                        itemExtent: 32.0,
                        backgroundColor: Colors.white,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _node['weekType'] = index;
                          });
                        },
                        children: List<Widget>.generate(
                            Constant.WEEK_TYPES.length, (int index) {
                          return Center(
                            child: Text(
                              Constant.WEEK_TYPES[index],
                              style: const TextStyle(fontSize: 16),
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
                        scrollController: FixedExtentScrollController(
                          initialItem: _node['startWeek'],
                        ),
                        itemExtent: 32.0,
                        backgroundColor: Colors.white,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _node['startWeek'] = index;
                          });
                        },
                        children: List<Widget>.generate(Config.MAX_WEEKS,
                            (int index) {
                          return Center(
                            child: Text(
                              S.of(context).week((index + 1).toString()),
                              style: const TextStyle(fontSize: 13),
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
                          scrollController: FixedExtentScrollController(
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
                              List<Widget>.generate(Config.MAX_WEEKS,
//                                                          - _node['startTime'],
                                  (int index) {
                            return Center(
                              child: Text(
                                S.of(context).week((index + 1).toString()),
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          })))
                ]),
          ),
        ],
      ),
      <Widget>[
        FlatButton(
          textColor: Theme.of(context).primaryColor,
          child: Text(S.of(context).ok),
          onPressed: () {
            Navigator.of(context).pop(_node);
          },
        ),
      ],
    );
  }
}
