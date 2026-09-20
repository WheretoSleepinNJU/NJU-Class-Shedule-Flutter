import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Models/CourseModel.dart';
import '../../Resources/ColorSchemes.dart';
import '../../Utils/ColorUtil.dart';
import '../../Utils/States/MainState.dart';
import '../../Components/Toast.dart';
import 'Widgets/ColorPickerSheet.dart';

/// 课程配色设置页：分两块——
/// 1.「配色方案」：整表切换一套预设色板，会覆盖所有课程（包括手动
///    单独设过颜色的课程），用之前先弹确认。
/// 2.「自定义配色」：列出当前课表里所有课程，逐个改色，点"确认应用"
///    才真正写库（避免选一次存一次库、频繁刷新）。
class ColorSettingsView extends StatefulWidget {
  const ColorSettingsView({Key? key}) : super(key: key);

  @override
  State<ColorSettingsView> createState() => _ColorSettingsViewState();
}

class _ColorGroup {
  final int courseId;
  final String name;
  final List<Course> rows;
  String currentHex;

  _ColorGroup(this.courseId, this.name, this.rows, this.currentHex);
}

class _ColorSettingsViewState extends State<ColorSettingsView> {
  final CourseProvider _courseProvider = CourseProvider();

  bool _loading = true;
  int _tableId = 0;
  ActiveColorPool? _activePool;
  List<_ColorGroup> _groups = [];
  final Map<int, String> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tableId = await ScopedModel.of<MainStateModel>(context,
            rebuildOnChange: false)
        .getClassTable();
    final scheme = await ColorPool.getActiveScheme();
    final pool = await ColorPool.getActivePool();

    final rawCourses = await _courseProvider.getAllCourses(tableId);
    final courses =
        rawCourses.map((m) => Course.fromMap(Map<String, dynamic>.from(m))).toList();
    final byId = <int, List<Course>>{};
    for (final c in courses) {
      final id = c.courseId ?? 0;
      byId.putIfAbsent(id, () => []).add(c);
    }
    List<_ColorGroup> groups = byId.entries.map((entry) {
      final rows = entry.value;
      final hex = rows.first.getColor(pool) ?? scheme.colors.first;
      return _ColorGroup(entry.key, rows.first.name ?? '未命名课程', rows, hex);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;
    setState(() {
      _tableId = tableId;
      _activePool = pool;
      _groups = groups;
      _pendingChanges.clear();
      _loading = false;
    });
  }

  Future<void> _applyScheme(CourseColorScheme scheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用配色方案'),
        content: Text(
            '切换到"${scheme.displayName}"会重新分配所有课程的颜色，'
            '包括你之前单独手动设置过颜色的课程，确定应用吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ColorPool.setActiveScheme(scheme.id);

    final rawCourses = await _courseProvider.getAllCourses(_tableId);
    for (final m in rawCourses) {
      final course = Course.fromMap(Map<String, dynamic>.from(m));
      if (course.color != null && course.color!.trim().isNotEmpty) {
        course.color = null;
        await _courseProvider.update(course);
      }
    }

    if (!mounted) return;
    Toast.showToast('已应用"${scheme.displayName}"配色方案', context);
    await _load();
  }

  Future<void> _editGroupColor(_ColorGroup group) async {
    final palette = _activePool?.palette ?? CourseColorSchemes.all.first.colors;
    final picked = await showCourseColorPickerSheet(
      context: context,
      initialColor: group.currentHex,
      presetColors: palette,
    );
    if (picked == null) return;
    setState(() {
      group.currentHex = picked;
      _pendingChanges[group.courseId] = picked;
    });
  }

  Future<void> _applyCustomChanges() async {
    for (final group in _groups) {
      final newHex = _pendingChanges[group.courseId];
      if (newHex == null) continue;
      for (final row in group.rows) {
        row.color = newHex;
        await _courseProvider.update(row);
      }
    }
    if (!mounted) return;
    Toast.showToast('已应用课程配色', context);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('课程颜色'),
          bottom: const TabBar(tabs: [
            Tab(text: '选取配色方案'),
            Tab(text: '自定义配色'),
          ]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                _buildSchemeTab(),
                _buildCustomTab(),
              ]),
      ),
    );
  }

  Widget _buildSchemeTab() {
    return ListView.builder(
      itemCount: CourseColorSchemes.all.length,
      itemBuilder: (context, index) {
        final scheme = CourseColorSchemes.all[index];
        return ListTile(
          title: Text(scheme.displayName),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: scheme.colors
                  .take(10)
                  .map((hex) => Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: HexColor(hex),
                          shape: BoxShape.circle,
                        ),
                      ))
                  .toList(),
            ),
          ),
          trailing: TextButton(
            onPressed: () => _applyScheme(scheme),
            child: const Text('应用'),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    if (_groups.isEmpty) {
      return const Center(child: Text('当前课表没有课程。'));
    }
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: _groups.length,
          itemBuilder: (context, index) {
            final group = _groups[index];
            return ListTile(
              title: Text(group.name),
              trailing: GestureDetector(
                onTap: () => _editGroupColor(group),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: HexColor(group.currentHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
              onTap: () => _editGroupColor(group),
            );
          },
        ),
      ),
      if (_pendingChanges.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyCustomChanges,
              child: Text('确认应用（${_pendingChanges.length} 门课变更）'),
            ),
          ),
        ),
    ]);
  }
}
