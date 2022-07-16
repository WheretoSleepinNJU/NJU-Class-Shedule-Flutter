import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';

class ClassTitle extends StatefulWidget {
  final int _maxShowClasses;
  final double _classTitleHeight;
  final double _classTitleWidth;
  final bool _isShowWeekTime;
  final bool? _isWhiteMode;
  final List<Map> classTimeList;

  const ClassTitle(this._maxShowClasses, this._classTitleHeight,
      this._classTitleWidth, this._isShowWeekTime, this._isWhiteMode,
      {Key? key, this.classTimeList = Constant.CLASS_TIME_LIST})
      : super(key: key);

  @override
  _ClassTitleState createState() => _ClassTitleState();
}

class _ClassTitleState extends State<ClassTitle> {
  @override
  void initState() {
    super.initState();
  }

  Color? getColor() {
    if (widget._isWhiteMode == null) {
      return null;
    } else {
      return widget._isWhiteMode! ? Colors.white : Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    // getClassTimeList();
    List<Widget> _classTitle = List.generate(
      widget._maxShowClasses,
      (int i) => SizedBox(
          height: widget._classTitleHeight,
          width: widget._classTitleWidth,
          child: Center(
              child: widget._isShowWeekTime
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text((i + 1).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: getColor())),
                        Text(
                          widget.classTimeList[i]['start'] +
                              '\n' +
                              widget.classTimeList[i]['end'],
                          style: TextStyle(fontSize: 10, color: getColor()),
                        )
                      ],
                    )
                  : Text((i + 1).toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: getColor())))),
    );
    return Column(children: _classTitle);
  }
}
