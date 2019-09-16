import '../../../generated/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Utils/WeekUtil.dart';
import '../../../Components/Toast.dart';
import '../../../Components/Dialog.dart';
import '../../../Resources/Config.dart';

class WeekChanger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
        future: _getWeek(context),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          } else {
            return ListTile(
              title: Text(S.of(context).change_week_title),
              subtitle: Text(S.of(context).change_week_subtitle +
                  S.of(context).week(snapshot.data.toString())),
              onTap: () async {
                await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    int changedWeek = snapshot.data - 1;
                    return mDialog(
                      S.of(context).change_week_title,
                      Container(
                          height: 32,
                          child: CupertinoPicker(
                              scrollController: new FixedExtentScrollController(
                                initialItem: snapshot.data - 1,
                              ),
                              itemExtent: 32.0,
                              backgroundColor: Colors.white,
                              onSelectedItemChanged: (int index) {
                                changedWeek = index;
                              },
                              children: new List<Widget>.generate(
                                  Config.MAX_WEEKS, (int index) {
                                return new Center(
                                  child: new Text(
                                    S.of(context).week((index + 1).toString()),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              }))),
                      <Widget>[
                        FlatButton(
                          child: Text(S.of(context).cancel),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                            child: Text(S.of(context).ok),
                            onPressed: () async {
                              await changeWeek(
                                  context, changedWeek, snapshot.data);
                              Navigator.of(context).pop();
                            }),
                      ],
                    );
                  },
                );
              },
            );
          }
        });
  }

  Future<int> _getWeek(BuildContext context) async {
    int week = await MainStateModel.of(context).getWeek();
    return week;
  }

  void changeWeek(BuildContext context, int changedWeek, int nowWeek) async {
    if (changedWeek == nowWeek - 1) {
      Toast.showToast(S.of(context).nowweek_not_edited_success_toast, context);
    } else {
      await WeekUtil.setNowWeek(changedWeek + 1);
      Toast.showToast(S.of(context).nowweek_edited_success_toast, context);
      Navigator.of(context).pop();
    }
  }
}
