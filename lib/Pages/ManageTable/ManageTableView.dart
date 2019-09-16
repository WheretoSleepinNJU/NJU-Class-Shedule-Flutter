import '../../generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Models/CourseTableModel.dart';
import '../../Utils/States/MainState.dart';
import 'Widgets/AddDialog.dart';

class ManageTableView extends StatefulWidget {
  ManageTableView() : super();

  @override
  _ManageTableViewState createState() => _ManageTableViewState();
}

class _ManageTableViewState extends State<ManageTableView> {
  CourseTableProvider courseTableProvider = new CourseTableProvider();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(S.of(context).class_table_manage_title),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () async {
                  String str = await _addTableDialog(context);
                  if (str != '')
                    await courseTableProvider.insert(new CourseTable(str));
                },
              )
            ]),
        body: SingleChildScrollView(
            child: FutureBuilder<List<Widget>>(
                future: _getData(context),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Widget>> snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  } else {
                    return Column(
                        children: ListTile.divideTiles(
                                context: context, tiles: snapshot.data)
                            .toList());
                  }
                })));
  }

  Future<String> _addTableDialog(BuildContext context) async {
    String tableName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AddDialog();
      },
    );
    return tableName;
  }

  Future<List<Widget>> _getData(BuildContext context) async {
    List courseTables = await courseTableProvider.getAllCourseTable();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedIndex = prefs.getInt('tableId') ?? 0;
    List <Widget> result = List.generate(
        courseTables.length,
        (int i) => Container(
            color: _selectedIndex != null && _selectedIndex == i
                ? Theme.of(context).primaryColor
                : Colors.white,
            child: ListTile(
              title: Text(courseTables[i]['name'],
                  style: TextStyle(
                    color: _selectedIndex != null && _selectedIndex == i
                        ? Colors.white
                        : Colors.black,
                  )),
              onTap: () {
                setState(() => _selectedIndex = i);
                ScopedModel.of<MainStateModel>(context).changeclassTable(i);
              },
            )));
    return result;
  }
}
