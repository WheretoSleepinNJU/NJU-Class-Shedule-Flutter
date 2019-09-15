import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';

class WeekTitle extends StatelessWidget {
  final int _maxShowDays;
  final double _weekTitleHeight;
  final double _classTitleWidth;

  WeekTitle(this._maxShowDays, this._weekTitleHeight, this._classTitleWidth);

  @override
  Widget build(BuildContext context) {
    List<Widget> _weekTitle = new List.generate(
        _maxShowDays,
        (int i) => new Expanded(
              child: Container(
                height: _weekTitleHeight,
                child: Center(
                    child: Text(Constant.WEEK_WITHOUT_BIAS_WITHOUT_PRE[i],
                        textAlign: TextAlign.center)),
                padding: EdgeInsets.all(0.0),
              ),
            ));

    _weekTitle.insert(0, Container(width: _classTitleWidth));
    return Container(child: Row(children: _weekTitle));
  }
}
