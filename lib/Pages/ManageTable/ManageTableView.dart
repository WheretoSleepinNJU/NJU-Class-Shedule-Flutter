import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Models/CourseTableModel.dart';
import '../../Utils/States/MainState.dart';
import '../../Components/Toast.dart';
import 'Widgets/AddDialog.dart';
import 'Widgets/DelDialog.dart';

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
                  if (str != '') {
                    CourseTable courseTable =
                        await courseTableProvider.insert(new CourseTable(str));
                    Toast.showToast(
                        S.of(context).add_class_table_success_toast, context);
                    if (courseTable.id != 0)
                      ScopedModel.of<MainStateModel>(context)
                          .changeclassTable(courseTable.id);
                    Navigator.of(context).pop();
                  }
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

  Future<bool> _delTableDialog(BuildContext context) async {
    String result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return DelDialog();
      },
    );
    if (result == "true") {
      return true;
    } else
      return false;
  }

  Future<List<Widget>> _getData(BuildContext context) async {
    List courseTables = await courseTableProvider.getAllCourseTable();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedIndex = prefs.getInt('tableId') ?? 0;
    List<Widget> result = List.generate(
        courseTables.length,
        (int i) => Container(
            color: _selectedIndex == courseTables[i]['id']
                ? Theme.of(context).primaryColor
                : Colors.white,
            child: ListTile(
              title: Text(courseTables[i]['name'],
                  style: TextStyle(
                    color: _selectedIndex == courseTables[i]['id']
                        ? Colors.white
                        : Colors.black,
                  )),
              trailing: _selectedIndex == courseTables[i]['id']
                  ? null
                  : IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        bool rst = await _delTableDialog(context);
                        if (rst) {
                          await courseTableProvider
                              .delete(courseTables[i]['id']);
                          Toast.showToast(
                              S.of(context).add_class_table_success_toast,
                              context);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
              onTap: () {
                setState(() => _selectedIndex = courseTables[i]['id']);
                ScopedModel.of<MainStateModel>(context)
                    .changeclassTable(courseTables[i]['id']);
              },
            )));
    return result;
  }
}
