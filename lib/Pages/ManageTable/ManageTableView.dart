import '../../AdaptiveUI/adaptive_ui.dart';
import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Models/CourseTableModel.dart';
import '../../Utils/States/MainState.dart';
import '../../Components/Toast.dart';
import 'Widgets/AddDialog.dart';
import 'Widgets/DelDialog.dart';
import 'Widgets/TableNameDialog.dart';

class ManageTableView extends StatefulWidget {
  const ManageTableView({Key? key, this.provider}) : super(key: key);

  final CourseTableProvider? provider;

  @override
  _ManageTableViewState createState() => _ManageTableViewState();
}

class _ManageTableViewState extends State<ManageTableView> {
  late final CourseTableProvider courseTableProvider;
  int _selectedIndex = 0;
  late Future<List> _data;

  @override
  void initState() {
    super.initState();
    courseTableProvider = widget.provider ?? CourseTableProvider();
    _data = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(
        title: Text(S.of(context).class_table_manage_title),
        actions: <Widget>[
          AdaptiveIconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              String str = await _addTableDialog(context);
              if (str != '') {
                CourseTable courseTable = await courseTableProvider.insert(
                  CourseTable(str),
                );
                Toast.showToast(
                  S.of(context).add_class_table_success_toast,
                  context,
                );
                if (courseTable.id != 0) {
                  ScopedModel.of<MainStateModel>(
                    context,
                  ).changeclassTable(courseTable.id!);
                }
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final rows = _rows(context, snapshot.data!);
            return AdaptivePageList(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0) const AdaptiveDivider(),
                  rows[index],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String> _addTableDialog(BuildContext context) async {
    String? tableName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return const AddDialog();
      },
    );
    return tableName!;
  }

  Future<bool> _delTableDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return const DelDialog();
      },
    );
    return result ?? false;
  }

  Future<void> _renameTable(int id, String oldName) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TableNameDialog(name: oldName),
    );
    if (name == null || name == oldName || !mounted) return;
    try {
      if (!await courseTableProvider.rename(id, name)) {
        throw StateError('Missing timetable');
      }
      if (!mounted) return;
      setState(() {
        _data = _loadData();
      });
      // Notify the timetable page and refresh the selected widget's metadata.
      if (id == _selectedIndex) {
        await ScopedModel.of<MainStateModel>(context).changeclassTable(id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).table_rename_failed)),
        );
      }
    }
  }

  Future<List> _loadData() async {
    final tables = await courseTableProvider.getAllCourseTable();
    final prefs = await SharedPreferences.getInstance();
    if (_selectedIndex == 0) _selectedIndex = prefs.getInt('tableId') ?? 1;
    return tables;
  }

  List<Widget> _rows(BuildContext context, List courseTables) {
    List<Widget> result = List.generate(
      courseTables.length,
      (int i) => AdaptiveSurface(
        color: _selectedIndex == courseTables[i]['id']
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        child: AdaptiveListTile(
          selected: _selectedIndex == courseTables[i]['id'],
          title: Text(
            courseTables[i]['name'],
            style: TextStyle(
              color: _selectedIndex == courseTables[i]['id']
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: _selectedIndex == courseTables[i]['id']
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveIconButton(
                key: ValueKey('rename-table-${courseTables[i]['id']}'),
                tooltip: S.of(context).rename_table,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _renameTable(
                  courseTables[i]['id'],
                  courseTables[i]['name'],
                ),
              ),
              if (_selectedIndex == courseTables[i]['id'])
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              else
                AdaptiveIconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    bool rst = await _delTableDialog(context);
                    if (rst) {
                      await courseTableProvider.delete(courseTables[i]['id']);
                      Toast.showToast(
                        S.of(context).del_class_table_success_toast,
                        context,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
            ],
          ),
          onTap: () {
            setState(() => _selectedIndex = courseTables[i]['id']);
            ScopedModel.of<MainStateModel>(
              context,
            ).changeclassTable(courseTables[i]['id']);
          },
        ),
      ),
    );
    return result;
  }
}
