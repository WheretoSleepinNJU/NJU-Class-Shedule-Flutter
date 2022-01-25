import '../../../generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Utils/WeekUtil.dart';
import '../../../Components/Toast.dart';
import '../../../Components/Dialog.dart';
import '../../../Resources/Config.dart';

class WeekChanger extends StatelessWidget {
  const WeekChanger({Key? key}) : super(key: key);

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
                UmengCommonSdk.onEvent("week_change", {"action": "show"});
                await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    int changedWeek = snapshot.data! - 1;
                    return MDialog(
                      S.of(context).change_week_title,
                      SizedBox(
                          height: 96,
                          child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: snapshot.data! > Config.MAX_WEEKS
                                    ? -1
                                    : snapshot.data! - 1,
                              ),
                              itemExtent: 32.0,
                              backgroundColor: Colors.white,
                              onSelectedItemChanged: (int index) {
                                changedWeek = index;
                              },
                              children: List<Widget>.generate(
                                  Config.MAX_WEEKS, (int index) {
                                return Center(
                                  child: Text(
                                    S.of(context).week((index + 1).toString()),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                );
                              }))),
                      <Widget>[
                        FlatButton(
                          textColor: Colors.grey,
                          child: Text(S.of(context).cancel),
                          onPressed: () {
                            UmengCommonSdk.onEvent(
                                "week_change", {"action": "cancel"});
                            Navigator.of(context).pop();
                          },
                        ),
                        FlatButton(
                            textColor: Theme.of(context).primaryColor,
                            child: Text(S.of(context).ok),
                            onPressed: () async {
                              UmengCommonSdk.onEvent(
                                  "week_change", {"action": "accept"});
                              await changeWeek(
                                  context, changedWeek, snapshot.data!);
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

  Future<bool> changeWeek(
      BuildContext context, int changedWeek, int nowWeek) async {
    if (changedWeek == nowWeek - 1) {
      Toast.showToast(S.of(context).nowweek_not_edited_success_toast, context);
    } else {
      await WeekUtil.setNowWeek(changedWeek + 1);
      Toast.showToast(S.of(context).nowweek_edited_success_toast, context);
      ScopedModel.of<MainStateModel>(context).refresh();
      Navigator.of(context).pop();
    }
    return true;
  }
}
