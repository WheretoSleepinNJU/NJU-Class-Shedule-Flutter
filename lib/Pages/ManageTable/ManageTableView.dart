import 'package:flutter/material.dart';
import '../../Resources/Strings.dart';
import '../Import/ImportView.dart';
import '../../Models/CourseTableModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Utils/States/MainState.dart';

class ManageTableView extends StatefulWidget {
  ManageTableView() : super();
  final String title = '课表管理';

  @override
  _ManageTableViewState createState() => _ManageTableViewState();
}

class _ManageTableViewState extends State<ManageTableView> {
  CourseTableProvider courseTableProvider = new CourseTableProvider();
  List<Widget> courseTableWidgetList = [Container()];
  int _selectedIndex = 0;
  String text = '';

  @override
  void initState() {
    super.initState();
//    insertData();
//    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
//                Navigator.of(context).pop();
//                  Navigator.of(context).push(MaterialPageRoute(
//                      builder: (BuildContext context) => SettingsView()));
              String str = await _addTableDialog(context);
              if (str != '')
                await courseTableProvider.insert(new CourseTable(str));
//              getData();
            },
          )
        ]),
        body: SingleChildScrollView(child:
            ScopedModelDescendant<MainStateModel>(
                builder: (context, child, model) {
          getData(model);
          return Column(
              children: ListTile.divideTiles(
                      context: context, tiles: courseTableWidgetList)
                  .toList());
        })));
//        SingleChildScrollView(
//            child: Column(
//                children: ListTile.divideTiles(
//                        context: context, tiles: courseTableWidgetList)
//                    .toList())));
  }

//  _onSelected(int index) async {
  _onSelected(MainStateModel model, int index) async {
    setState(() => _selectedIndex = index);
    print(index);
    model.changeclassTable(index);
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    await prefs.setInt('tableId', index);
//    Navigator.of(context).pop();
  }

  Future<String> _addTableDialog(BuildContext context) async {
    String tableName = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Strings.add_table_title),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(),
                onChanged: (value) {
                  tableName = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(Strings.ok),
              onPressed: () {
                Navigator.of(context).pop(tableName);
              },
            ),
          ],
        );
      },
    );
  }

//  void insertData() async {
//    await courseTableProvider.open();
//    await courseTableProvider
//        .insert(new CourseTable.fromMap({"name": "flutter大全0"}));
//    await courseTableProvider
//        .insert(new CourseTable.fromMap({"name": "flutter大全1"}));
//    await courseTableProvider
//        .insert(new CourseTable.fromMap({"name": "flutter大全2"}));
//    await courseTableProvider
//        .insert(new CourseTable.fromMap({"name": "flutter大全3"}));
//    //切记用完就close
//    await courseTableProvider.close();
//  }

  void getData(MainStateModel model) async {
    List tmp = await courseTableProvider.getAllCourseTable();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedIndex = prefs.getInt('tableId') ?? 0;
    setState(() {
      courseTableWidgetList = List.generate(
          tmp.length,
          (int i) => Container(
              color: _selectedIndex != null && _selectedIndex == i
                  ? Theme.of(context).primaryColor
                  : Colors.white,
              child: ListTile(
                title: Text(tmp[i]['name'],
                    style: TextStyle(
                      color: _selectedIndex != null && _selectedIndex == i
                          ? Colors.white
                          : Colors.black,
                    )),
                onTap: () {
                  _onSelected(model, i);
                },
              )));
    });
  }
}
