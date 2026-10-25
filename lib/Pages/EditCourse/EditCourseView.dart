import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/CourseModel.dart';
import '../../Components/Dialog.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/Config.dart';
import '../../Resources/Constant.dart';
import '../../generated/l10n.dart';
import 'CourseMeetingInput.dart';
import 'EditCoursePresenter.dart';

class EditCourseView extends StatefulWidget {
  final Course? course;
  final List<Course>? meetings;
  final int? tableId;
  final List<Map>? classTimeList;
  final EditCoursePresenter? presenter;
  const EditCourseView({
    super.key,
    this.course,
    this.meetings,
    this.tableId,
    this.classTimeList,
    this.presenter,
  });
  @override
  State<EditCourseView> createState() => _EditCourseViewState();
}

class _MeetingDraft {
  final int key;
  final Course? original;
  final TextEditingController teacher, classroom;
  final Set<int> weeks;
  int day, start, end;
  bool pending, expanded, weekError = false;
  _MeetingDraft(this.key, {this.original, _MeetingDraft? copy})
    : teacher = TextEditingController(
        text: original?.teacher ?? copy?.teacher.text,
      ),
      classroom = TextEditingController(
        text: original?.classroom ?? copy?.classroom.text,
      ),
      weeks =
          original?.weekNumbers.toSet() ??
          copy?.weeks.toSet() ??
          {for (var i = 1; i <= Config.MAX_WEEKS; i++) i},
      day =
          original == null
              ? (copy == null ? 1 : copy.day % 7 + 1)
              : (original.weekTime ?? 1).clamp(1, 7),
      start = math.max(1, original?.startTime ?? copy?.start ?? 1),
      end = math.max(
        1,
        original == null
            ? copy?.end ?? 1
            : (original.startTime ?? 1) + (original.timeCount ?? 0),
      ),
      pending = original?.weekTime == 0,
      expanded = key == 0 || original == null;
  CourseMeetingInput get input => CourseMeetingInput(
    original: original,
    teacher: teacher.text,
    classroom: classroom.text,
    weeks: weeks.toList(),
    weekTime: day,
    startTime: start,
    endTime: end,
    timePending: pending,
  );
  void dispose() {
    teacher.dispose();
    classroom.dispose();
  }
}

class _EditCourseViewState extends State<EditCourseView> {
  final _form = GlobalKey<FormState>();
  final _slots = <_MeetingDraft>[], _allDrafts = <_MeetingDraft>[];
  late final TextEditingController _name, _info;
  late final EditCoursePresenter _presenter;
  late final List<Course> _originals;
  late List<Map> _times;
  int? _tableId;
  int _serial = 0;
  bool _saving = false, _deleting = false, _loadFailed = false;
  bool get _busy => _saving || _deleting;
  bool get _creating => widget.course == null;

  @override
  void initState() {
    super.initState();
    _presenter = widget.presenter ?? EditCoursePresenter();
    _originals =
        widget.meetings ?? (widget.course == null ? [] : [widget.course!]);
    _name = TextEditingController(text: widget.course?.name);
    _info = TextEditingController(text: widget.course?.info);
    _times = widget.classTimeList ?? Constant.CLASS_TIME_LIST;
    _tableId = widget.course?.tableId ?? widget.tableId;
    for (final original in _originals) {
      _addDraft(original: original);
    }
    if (_slots.isEmpty) _addDraft();
    if (_tableId == null || _creating && widget.classTimeList == null) {
      _loadTable();
    }
  }

