import '../../../AdaptiveUI/adaptive_ui.dart';
import 'CourseScheduleText.dart';
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
          child: AdaptiveDialogFrame(
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
                                  onEdit: onEdit == null
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

  Widget _detailLine(
    BuildContext context,
    IconData icon,
    String label,
    String text,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AdaptiveTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              _text(context, text, scheme.onSurface),
            ],
          ),
        ),
      ],
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
    return AdaptiveCard(
      margin: EdgeInsets.zero,
      key: ValueKey('course-detail-card-${course.id ?? course.name}'),
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AdaptiveLayout.cardRadiusOf(context)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  AdaptiveButton.text(
                    key: ValueKey('edit-course-${course.id ?? course.name}'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: .07),
                      textStyle: theme.textTheme.labelLarge,
                      minimumSize: const Size(52, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slots.length > 1) ...[
                      Text(
                        s.meeting_number(i + 1),
                        style: AdaptiveTypography.section.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      CourseScheduleText.weeks(context, slots[i]),
                      style: AdaptiveTypography.body.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _text(
                      context,
                      CourseScheduleText.time(context, slots[i], classTimeList),
                      scheme.onSurface,
                    ),
                    const SizedBox(height: 14),
                    _detailLine(
                      context,
                      Icons.place_outlined,
                      s.class_room,
                      value(slots[i].classroom),
                    ),
                    const SizedBox(height: 10),
                    _detailLine(
                      context,
                      Icons.person_outline_rounded,
                      s.class_teacher,
                      value(slots[i].teacher),
                    ),
                    if (!commonInfo &&
                        (slots[i].info?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 14),
                      _detailLine(
                        context,
                        Icons.notes_rounded,
                        s.class_info,
                        slots[i].info!.trim(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (commonInfo && (course.info?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 16),
              _detailLine(
                context,
                Icons.notes_rounded,
                s.class_info,
                course.info!.trim(),
              ),
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
