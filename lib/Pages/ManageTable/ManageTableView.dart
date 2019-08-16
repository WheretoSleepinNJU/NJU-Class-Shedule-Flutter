import 'package:flutter/material.dart';
import '../../Resources/Strings.dart';
import '../Import/ImportView.dart';
import '../../Models/CourseTableModel.dart';

class ManageTableView extends StatefulWidget {
  ManageTableView() : super();
  final String title = '课表管理';

  @override
  _ManageTableViewState createState() => _ManageTableViewState();
}

class _ManageTableViewState extends State<ManageTableView> {
  CourseTableProvider courseTableProvider = new CourseTableProvider();
  List<Widget> courseTableWidgetList = [Container()];
  String text = '';

  @override
  void initState() {
    super.initState();
//    insertData();
    getData();
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
                await courseTableProvider
                    .insert(new CourseTable(str));
              getData();
            },
          )
        ]),
        body: SingleChildScrollView(
            child: Column(
                children: ListTile.divideTiles(
                        context: context, tiles: courseTableWidgetList)
                    .toList())));
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

  void getData() async {
    List tmp = await courseTableProvider.getAllCourseTable();
    setState(() {
      courseTableWidgetList = List.generate(
          tmp.length,
          (int i) => ListTile(
                title: Text(tmp[i]['name']),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => ImportView()));
                },
              ));
    });
  }
}