  Future<void> _loadTable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tables = CourseTableProvider();
      var selected = _tableId ?? prefs.getInt('tableId');
      final all = await tables.getAllCourseTable();
      if (!all.any((t) => t['id'] == selected)) {
        selected =
            all.isEmpty
                ? (await tables.insert(
                  CourseTable(Config.default_class_table),
                )).id!
                : all.first['id'] as int;
        await prefs.setInt('tableId', selected);
      }
      final times =
          widget.classTimeList ?? await tables.getClassTimeList(selected!);
      if (mounted) {
        setState(() {
          _tableId = selected;
          _times = times;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _addDraft({Course? original}) {
    final draft = _MeetingDraft(
      _serial++,
      original: original,
      copy: original == null && _slots.isNotEmpty ? _slots.last : null,
    );
    _slots.add(draft);
    _allDrafts.add(draft);
  }

  @override
  void dispose() {
    _name.dispose();
    _info.dispose();
    for (final slot in _allDrafts) {
      slot.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _tableId == null) return;
    final valid = _form.currentState!.validate();
    setState(() {
      for (final s in _slots) {
        s.weekError = s.weeks.isEmpty;
      }
    });
    if (!valid || _slots.any((s) => !s.input.isValid)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    var saved = false;
    try {
      saved = await _presenter.saveMeetings(
        originals: _originals,
        tableId: _tableId!,
        name: _name.text,
        info: _info.text,
        updateInfo:
            _creating ||
            _info.text.trim() != (widget.course?.info?.trim() ?? ''),
        meetings: _slots.map((s) => s.input).toList(),
      );
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).save_failed)));
    }
  }

