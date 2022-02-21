import '../../../generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/Config.dart';
import '../../../Components/Dialog.dart';

class WeekTimeNodeDialog extends StatefulWidget {
  final Map node;

  static const Map map = {'weekTime': 0, 'startTime': 0, 'endTime': 0};

  const WeekTimeNodeDialog({this.node = map, Key? key}) : super(key: key);

  @override
  _WeekTimeNodeDialogState createState() => _WeekTimeNodeDialogState();
}

class _WeekTimeNodeDialogState extends State<WeekTimeNodeDialog> {
  @override
  Widget build(BuildContext context) {
    Map _node = widget.node;
    // if ((_node['endTime'] ?? 0) < (_node['startTime'] ?? 0)) {
    //   _node['endTime'] = _node['startTime'];
    //   setState(() {
    //     _node = _node;
    //   });
    // }
    FixedExtentScrollController _startController = FixedExtentScrollController(
      initialItem: _node['startTime'],
    );
    FixedExtentScrollController _endController = FixedExtentScrollController(
      initialItem: _node['endTime'],
    );
    return MDialog(
      S.of(context).choose_class_time_dialog_title,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 96,
            child: Flex(
                // mainAxisSize: MainAxisSize.min,
                direction: Axis.horizontal,
                children: <Widget>[
                  Flexible(
                    flex: 5,
                    child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _node['weekTime'],
                        ),
                        itemExtent: 32.0,
                        // backgroundColor: Colors.white,
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
                  // Flexible(
                  //   flex: 1,
                  //   child: Container(),
                  // ),
                  Flexible(
                    flex: 5,
                    child: CupertinoPicker(
                        scrollController: _startController,
                        itemExtent: 32.0,

                        // backgroundColor: Colors.white,
                        onSelectedItemChanged: (int index) {
                          if (_endController.selectedItem < index) {
                            _node['endTime'] = index;
                            _endController.jumpToItem(_node['endTime']);
                          }
                          setState(() {
                            _node['startTime'] = index;
                          });
                        },
                        children: List<Widget>.generate(Config.MAX_CLASSES,
                            (int index) {
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
                      flex: 5,
                      child: CupertinoPicker(
                          scrollController: _endController,
                          itemExtent: 32.0,
                          // backgroundColor: Colors.white,
                          onSelectedItemChanged: (int index) {
                            if (index < _startController.selectedItem) {
                              _node['startTime'] = index;
                              _startController.jumpToItem(_node['startTime']);
                            }
                            setState(() {
                              _node['endTime'] = index;
                            });
                          },
                          children: List<Widget>.generate(Config.MAX_CLASSES,
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
        ],
      ),
      widgetOK: Text(S.of(context).ok),
      widgetOKAction: () {
        Navigator.of(context).pop(_node);
      },
    );
  }
}
