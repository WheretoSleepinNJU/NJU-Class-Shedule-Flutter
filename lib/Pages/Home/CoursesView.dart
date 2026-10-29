import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../AdaptiveUI/adaptive_ui.dart';
import '../../Models/CourseGroup.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../AllCourse/AllCourseView.dart';
import '../EditCourse/EditCourseView.dart';
import '../Import/ImportView.dart';
import '../Lecture/LecturesView.dart';
import '../CourseTable/Widgets/CourseDetailDialog.dart';
import 'EmptyCourses.dart';
import '../CourseTable/Widgets/CourseSummaryTile.dart';

class _CoursesData {
  const _CoursesData(this.tableId, this.groups, this.times);
  final int tableId;
  final List<List<Course>> groups;
  final List<Map> times;
}

class CoursesView extends StatefulWidget {
  const CoursesView({super.key, this.provider, this.tables});
  final CourseProvider? provider;
  final CourseTableProvider? tables;
  @override
  State<CoursesView> createState() => CoursesViewState();
}

class CoursesViewState extends State<CoursesView> {
  late final _provider = widget.provider ?? CourseProvider();
  late final _tables = widget.tables ?? CourseTableProvider();
  Future<_CoursesData>? _data;
  int _category = 0;
  final Set<int> _visited = {0};
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  Future<_CoursesData> _load() async {
    final id = await ScopedModel.of<MainStateModel>(context).getClassTable();
    final rows = await _provider.getAllCourses(id);
    final times = await _tables.getClassTimeList(id);
    return _CoursesData(
      id,
      CourseGroup.collect(
        rows.map((row) => Course.fromMap(Map<String, dynamic>.from(row))),
      ),
      times,
    );
  }

  void reload() {
    if (!mounted) return;
    setState(() {
      _data = _load();
    });
  }

  void _changed() {
    if (!mounted) return;
    reload();
    MainStateModel.of(context).refresh();
  }

  Future<void> _add() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const EditCourseView()));
    if (result == true) _changed();
  }

  Future<void> _import() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ImportView()));
    if (result == true) _changed();
  }

  Future<void> _chooseAdd() async {
    final choice = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AdaptiveDialog(
        title: Text(S.of(context).add_class),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdaptiveListTile(
              title: Text(S.of(context).import_manually_title),
              leading: const Icon(Icons.add_rounded),
              onTap: () => Navigator.pop(dialogContext, 0),
            ),
            AdaptiveListTile(
              title: Text(S.of(context).import_title),
              leading: const Icon(Icons.download_rounded),
              onTap: () => Navigator.pop(dialogContext, 1),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 0) await _add();
    if (choice == 1) await _import();
  }

  Future<void> _details(_CoursesData data, List<Course> group) async {
    final edit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CourseDetailDialog(
        group.first,
        true,
        () => Navigator.pop(dialogContext, false),
        meetings: group,
        classTimeList: data.times,
        onEdit: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (edit != true || !mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCourseView(
          course: group.first,
          meetings: group,
          tableId: data.tableId,
          classTimeList: data.times,
        ),
      ),
    );
    if (result == true) _changed();
  }

  Widget _added() => FutureBuilder<_CoursesData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: AdaptiveButton.text(
            onPressed: reload,
            child: Text(S.of(context).courses_load_failed),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: AdaptiveProgressIndicator());
      }
      final data = snapshot.data!;
      if (data.groups.isEmpty) {
        return AdaptivePageList(
          children: [EmptyCourses(onAdd: _add, onImport: _import)],
        );
      }
      return AdaptiveRefreshIndicator(
        onRefresh: () async {
          reload();
          await _data;
        },
        child: AdaptivePageList(
          key: const PageStorageKey('added-courses'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            for (final group in data.groups)
              AdaptiveSection(
                children: [
                  CourseSummaryTile(
                    meetings: group,
                    classTimeList: data.times,
                    onTap: () => _details(data, group),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = [s.course_added, s.course_catalog, s.course_lectures];
    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(
        title: Text(s.home_courses),
        tabs: AdaptiveTabRow(
          tabs: labels,
          selectedIndex: _category,
          onSelected: (index) {
            setState(() {
              _category = index;
              _visited.add(index);
            });
            if (index == 0) reload();
          },
        ),
        actions: [
          AdaptiveIconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: s.add_class,
            onPressed: _chooseAdd,
          ),
        ],
      ),
      body: IndexedStack(
        index: _category,
        children: [
          Visibility(
            visible: _category == 0,
            maintainState: true,
            child: _added(),
          ),
          Visibility(
            visible: _category == 1,
            maintainState: true,
            child: _visited.contains(1)
                ? const AdaptiveEmbeddedPage(child: AllCourseView())
                : const SizedBox.shrink(),
          ),
          Visibility(
            visible: _category == 2,
            maintainState: true,
            child: _visited.contains(2)
                ? const AdaptiveEmbeddedPage(child: LectureView())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