  Future<void> _delete() async {
    if (_busy || _creating) return;
    FocusScope.of(context).unfocus();
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => MDialog(
            s.delete_class_dialog_title,
            Text(
              '${s.delete_class_dialog_content(widget.course!.name ?? '')}\n\n${s.delete_all_meetings(_originals.length)}',
            ),
            overrideActions: [
              TextButton(
                key: const ValueKey('cancel-course-deletion'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(s.cancel),
              ),
              TextButton(
                key: const ValueKey('confirm-course-deletion'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(s.delete_class_dialog_title),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    var deleted = false;
    try {
      deleted = await _presenter.delete(_originals);
    } catch (_) {
      deleted = false;
    }
    if (!mounted) return;
    setState(() => _deleting = false);
    if (deleted) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.delete_failed)));
    }
  }

  String _period(int number) {
    final label = S.of(context).class_single('$number');
    if (number > _times.length) return label;
    return '$label · ${_times[number - 1]['start']}-${_times[number - 1]['end']}';
  }

  String _key(_MeetingDraft slot, String legacy) =>
      identical(slot, _slots.first) ? legacy : 'slot-${slot.key}-$legacy';

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          required
              ? (value) =>
                  (value?.trim().isEmpty ?? true)
                      ? S.of(context).class_name_empty
                      : null
              : null,
    ),
  );

  Widget _meeting(_MeetingDraft slot, int index) {
    final s = S.of(context), theme = Theme.of(context);
    final maxWeeks = math.max(
      Config.MAX_WEEKS,
      slot.weeks.isEmpty ? 0 : slot.weeks.reduce(math.max),
    );
    final maxClasses = math.max(_times.length, math.max(slot.start, slot.end));
    final summary =
        slot.pending
            ? s.time_pending
            : '${Constant.WEEK_WITH_BIAS[slot.day]} · ${s.class_duration('${slot.start}', '${slot.end}')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: ValueKey('course-slot-${slot.key}'),
          initiallyExpanded: slot.expanded,
          onExpansionChanged: (value) => setState(() => slot.expanded = value),
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            s.meeting_number(index + 1),
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(summary, style: theme.textTheme.bodySmall),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_slots.length > 1)
                IconButton(
                  key: ValueKey('remove-slot-${slot.key}'),
                  tooltip: s.remove_meeting,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed:
                      _saving
                          ? null
                          : () => setState(() => _slots.remove(slot)),
                ),
              Icon(
                slot.expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
            ],
          ),
          children: [
            const SizedBox(height: 12),
            _field(
              _key(slot, 'edit-course-teacher'),
              slot.teacher,
              s.class_teacher,
            ),
            _field(
              _key(slot, 'edit-course-classroom'),
              slot.classroom,
              s.class_room,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(s.course_weeks, style: theme.textTheme.titleSmall),
            ),
            Wrap(
              spacing: 4,
              children: [
                for (final option in [
                  s.select_all,
                  s.single_week,
                  s.double_week,
                  s.clear_selection,
                ])
                  TextButton(
                    onPressed:
                        () => setState(() {
                          slot.weeks.clear();
                          if (option != s.clear_selection) {
                            slot.weeks.addAll(
                              List.generate(maxWeeks, (i) => i + 1).where(
                                (w) =>
                                    option == s.select_all ||
                                    (option == s.single_week
                                        ? w.isOdd
                                        : w.isEven),
                              ),
                            );
                          }
                          slot.weekError = slot.weeks.isEmpty;
                        }),
                    child: Text(option),
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(maxWeeks, (i) {
                final week = i + 1;
                return SizedBox(
                  width: math.max(
                    48,
                    MediaQuery.textScalerOf(context).scale(14) * 2 + 16,
                  ),
                  child: FilterChip(
                    key: ValueKey(_key(slot, 'edit-week-$week')),
                    showCheckmark: false,
                    labelPadding: EdgeInsets.zero,
                    label: Center(child: Text('$week')),
                    selected: slot.weeks.contains(week),
                    onSelected:
                        (selected) => setState(() {
                          selected
                              ? slot.weeks.add(week)
                              : slot.weeks.remove(week);
                          slot.weekError = slot.weeks.isEmpty;
                        }),
                  ),
                );
              }),
            ),
            if (slot.weekError)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    s.select_weeks_required,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(s.free_or_pending_time),
              value: slot.pending,
              onChanged: (value) => setState(() => slot.pending = value),
            ),
            if (!slot.pending) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(_key(slot, 'edit-day-${slot.day}')),
                initialValue: slot.day,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.week_day,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(Constant.WEEK_WITH_BIAS[i + 1]),
                  ),
                ),
                onChanged: (v) => setState(() => slot.day = v!),
              ),
              const SizedBox(height: 16),
              for (final start in [true, false]) ...[
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    _key(
                      slot,
                      'edit-${start ? 'start' : 'end'}-${start ? slot.start : slot.end}',
                    ),
                  ),
                  initialValue: start ? slot.start : slot.end,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: start ? s.start_class : s.end_class,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(
                    maxClasses,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        _period(i + 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  onChanged:
                      (v) => setState(() {
                        if (start) {
                          slot.start = v!;
                          slot.end = math.max(slot.start, slot.end);
                        } else {
                          slot.end = v!;
                          slot.start = math.min(slot.start, slot.end);
                        }
                      }),
                ),
                if (start) const SizedBox(height: 16),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 2,
    child: Builder(builder: _buildPage),
  );
  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context), s = S.of(context);
    final resize = Platform.operatingSystem != 'ohos';
    final buttons = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      backgroundColor: Colors.transparent,
      textStyle: theme.textTheme.labelLarge,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    return TextButtonTheme(
      data: TextButtonThemeData(style: buttons),
      child: PopScope(
        canPop: !_busy,
        child: Scaffold(
          resizeToAvoidBottomInset: resize,
          appBar: AppBar(
            title: Text(_creating ? s.add_manually_title : s.edit_course),
            actions: [
              TextButton(
                key: const ValueKey('save-course'),
                onPressed: _busy || _tableId == null ? null : _save,
                child:
                    _saving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(_creating ? s.add_class : s.save),
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar:
              _creating
                  ? null
                  : SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: OutlinedButton.icon(
                      key: const ValueKey('delete-course'),
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: .4),
                        ),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon:
                          _deleting
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.delete_outline, size: 20),
                      label: Text(s.delete_class_dialog_title),
                    ),
                  ),
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  24 + (resize ? 0 : MediaQuery.viewInsetsOf(context).bottom),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _field(
                    'edit-course-name',
                    _name,
                    s.class_name,
                    required: true,
                  ),
                  _field('edit-course-info', _info, s.class_info),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.course_meetings,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('add-course-slot'),
                        onPressed:
                            _busy ? null : () => setState(() => _addDraft()),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(s.add_meeting),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _slots.length; i++)
                    _meeting(_slots[i], i),
                  if (_loadFailed)
                    Text(
                      s.save_failed,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
