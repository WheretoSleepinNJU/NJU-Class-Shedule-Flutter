import 'PlatformSettings.dart';
import '../../../generated/l10n.dart';
import 'SettingsCard.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Utils/WeekUtil.dart';
import '../../../Components/Toast.dart';
import '../../../Resources/Config.dart';

class WeekChanger extends StatefulWidget {
  const WeekChanger({Key? key}) : super(key: key);

  @override
  State<WeekChanger> createState() => _WeekChangerState();
}

class _WeekChangerState extends State<WeekChanger> {
  Future<int>? _week;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to model changes, not to each unrelated parent repaint/rebuild.
    MainStateModel.of(context);
    _week = _getWeek(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _week,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (!snapshot.hasData) {
          return Container();
        } else {
          return SettingsEntry(
            icon: Icons.date_range_rounded,
            iconColor: const Color(0xFF37AF77),
            title: Text(S.of(context).change_week_title),
            subtitle: Text(
              S.of(context).change_week_subtitle +
                  S.of(context).week(snapshot.data.toString()),
            ),
            onTap: () async {
              UmengCommonSdk.onEvent("week_change", {"action": "show"});
              final nowWeek = snapshot.data!;
              var selected = nowWeek.clamp(1, Config.MAX_WEEKS);
              final result = await showDialog<int>(
                context: context,
                builder: (dialogContext) => StatefulBuilder(
                  builder: (context, update) => SettingsActionDialog(
                    S.of(context).change_week_title,
                    SettingsNumberPicker(
                      value: selected,
                      min: 1,
                      max: Config.MAX_WEEKS,
                      label: (value) => S.of(context).week('$value'),
                      onValueChanged: (value) => update(() => selected = value),
                    ),
                    widgetCancelAction: () {
                      UmengCommonSdk.onEvent('week_change', {
                        'action': 'cancel',
                      });
                      Navigator.pop(dialogContext);
                    },
                    widgetOKAction: () =>
                        Navigator.pop(dialogContext, selected),
                  ),
                ),
              );
              if (result != null && context.mounted) {
                UmengCommonSdk.onEvent('week_change', {'action': 'accept'});
                await changeWeek(context, result - 1, nowWeek);
              }
            },
          );
        }
      },
    );
  }

  Future<int> _getWeek(BuildContext context) async {
    int week = await MainStateModel.of(context).getWeek();
    return week;
  }

  Future<bool> changeWeek(
    BuildContext context,
    int changedWeek,
    int nowWeek,
  ) async {
    if (changedWeek == nowWeek - 1) {
      Toast.showToast(S.of(context).nowweek_not_edited_success_toast, context);
    } else {
      await WeekUtil.setNowWeek(changedWeek + 1);
      if (!context.mounted) return false;
      Toast.showToast(S.of(context).nowweek_edited_success_toast, context);
      ScopedModel.of<MainStateModel>(context).refresh();
    }
    return true;
  }
}
