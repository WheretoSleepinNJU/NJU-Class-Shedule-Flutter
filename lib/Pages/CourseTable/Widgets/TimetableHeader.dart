import 'package:flutter/material.dart';
import '../../../AdaptiveUI/adaptive_ui.dart';
import 'package:intl/intl.dart';

import '../../../Resources/Constant.dart';
import '../../../generated/l10n.dart';

class TimetableHeader extends StatelessWidget implements AdaptiveNativeTitle {
  const TimetableHeader({
    super.key,
    required this.displayedWeek,
    required this.currentWeek,
    required this.date,
    required this.onTap,
    this.foregroundColor,
  });

  final int displayedWeek;
  final int currentWeek;
  final DateTime date;
  final VoidCallback onTap;
  final Color? foregroundColor;

  static double toolbarHeight(TextScaler scaler) =>
      kToolbarHeight * (scaler.clamp(maxScaleFactor: 1.4).scale(14) / 14);

  @override
  NativeTitleContent nativeTitleContent(BuildContext context) {
    final s = S.of(context);
    final status = currentWeek < 1
        ? s.not_open
        : currentWeek != displayedWeek
        ? s.not_this_week
        : '';
    final week = '${s.week(displayedWeek)}${status.isEmpty ? '' : ' $status'}';
    return NativeTitleContent(
      title: '${s.app_name}  $week',
      subtitle:
          '${DateFormat('yyyy/MM/dd').format(date)} ${Constant.WEEK_WITH_BIAS[date.weekday]}',
      onTap: onTap,
      foreground: foregroundColor,
      textScale:
          MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.4).scale(14) /
          14,
      semanticLabel:
          '${s.view_week_timetable}，$week，${s.change_week_subtitle}${currentWeek < 1 ? s.not_open : s.week(currentWeek)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    // Preserve the original priority: pre-semester takes precedence over
    // browsing a week other than the actual current week.
    final status =
        currentWeek < 1
            ? s.not_open
            : currentWeek != displayedWeek
            ? s.not_this_week
            : '';
    final weekLabel =
        '${s.week(displayedWeek)}${status.isEmpty ? '' : ' $status'}';
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: Semantics(
        button: true,
        label:
            '${s.view_week_timetable}，$weekLabel，'
            '${s.change_week_subtitle}${currentWeek < 1 ? s.not_open : s.week(currentWeek)}',
        child: InkWell(
          key: const ValueKey('timetable-week-menu'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${s.app_name}  $weekLabel',
                          key: const ValueKey('timetable-main-title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_drop_down, size: 22, color: color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('yyyy/MM/dd').format(date)} '
                  '${Constant.WEEK_WITH_BIAS[date.weekday]}',
                  key: const ValueKey('timetable-date-subtitle'),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: color.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
