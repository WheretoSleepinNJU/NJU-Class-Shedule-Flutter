import '../../../generated/l10n.dart';
import 'package:flutter/material.dart';
import '../../../Resources/Config.dart';
import '../../../Utils/States/MainState.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import '../../../Components/Toast.dart';

class WeekSelector extends StatelessWidget {
  final bool weekSelectorVisibility;
  final MainStateModel model;

  const WeekSelector(this.model, this.weekSelectorVisibility, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return weekSelectorVisibility
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
                children: List.generate(
                    Config.MAX_WEEKS,
                    (int i) => Container(
                        color: Theme.of(context).appBarTheme.backgroundColor,
                        padding: const EdgeInsets.only(
                            left: 5, top: 10, right: 5, bottom: 10),
                        child: InkWell(
                            onTap: () {
                              Toast.showToast(
                                  S.of(context).go_to_settings_toast, context);
                              model.changeTmpWeek(i + 1);
                              UmengCommonSdk.onEvent(
                                  "week_choose", {"action": "change"});
                            },
                            child: Text(
                              S.of(context).week((i + 1).toString()),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ))))))
        : Container();
  }
}
