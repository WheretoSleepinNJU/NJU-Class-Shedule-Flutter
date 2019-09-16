import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';

class ClassTitle extends StatelessWidget {
  final int _maxShowClasses;
  final double _classTitleHeight;
  final double _classTitleWidth;
  final bool _isShowWeekTime;

  ClassTitle(this._maxShowClasses, this._classTitleHeight,
      this._classTitleWidth, this._isShowWeekTime);

  @override
  Widget build(BuildContext context) {
    List<Widget> _classTitle = new List.generate(
      _maxShowClasses,
      (int i) => new Container(
          height: _classTitleHeight,
          width: _classTitleWidth,
          child: Center(
              child: _isShowWeekTime
                  ? Column(
                      children: <Widget>[
                        Text((i + 1).toString(), textAlign: TextAlign.center),
                        Text(
                          Constant.CLASS_TIME[i],
                          style: TextStyle(fontSize: 10),
                        )
                      ],
                    )
                  : Text((i + 1).toString(), textAlign: TextAlign.center))),
    );
    return Container(child: Column(children: _classTitle));
  }
}
