import 'package:flutter/material.dart';
// import 'package:scoped_model/scoped_model.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Resources/Themes.dart';
import './ThemeCustomDialog.dart';

class ThemeChanger extends StatelessWidget {
  const ThemeChanger({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(
                themeDataList.length,
                (int i) => Container(
                    width: 30,
                    height: 30,
                    margin:
                        const EdgeInsets.only(left: 15, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: themeDataList[i].appBarTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: InkResponse(onTap: () {
                      UmengCommonSdk.onEvent("theme_change", {"type": i});
                      MainStateModel.of(context).changeTheme(i);
                    })))
              ..add(Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child: InkWell(
                    child: const Text('自定义'),
                    onTap: () {
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return const ThemeCustomDialog();
                        },
                      );
                    }),
              ))));
  }
}
