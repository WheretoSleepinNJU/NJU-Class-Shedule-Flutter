import '../../../generated/i18n.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Utils/WeekUtil.dart';

class WeekTitle extends StatelessWidget {
  final int _maxShowDays;
  final double _weekTitleHeight;
  final double _classTitleWidth;
  final bool _isShowMonth;
  final bool _isShowDate;
  final bool _isWhiteMode;

  WeekTitle(this._maxShowDays, this._weekTitleHeight, this._classTitleWidth,
      this._isShowMonth, this._isShowDate, this._isWhiteMode);

  @override
  Widget build(BuildContext context) {
    List<String> _dayList = WeekUtil.getDayList();
    List<Widget> _weekTitle = new List.generate(
        _maxShowDays,
        (int i) => new Expanded(
              child: Container(
                height: _isShowDate ? _weekTitleHeight * 1.2 : _weekTitleHeight,
//                height: 40,
                child: Center(
                  child: _isShowDate
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                              Text(
                                Constant.WEEK_WITHOUT_BIAS[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isWhiteMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                              Text(
                                _dayList[i],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _isWhiteMode
                                        ? Colors.white
                                        : Colors.black),
                              )
                            ])
                      : Center(
                          child: Text(
                            Constant.WEEK_WITHOUT_BIAS_WITHOUT_PRE[i],
                            style: TextStyle(
                                color:
                                    _isWhiteMode ? Colors.white : Colors.black),
                          ),
                        ),
                ),
                padding: EdgeInsets.all(0.0),
              ),
            ));

    _weekTitle.insert(
        0,
        Container(
          width: _classTitleWidth,
          child: _isShowMonth
              ? (_isShowDate
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              WeekUtil.getNowMonth().toString() +
                                  S.of(context).month,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isWhiteMode
                                      ? Colors.white
                                      : Colors.black),
                            ),
                            Text(
                              WeekUtil.getNowMonthName() + '.',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _isWhiteMode
                                      ? Colors.white
                                      : Colors.black),
                            )
                          ]),
                    )
                  : Center(
                      child: Text(
                        WeekUtil.getNowMonth().toString() + S.of(context).month,
                        style: TextStyle(
                            color: _isWhiteMode ? Colors.white : Colors.black),
                      ),
                    ))
              : Container(width: _classTitleWidth),
        )

//        Container(width: _classTitleWidth)
//        Container(
//            width: _classTitleWidth,
//            child: Center(
//                child: Text(WeekUtil.getNowMonth().toString() + '月')))
        );
    return Container(child: Row(children: _weekTitle));
  }
}
