import '../../../generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Resources/Config.dart';
import '../../../Components/Dialog.dart';

class WeekNodeDialog extends StatefulWidget {
  final Map node;

  static const Map map = {
    'weeks': [],
    'startWeek': 0,
    'endWeek': Config.MAX_WEEKS - 1,
    'weekType': Constant.FULL_WEEKS
  };

  const WeekNodeDialog({this.node = map, Key? key}) : super(key: key);

  @override
  _WeekNodeDialogState createState() => _WeekNodeDialogState();
}

class _WeekNodeDialogState extends State<WeekNodeDialog> {
  List<int> weeks = [1];

  Widget getChoiceChip(int i) {
    return ChoiceChip(
      selected: weeks.contains(i),
      // backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor,
      shadowColor: Colors.grey,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10))),
      label: Text(
        i.toString(),
        style: TextStyle(
            color: weeks.contains(i)
                ? Colors.white
                : Theme.of(context).primaryColor),
      ),
      onSelected: (val) {
        if (val) {
          weeks.add(i);
        } else {
          weeks.remove(i);
        }
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map _node = widget.node;
    FixedExtentScrollController _startController = FixedExtentScrollController(
      initialItem: _node['startWeek'],
    );
    FixedExtentScrollController _endController = FixedExtentScrollController(
      initialItem: _node['endWeek'],
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
                          initialItem: _node['weekType'],
                        ),
                        itemExtent: 32.0,
                        // backgroundColor: Colors.white,
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
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white),
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
                            _node['endWeek'] = index;
                            _endController.jumpToItem(_node['endWeek']);
                          }
                          setState(() {
                            _node['startWeek'] = index;
                          });
                        },
                        children: List<Widget>.generate(Config.MAX_WEEKS,
                            (int index) {
                          return Center(
                            child: Text(
                              S.of(context).week((index + 1).toString()),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white),
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
                              _node['startWeek'] = index;
                              _startController.jumpToItem(_node['startWeek']);
                            }
                            setState(() {
                              _node['endWeek'] = index;
                            });
                          },
                          children: List<Widget>.generate(Config.MAX_WEEKS,
//                              - _node['startWeek'],
                              (int index) {
                            return Center(
                              child: Text(
                                S.of(context).week((index + 1).toString()),
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.black
                                        : Colors.white),
                              ),
                            );
                          })))
                ]),
          ),
          // ButtonBar(
          //   children: <Widget>[
          //     ElevatedButton(
          //       child: Text('全部'),
          //       onPressed: () {},
          //     ),
          //     ElevatedButton(
          //       child: Text('单周'),
          //       onPressed: () {},
          //     ),
          //     ElevatedButton(
          //       child: Text('双周'),
          //       onPressed: () {},
          //     ),
          //   ],
          // ),
          // Row(
          //   children: [
          //     getChoiceChip(1),
          //     getChoiceChip(2),
          //     getChoiceChip(3),
          //     getChoiceChip(4),
          //     getChoiceChip(5),
          //   ],
          // ),
        ],
      ),
      widgetOK: Text(S.of(context).ok),
      widgetOKAction: () {
        Navigator.of(context).pop(_node);
      },
    );
  }
}
