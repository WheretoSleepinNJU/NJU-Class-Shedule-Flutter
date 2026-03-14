import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../../../Components/Dialog.dart';
import '../../../Components/Toast.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/PrototypePalette.dart';
import '../../../Utils/States/MainState.dart';
import '../../../core/widget_data/utils/widget_refresh_helper.dart';
import '../../../generated/l10n.dart';

class CourseActivatedDialog extends StatefulWidget {
  const CourseActivatedDialog({
    Key? key,
    required this.course,
    required this.isActive,
  }) : super(key: key);

  final Course course;
  final bool isActive;

  static Future<void> show(
    BuildContext context,
    Course course,
    bool isActive,
  ) {
    return showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      barrierLabel: 'course-activated-dialog',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (BuildContext context, _, __) {
        return CourseActivatedDialog(course: course, isActive: isActive);
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<CourseActivatedDialog> createState() => _CourseActivatedDialogState();
}

class _CourseActivatedDialogState extends State<CourseActivatedDialog> {
  static const List<String> _weekdayLabels = <String>[
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _locationController;

  late final List<int> _originalWeeks;
  late final _WeekPattern _originalWeekPattern;
  late final String _originalName;
  late final String _originalTeacher;
  late final String _originalLocation;
  late final int _originalWeekday;
  late final int _originalWeekStart;
  late final int _originalWeekEnd;
  late final int _originalSectionStart;
  late final int _originalSectionEnd;

  late int _selectedWeekday;
  late int _weekStart;
  late int _weekEnd;
  late int _sectionStart;
  late int _sectionEnd;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name ?? '');
    _teacherController =
        TextEditingController(text: widget.course.teacher ?? '');
    _locationController =
        TextEditingController(text: widget.course.classroom ?? '');

    _originalWeeks = _parseWeeks(widget.course.weeks);
    _originalWeekPattern = _detectWeekPattern(_originalWeeks);
    _originalName = (widget.course.name ?? '').trim();
    _originalTeacher = (widget.course.teacher ?? '').trim();
    _originalLocation = (widget.course.classroom ?? '').trim();
    _originalWeekday = _normalizeWeekday(widget.course.weekTime ?? 1);
    _originalWeekStart = _originalWeeks.first;
    _originalWeekEnd = _originalWeeks.last;
    _originalSectionStart = _normalizeSection(widget.course.startTime ?? 1);
    _originalSectionEnd = _normalizeSection(
      (widget.course.startTime ?? 1) + (widget.course.timeCount ?? 0),
    );

    _selectedWeekday = _originalWeekday;
    _weekStart = _originalWeekStart;
    _weekEnd = _originalWeekEnd;
    _sectionStart = _originalSectionStart;
    _sectionEnd = _originalSectionEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _nameController.text.trim() != _originalName ||
        _teacherController.text.trim() != _originalTeacher ||
        _locationController.text.trim() != _originalLocation ||
        _selectedWeekday != _originalWeekday ||
        _weekStart != _originalWeekStart ||
        _weekEnd != _originalWeekEnd ||
        _sectionStart != _originalSectionStart ||
        _sectionEnd != _originalSectionEnd;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleCloseRequested,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: const Color(0x66000000)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(18, 24, 18, 24 + bottomInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 340,
                    maxHeight: 650,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFAF2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color:
                              const Color(0xFF3B2A13).withValues(alpha: 0.15),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                          child: Column(
                            children: <Widget>[
                              _buildHeader(context),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      _buildWeekdayRow(),
                                      const SizedBox(height: 12),
                                      _buildWeekRangeRow(),
                                      const SizedBox(height: 12),
                                      _buildSectionRangeRow(),
                                      const SizedBox(height: 12),
                                      _buildTeacherRow(context),
                                      const SizedBox(height: 12),
                                      _buildLocationRow(context),
                                      const SizedBox(height: 18),
                                      _buildTodoSection(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isSaving)
                          Positioned.fill(
                            child: AbsorbPointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      DuckPalette.page.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: DuckPalette.duckYellow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        _HeaderIconButton(
          icon: Icons.close_rounded,
          color: DuckPalette.textMuted,
          onTap: _handleCloseRequested,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: DuckPalette.textMain,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '课程名称',
                hintStyle: TextStyle(
                  color: DuckPalette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFF05F57),
          onTap: _handleDeletePressed,
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return _FieldShell(
      icon: Icons.calendar_month_rounded,
      iconColor: const Color(0xFFF2A800),
      child: Row(
        children: <Widget>[
          const Text(
            '星期',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DuckPalette.textMain,
            ),
          ),
          const Spacer(),
          _CapsuleButton(
            label: _weekdayLabels[_selectedWeekday - 1],
            minWidth: 46,
            onTap: _pickWeekday,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRangeRow() {
    return _FieldShell(
      icon: Icons.date_range_rounded,
      iconColor: const Color(0xFFFF9A3D),
      child: Row(
        children: <Widget>[
          const Text(
            '第',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DuckPalette.textMain,
            ),
          ),
          const SizedBox(width: 8),
          _CapsuleButton(
            label: '$_weekStart',
            onTap: _pickWeekRange,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DuckPalette.textMain,
              ),
            ),
          ),
          _CapsuleButton(
            label: '$_weekEnd',
            onTap: _pickWeekRange,
          ),
          const SizedBox(width: 8),
          const Text(
            '周',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DuckPalette.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRangeRow() {
    return _FieldShell(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF66B3FF),
      child: Row(
        children: <Widget>[
          const Text(
            '第',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DuckPalette.textMain,
            ),
          ),
          const SizedBox(width: 8),
          _CapsuleButton(
            label: '$_sectionStart',
            onTap: _pickSectionRange,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DuckPalette.textMain,
              ),
            ),
          ),
          _CapsuleButton(
            label: '$_sectionEnd',
            onTap: _pickSectionRange,
          ),
          const SizedBox(width: 8),
          const Text(
            '节',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DuckPalette.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherRow(BuildContext context) {
    return _FieldShell(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF89A6FF),
      child: _InlineInput(
        controller: _teacherController,
        hintText: S.of(context).class_teacher,
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    return _FieldShell(
      icon: Icons.domain_rounded,
      iconColor: const Color(0xFF58C7A8),
      child: _InlineInput(
        controller: _locationController,
        hintText: S.of(context).unknown_place,
      ),
    );
  }

  Widget _buildTodoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '待办',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: DuckPalette.textMain,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '暂无关联待办',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DuckPalette.textMain,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '--',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DuckPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleCloseRequested() async {
    FocusScope.of(context).unfocus();
    if (_isSaving) {
      return;
    }
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final _CloseDecision? decision = await _showCloseConfirmDialog();
    if (!mounted || decision == null) {
      return;
    }
    switch (decision) {
      case _CloseDecision.continueEditing:
        return;
      case _CloseDecision.discard:
        Navigator.of(context).pop();
        return;
      case _CloseDecision.save:
        await _saveAndClose();
        return;
    }
  }

  Future<void> _handleDeletePressed() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || widget.course.id == null) {
      return;
    }
    final bool confirmed = await _showDeleteConfirmDialog();
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final CourseProvider courseProvider = CourseProvider();
      await courseProvider.delete(widget.course.id!);
      await WidgetRefreshHelper.refreshAfterCourseDeleted();
      ScopedModel.of<MainStateModel>(context).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        Toast.showToast('删除失败，请稍后重试', context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveAndClose() async {
    final String? validationMessage = await _validateDraft();
    if (validationMessage != null) {
      if (mounted) {
        Toast.showToast(validationMessage, context);
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final CourseProvider courseProvider = CourseProvider();
      widget.course.name = _nameController.text.trim();
      widget.course.teacher = _emptyToNull(_teacherController.text);
      widget.course.classroom = _emptyToNull(_locationController.text);
      widget.course.weekTime = _selectedWeekday;
      widget.course.startTime = _sectionStart;
      widget.course.timeCount = _sectionEnd - _sectionStart;
      widget.course.weeks = jsonEncode(_buildWeeksForSave());
      await courseProvider.update(widget.course);
      await WidgetRefreshHelper.refreshAfterCourseUpdated();
      ScopedModel.of<MainStateModel>(context).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        Toast.showToast('保存失败，请稍后重试', context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _validateDraft() async {
    if (_nameController.text.trim().isEmpty) {
      return '请输入课程名称';
    }
    if (_weekEnd < _weekStart) {
      return '课程结束周数应大于起始周数';
    }
    if (_sectionEnd < _sectionStart) {
      return '课程结束节数应大于起始节数';
    }

    final Course? conflictCourse = await _findConflictCourse();
    if (conflictCourse != null) {
      return '与「${conflictCourse.name ?? '未命名课程'}」时间冲突，请调整时间';
    }
    return null;
  }

  Future<Course?> _findConflictCourse() async {
    final int? tableId = widget.course.tableId;
    if (tableId == null) {
      return null;
    }
    final CourseProvider courseProvider = CourseProvider();
    final List rows = await courseProvider.getAllCourses(tableId);
    final Set<int> draftWeeks = _buildWeeksForSave().toSet();

    for (final dynamic row in rows) {
      final Map<String, dynamic> map =
          Map<String, dynamic>.from(row as Map<dynamic, dynamic>);
      final Course otherCourse = Course.fromMap(map);
      if (otherCourse.id == widget.course.id) {
        continue;
      }
      if ((otherCourse.weekTime ?? -1) != _selectedWeekday) {
        continue;
      }

      final List<int> otherWeeks = _parseWeeks(otherCourse.weeks);
      final bool hasWeekOverlap =
          otherWeeks.any((int week) => draftWeeks.contains(week));
      if (!hasWeekOverlap) {
        continue;
      }

      final int otherStart = otherCourse.startTime ?? 0;
      final int otherEnd = otherStart + (otherCourse.timeCount ?? 0);
      if (otherStart <= 0 || otherEnd <= 0) {
        continue;
      }
      if (_rangesOverlap(_sectionStart, _sectionEnd, otherStart, otherEnd)) {
        return otherCourse;
      }
    }
    return null;
  }

  Future<void> _pickWeekday() async {
    FocusScope.of(context).unfocus();
    final int? selectedDay = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _PickerSheet(
          title: '选择星期',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(_weekdayLabels.length, (int index) {
              final int day = index + 1;
              final bool selected = day == _selectedWeekday;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(day),
                child: Container(
                  width: 58,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? DuckPalette.duckYellowSoft
                        : DuckPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? DuckPalette.duckYellow
                          : DuckPalette.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? DuckPalette.textMain
                          : DuckPalette.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );

    if (selectedDay != null && mounted) {
      setState(() {
        _selectedWeekday = selectedDay;
      });
    }
  }

  Future<void> _pickWeekRange() async {
    FocusScope.of(context).unfocus();
    final _RangeSelection? result = await _showRangeSheet(
      title: '选择周次',
      startLabel: '开始周',
      endLabel: '结束周',
      unit: '周',
      maxValue: math.max(math.max(_weekEnd, _originalWeekEnd), 25),
      initialStart: _weekStart,
      initialEnd: _weekEnd,
    );
    if (result != null && mounted) {
      setState(() {
        _weekStart = result.start;
        _weekEnd = result.end;
      });
    }
  }

  Future<void> _pickSectionRange() async {
    FocusScope.of(context).unfocus();
    final _RangeSelection? result = await _showRangeSheet(
      title: '选择节次',
      startLabel: '开始节',
      endLabel: '结束节',
      unit: '节',
      maxValue: 13,
      initialStart: _sectionStart,
      initialEnd: _sectionEnd,
    );
    if (result != null && mounted) {
      setState(() {
        _sectionStart = result.start;
        _sectionEnd = result.end;
      });
    }
  }

  Future<_RangeSelection?> _showRangeSheet({
    required String title,
    required String startLabel,
    required String endLabel,
    required String unit,
    required int maxValue,
    required int initialStart,
    required int initialEnd,
  }) {
    return showModalBottomSheet<_RangeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        int start = initialStart;
        int end = initialEnd;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _PickerSheet(
              title: title,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _DropdownField(
                          label: startLabel,
                          value: start,
                          maxValue: maxValue,
                          unit: unit,
                          onChanged: (int value) {
                            setModalState(() {
                              start = value;
                              if (end < start) {
                                end = start;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: endLabel,
                          value: end,
                          maxValue: maxValue,
                          unit: unit,
                          minValue: start,
                          onChanged: (int value) {
                            setModalState(() {
                              end = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DuckPalette.duckYellow,
                        foregroundColor: DuckPalette.textMain,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(
                          _RangeSelection(start: start, end: end),
                        );
                      },
                      child: const Text(
                        '确定',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<_CloseDecision?> _showCloseConfirmDialog() {
    return showDialog<_CloseDecision>(
      context: context,
      builder: (BuildContext dialogContext) {
        return MDialog(
          '保存修改？',
          const Text('你修改了课程信息，关闭前要保存吗？'),
          overrideActions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_CloseDecision.continueEditing);
              },
              child: const Text(
                '继续编辑',
                style: TextStyle(color: DuckPalette.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_CloseDecision.discard);
              },
              child: const Text(
                '放弃',
                style: TextStyle(color: Color(0xFFF05F57)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_CloseDecision.save);
              },
              child: const Text(
                '保存',
                style: TextStyle(color: DuckPalette.textMain),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return MDialog(
          S.of(context).delete_class_dialog_title,
          Text(
            S.of(context).delete_class_dialog_content(
                  _nameController.text.trim().isEmpty
                      ? (widget.course.name ?? '该课程')
                      : _nameController.text.trim(),
                ),
          ),
          widgetCancelAction: () {
            Navigator.of(dialogContext).pop(false);
          },
          widgetOKAction: () {
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
    );
    return result ?? false;
  }

  List<int> _buildWeeksForSave() {
    final bool weekRangeChanged =
        _weekStart != _originalWeekStart || _weekEnd != _originalWeekEnd;
    if (!weekRangeChanged) {
      return List<int>.from(_originalWeeks);
    }

    switch (_originalWeekPattern) {
      case _WeekPattern.odd:
      case _WeekPattern.even:
        final bool targetOdd = _originalWeekPattern == _WeekPattern.odd;
        int start = _weekStart;
        while (start <= _weekEnd && start.isOdd != targetOdd) {
          start += 1;
        }
        if (start > _weekEnd) {
          start = _weekStart;
        }
        return <int>[
          for (int week = start; week <= _weekEnd; week += 2) week,
        ];
      case _WeekPattern.full:
      case _WeekPattern.custom:
        return <int>[
          for (int week = _weekStart; week <= _weekEnd; week += 1) week,
        ];
    }
  }

  List<int> _parseWeeks(String? rawWeeks) {
    if (rawWeeks == null || rawWeeks.trim().isEmpty) {
      return <int>[1];
    }
    try {
      final List<dynamic> decoded = jsonDecode(rawWeeks) as List<dynamic>;
      final List<int> weeks = decoded
          .map((dynamic item) => int.tryParse(item.toString()) ?? 0)
          .where((int item) => item > 0)
          .toList()
        ..sort();
      return weeks.isEmpty ? <int>[1] : weeks;
    } catch (_) {
      return <int>[1];
    }
  }

  _WeekPattern _detectWeekPattern(List<int> weeks) {
    if (weeks.length <= 1) {
      return _WeekPattern.full;
    }
    final List<int> diffs = <int>[
      for (int i = 1; i < weeks.length; i += 1) weeks[i] - weeks[i - 1],
    ];
    final bool isFull = diffs.every((int diff) => diff == 1);
    if (isFull) {
      return _WeekPattern.full;
    }
    final bool isAlternating = diffs.every((int diff) => diff == 2);
    if (isAlternating) {
      return weeks.first.isOdd ? _WeekPattern.odd : _WeekPattern.even;
    }
    return _WeekPattern.custom;
  }

  int _normalizeWeekday(int value) {
    return value.clamp(1, 7);
  }

  int _normalizeSection(int value) {
    return value.clamp(1, 13);
  }

  bool _rangesOverlap(int startA, int endA, int startB, int endB) {
    return startA <= endB && startB <= endA;
  }

  String? _emptyToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E9D4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CapsuleButton extends StatelessWidget {
  const _CapsuleButton({
    required this.label,
    required this.onTap,
    this.minWidth = 50,
  });

  final String label;
  final VoidCallback onTap;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: DuckPalette.textMain,
          ),
        ),
      ),
    );
  }
}

class _InlineInput extends StatelessWidget {
  const _InlineInput({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: DuckPalette.textMain,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: DuckPalette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF2),
          borderRadius: BorderRadius.circular(26),
          boxShadow: DuckPalette.softShadow(0.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: DuckPalette.textMain,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    required this.onChanged,
    this.minValue = 1,
  });

  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DuckPalette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(18),
              items: <DropdownMenuItem<int>>[
                for (int number = minValue; number <= maxValue; number += 1)
                  DropdownMenuItem<int>(
                    value: number,
                    child: Text('$number $unit'),
                  ),
              ],
              onChanged: (int? nextValue) {
                if (nextValue != null) {
                  onChanged(nextValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeSelection {
  const _RangeSelection({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}

enum _CloseDecision {
  continueEditing,
  discard,
  save,
}

enum _WeekPattern {
  full,
  odd,
  even,
  custom,
}
