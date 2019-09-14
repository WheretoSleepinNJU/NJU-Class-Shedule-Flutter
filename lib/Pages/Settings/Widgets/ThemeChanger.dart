import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../Utils/States/MainState.dart';
import '../../../Resources/Themes.dart';

class ThemeChanger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                themeDataList.length,
                    (int i) =>
                new Container(
                    width: 30,
                    height: 30,
                    margin: EdgeInsets.only(
                        left: 15, top: 10, bottom: 10),
                    decoration: new BoxDecoration(
                      color: themeDataList[i].primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: InkResponse(
                      onTap: () =>
                          MainStateModel.of(context).changeTheme(i),
                    )))));
  }
}