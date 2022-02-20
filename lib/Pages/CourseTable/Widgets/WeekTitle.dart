import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Constant.dart';
import '../../../Utils/WeekUtil.dart';

class WeekTitle extends StatelessWidget {
  final int _maxShowDays;
  final double _weekTitleHeight;
  final double _classTitleWidth;
  final bool _isShowMonth;
  final bool _isShowDate;
  final bool? _isWhiteMode;
  final int _biasWeek;

  const WeekTitle(
      this._maxShowDays,
      this._weekTitleHeight,
      this._classTitleWidth,
      this._isShowMonth,
      this._isShowDate,
      this._isWhiteMode,
      this._biasWeek,
      {Key? key})
      : super(key: key);

  Color? getColor() {
    if (_isWhiteMode == null) {
      return null;
    } else {
      return _isWhiteMode! ? Colors.white : Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    int nowWeekDay = WeekUtil.getWeekDay();
//    List<String> _dayList = WeekUtil.getDayList();
    List<String> _dayList = WeekUtil.getTmpDayList(_biasWeek);
    List<Widget> _weekTitle = List.generate(
        _maxShowDays,
        (int i) => Expanded(
              child: Container(
                color:
                    i == nowWeekDay - 1 ? Colors.black12 : Colors.transparent,
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
                                    color: getColor()),
                              ),
                              Text(
                                _dayList[i],
                                style: TextStyle(
                                    fontSize: 10,
                                    color: getColor()),
                              )
                            ])
                      : Center(
                          child: Text(
                            Constant.WEEK_WITHOUT_BIAS_WITHOUT_PRE[i],
                            style: TextStyle(
                                color:getColor()),
                          ),
                        ),
                ),
                padding: const EdgeInsets.all(0.0),
              ),
            ));

    _weekTitle.insert(
        0,
        SizedBox(
          width: _classTitleWidth,
          child: _isShowMonth
              ? (_isShowDate
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
//                              WeekUtil.getNowMonth().toString() +
                              WeekUtil.getTmpMonth(_biasWeek).toString() +
                                  S.of(context).month,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: getColor()),
                            ),
                            Text(
//                              WeekUtil.getNowMonthName() + '.',
                              WeekUtil.getTmpMonthName(_biasWeek) + '.',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: getColor()),
                            )
                          ]),
                    )
                  : Center(
                      child: Text(
                        WeekUtil.getTmpMonth(_biasWeek).toString() +
                            S.of(context).month,
//                        WeekUtil.getNowMonth().toString() + S.of(context).month,
                        style: TextStyle(color: getColor()),
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
    return Row(children: _weekTitle);
  }
}
