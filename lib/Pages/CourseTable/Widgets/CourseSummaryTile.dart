import 'package:flutter/material.dart';
import '../../../AdaptiveUI/adaptive_ui.dart';
import '../../../Models/CourseModel.dart';
import '../../../Resources/Constant.dart';
import '../../../generated/l10n.dart';
import 'CourseScheduleText.dart';

/// Shared course rhythm for the added list and catalog; no backend branches.
class CourseSummaryTile extends StatelessWidget {
  const CourseSummaryTile({
    super.key,
    required this.meetings,
    required this.onTap,
    this.classTimeList = Constant.CLASS_TIME_LIST,
    this.expanded = false,
  });
  final List<Course> meetings;
  final List<Map> classTimeList;
  final VoidCallback onTap;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final course = meetings.first,
        scheme = Theme.of(context).colorScheme,
        s = S.of(context);
    final teachers = meetings
        .map((c) => c.teacher?.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .join('、');
    final rooms = meetings
        .map((c) => c.classroom?.trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .join(' / ');
    Widget metadata(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.start,
            style: AdaptiveTypography.body.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
    return AdaptivePressable(
      onPressed: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AdaptiveLayout.cardRadiusOf(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.name ?? '',
                  textAlign: TextAlign.start,
                  style: AdaptiveTypography.item.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (teachers.isNotEmpty) teachers,
              s.course_meetings_count(meetings.length),
            ].join(' · '),
            textAlign: TextAlign.start,
            style: AdaptiveTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          metadata(
            Icons.schedule_rounded,
            CourseScheduleText.time(context, course, classTimeList),
          ),
          if (rooms.isNotEmpty) ...[
            const SizedBox(height: 6),
            metadata(Icons.place_outlined, rooms),
          ],
        ],
      ),
    );
  }
}
