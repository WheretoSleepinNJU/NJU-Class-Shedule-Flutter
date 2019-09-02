// This sample shows adding an action to an [AppBar] that opens a shopping cart.

import 'package:flutter/material.dart';
import 'Pages/CourseTable/CourseTableView.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';
import 'Utils/States/MainState.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  int themeIndex = await getTheme();
//  runApp(MyApp());
  runApp(MyApp(themeIndex));
}


Future<int> getTheme() async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  int themeIndex = sp.getInt("themeIndex");
  if(themeIndex != null) {
    return themeIndex;
  }
  return 0;
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
//    Application.eventBus = new EventBus();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainStateModel>(
        model: MainStateModel(),
        child: ScopedModelDescendant<MainStateModel>(
          builder: (context, child, model) {
            print("rebuild");
            return  MaterialApp(
              theme: ThemeData(
                  primaryColor: themeList[model.themeIndex != null ? model.themeIndex : widget.themeIndex]
              ),
              home: CourseTableView(),
            );
          },
        )
    );
  }
}

//import 'package:flutter/material.dart';
//import 'Pages/CourseTable/CourseTableView.dart';
//
//void main() => runApp(MyApp());
//
//class MyApp extends StatelessWidget {
//  // This widget is the root of your application.
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Flutter Code Sample for material.AppBar.actions',
//      theme: ThemeData(
//        primarySwatch: Colors.pink,
//      ),
//      home: MyStatelessWidget(),
//    );
//  }
//}
//
//class MyStatelessWidget extends StatelessWidget {
//  MyStatelessWidget({Key key}) : super(key: key);
//
//  @override
//  Widget build(BuildContext context) {
////    return Scaffold(
////      appBar: AppBar(
////        title: Text('Hello World'),
////        actions: <Widget>[
////          IconButton(
////            icon: Icon(Icons.shopping_cart),
////            tooltip: 'Open shopping cart',
////            onPressed: () {
////              // ...
////            },
////          ),
////        ],
////      ),
////    );
//    return CourseTableView();
//  }
//}
