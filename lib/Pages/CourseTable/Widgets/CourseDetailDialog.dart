import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../Components/Dialog.dart';
import '../../../Components/Toast.dart';
import '../../../generated/l10n.dart';

class CourseDetailDialog extends StatelessWidget {
  final VoidCallback? onPressed, onEdit;
  final Course course;
  final List<Course>? meetings;
  final bool isActive;
  final List<Map> classTimeList;
  const CourseDetailDialog(
    this.course,
    this.isActive,
    this.onPressed, {
    super.key,
    this.onEdit,
    this.meetings,
    this.classTimeList = Constant.CLASS_TIME_LIST,
  });
  @override
  Widget build(BuildContext context) => CourseDetailsDialog(
    courses: [course],
    groups: [
      meetings ?? [course],
    ],
    isActive: (_) => isActive,
    onClose: onPressed,
    onEdit: onEdit == null ? null : (_) => onEdit!(),
    classTimeList: classTimeList,
  );
}

class CourseDetailsDialog extends StatelessWidget {
  final List<Course> courses;
  final List<List<Course>>? groups;
  final bool Function(Course) isActive;
  final VoidCallback? onClose;
  final ValueChanged<Course>? onEdit;
  final List<Map> classTimeList;
  const CourseDetailsDialog({
    super.key,
    required this.courses,
    this.groups,
    required this.isActive,
    this.onClose,
    this.onEdit,
    this.classTimeList = Constant.CLASS_TIME_LIST,
  });
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: MDialog.maxTextScale,
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              backgroundColor: Colors.transparent,
              textStyle: theme.textTheme.labelLarge,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).vertical -
                    48,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose ?? () => Navigator.of(context).pop(),
                excludeFromSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        key: const ValueKey('course-detail-scroll'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < courses.length; i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {},
                                excludeFromSemantics: true,
                                child: CourseDetailCard(
                                  course: courses[i],
                                  meetings: groups?[i],
                                  isActive: isActive(courses[i]),
                                  classTimeList: classTimeList,
                                  onEdit:
                                      onEdit == null
                                          ? null
                                          : () => onEdit!(courses[i]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        S.of(context).tap_blank_to_close,
                        key: const ValueKey('course-detail-dismiss-hint'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class CourseDetailCard extends StatelessWidget {
  final Course course;
  final List<Course>? meetings;
  final bool isActive;
  final VoidCallback? onEdit;
  final List<Map> classTimeList;
  const CourseDetailCard({
    super.key,
    required this.course,
    this.meetings,
    required this.isActive,
    this.onEdit,
    this.classTimeList = Constant.CLASS_TIME_LIST,
  });

  String _weeks(BuildContext context, Course meeting) {
    final weeks = meeting.weekNumbers, s = S.of(context);
    if (weeks.isEmpty) return s.weeks_pending;
    if (weeks.length == 1) return s.week(weeks.first);
    final range = s.week_duration(weeks.first, weeks.last);
    if (List.generate(
      weeks.length,
      (i) => weeks[i] == weeks.first + i,
    ).every((v) => v)) {
      return range;
    }
    if (List.generate(
      weeks.length,
      (i) => weeks[i] == weeks.first + 2 * i,
    ).every((v) => v)) {
      return '$range ${weeks.first.isOdd ? s.single_week : s.double_week}';
    }
    return weeks.map((w) => s.week(w)).join('、');
  }

  String _time(BuildContext context, Course meeting) {
    final start = meeting.startTime ?? 0,
        end = start + (meeting.timeCount ?? 0),
        day = meeting.weekTime ?? 0;
    if (day == 0 || start == 0) return S.of(context).free_time;
    final period =
        start == end
            ? S.of(context).class_single('$start')
            : S.of(context).class_duration('$start', '$end');
    return [
      if (day >= 1 && day <= 7) Constant.WEEK_WITH_BIAS[day],
      period,
      if (start > 0 && end >= start && end <= classTimeList.length)
        '${classTimeList[start - 1]['start']}-${classTimeList[end - 1]['end']}',
    ].join('  |  ');
  }

  Widget _text(BuildContext context, String value, Color color) {
    final style =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final size = style.fontSize ?? 14;
    return SelectableLinkify(
      text: value,
      textScaleFactor: MediaQuery.textScalerOf(context).scale(size) / size,
      style: style.copyWith(height: 1.5, color: color),
      linkStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      options: const LinkifyOptions(humanize: false),
      onOpen: (link) async {
        final uri = Uri.tryParse(link.url);
        if (uri == null ||
            !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            Toast.showToast(S.of(context).network_error_toast, context);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        scheme = theme.colorScheme,
        s = S.of(context);
    final slots = meetings ?? [course];
    final commonInfo = slots.every(
      (c) => (c.info?.trim() ?? '') == (course.info?.trim() ?? ''),
    );
    String value(String? text) =>
        (text?.trim().isEmpty ?? true) ? s.not_filled : text!.trim();
    final source = switch (course.importType) {
      Constant.ADD_BY_IMPORT => s.import_auto,
      Constant.ADD_BY_LECTURE => s.import_from_lecture,
      _ => s.import_manually,
    };
    return Material(
      key: ValueKey('course-detail-card-${course.id ?? course.name}'),
      color: Color.alphaBlend(
        scheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.08 : 0.035,
        ),
        scheme.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.primary.withValues(alpha: .16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    course.name ?? '',
                    softWrap: true,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    key: ValueKey('edit-course-${course.id ?? course.name}'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: .07),
                      textStyle: theme.textTheme.labelLarge,
                      minimumSize: const Size(52, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: Text(s.edit, maxLines: 1, softWrap: false),
                  ),
                ],
              ],
            ),
            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text(
                  s.not_this_week,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (slots.length > 1)
              Text(
                s.meetings_count(slots.length),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            const SizedBox(height: 12),
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const Divider(height: 24),
              if (slots.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    s.meeting_number(i + 1),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              Text(
                _weeks(context, slots[i]),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              _text(context, _time(context, slots[i]), scheme.onSurfaceVariant),
              const SizedBox(height: 6),
              _text(
                context,
                '${s.class_room}：${value(slots[i].classroom)}',
                scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              _text(
                context,
                '${s.class_teacher}：${value(slots[i].teacher)}',
                scheme.onSurfaceVariant,
              ),
              if (!commonInfo &&
                  (slots[i].info?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                _text(context, slots[i].info!.trim(), scheme.onSurfaceVariant),
              ],
            ],
            if (commonInfo && (course.info?.trim().isNotEmpty ?? false)) ...[
              const Divider(height: 24),
              _text(context, course.info!.trim(), scheme.onSurfaceVariant),
            ],
            const SizedBox(height: 12),
            Text(
              '${s.add_method}：$source',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
