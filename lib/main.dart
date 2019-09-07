import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'Pages/CourseTable/CourseTableView.dart';
import 'Utils/States/MainState.dart';
import 'Utils/InitUtil.dart';
import 'Resources/Themes.dart';

void main() async {
  //Initialize the app config.
  int themeIndex = await InitUtil.Initialize();
  runApp(MyApp(themeIndex));
}

class MyApp extends StatefulWidget {
  final int themeIndex;

  MyApp(this.themeIndex);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
          builder: (context, child, model) {
            print("rebuild");
            return MaterialApp(
              theme:
              themeDataList[model.themeIndex != null? model.themeIndex: widget.themeIndex],
              home: CourseTableView(),
            );
          },
        ));
  }
}

