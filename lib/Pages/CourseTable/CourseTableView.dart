import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import './CourseTablePresenter.dart';
import '../Settings/SettingsView.dart';
import '../../Components/Separator.dart';
import '../../Resources/Config.dart';
import '../../Utils/States/MainState.dart';
import '../../Models/CourseModel.dart';

import 'Widgets/BackgroundImage.dart';
import 'Widgets/WeekSelector.dart';
import 'Widgets/WeekTitle.dart';

class CourseTableView extends StatefulWidget {
  @override
  CourseTableViewState createState() => new CourseTableViewState();
}

class CourseTableViewState extends State<CourseTableView> {
  CourseTablePresenter _presenter = new CourseTablePresenter();
  int _maxShowClasses;
  int _maxShowDays;
  int _nowWeekNum;
  double _screenWidth;
  double _classTitleWidth;
  double _classTitleHeight;
  double _weekTitleHeight;
  double _weekTitleWidth;

  bool weekSelectorVisibility = false;

  List<Course> multiClassesDialog = [];

  Future<List<Widget>> _getData(BuildContext context) async {
//    await courseTablePresenter.insertMockData();

    _maxShowClasses = Config.MAX_CLASSES;
    _maxShowDays = 7;
    int index = await ScopedModel.of<MainStateModel>(context).getClassTable();
    _nowWeekNum = await ScopedModel.of<MainStateModel>(context).getWeek();

    await _presenter.refreshClasses(index, _nowWeekNum);

    _screenWidth = MediaQuery.of(context).size.width;
    _classTitleWidth = 30;
    _classTitleHeight = 50;
    _weekTitleHeight = 30;
    _weekTitleWidth = (_screenWidth - _classTitleWidth) / _maxShowDays;

    List<Widget> classWidgets = await _presenter.getClassesWidgetList(
        context, _classTitleHeight, _weekTitleWidth);

    return classWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
            builder: (context, child, model) {
          print('CourseTableView refreshed.');

          return FutureBuilder<List<Widget>>(
              future: _getData(context),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                } else {
                  List<Widget> _classTitle = new List.generate(
                    _maxShowClasses,
                    (int i) => new Container(
                        margin: EdgeInsets.only(top: i * _classTitleHeight),
                        height: _classTitleHeight,
                        width: _classTitleWidth,
                        child: Center(
                            child: Text((i + 1).toString(),
                                textAlign: TextAlign.center))),
                  );

                  // TODO: fix bug in stack
                  List<Widget> _divider = new List.generate(
                      _maxShowClasses,
                      (int i) => new Container(
                            margin: EdgeInsets.only(
                                top: (i + 1) * _classTitleHeight),
                            width: _weekTitleWidth * _maxShowDays,
                            child: Separator(color: Colors.grey),
                          ));

                  return Scaffold(
                      appBar: AppBar(
                          centerTitle: true,
                          title: Column(children: [
                            Text(S.of(context).app_name),
                            GestureDetector(
                              child: Text(
                                  S.of(context).week(_nowWeekNum.toString()),
                                  style: TextStyle(fontSize: 16)),
                              onTap: () => setState(() {
                                weekSelectorVisibility =
                                    !weekSelectorVisibility;
                              }),
                            )
                          ]),
                          actions: <Widget>[
                            IconButton(
                              icon: Icon(Icons.lightbulb_outline),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        SettingsView()));
                              },
                            )
                          ]),
                      body:
                      Stack(children: [
                        // TODO: 背景图片
//                        BackgroundImage(),
                        SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                              WeekSelector(model, weekSelectorVisibility),
                              WeekTitle(_maxShowDays, _weekTitleHeight,
                                  _classTitleWidth),
                              Row(children: [
                                Container(
                                    height: _classTitleHeight * _maxShowClasses,
                                    width: _classTitleWidth,
                                    child: Stack(children: _classTitle)),
                                Container(
                                    height: _classTitleHeight * _maxShowClasses,
                                    width: _screenWidth - _classTitleWidth,
                                    // TODO: fix bug in stack
                                    child: Stack(
                                        children: _divider + snapshot.data,
                                        overflow: Overflow.visible))
                              ])
                            ])),
                      ])
                  );
                }
              });
        }));
  }
}
