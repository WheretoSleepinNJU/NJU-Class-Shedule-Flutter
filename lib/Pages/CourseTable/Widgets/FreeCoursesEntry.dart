import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../AdaptiveUI/adaptive_ui.dart';
import '../../../Utils/ColorUtil.dart';
import '../../../generated/l10n.dart';

/// A fixed header entry, separate from the timetable grid and bottom dock.
class FreeCoursesEntry extends StatelessWidget {
  const FreeCoursesEntry({
    super.key,
    required this.count,
    required this.onTap,
    this.backgroundSeed,
  });

  final int count;
  final String? backgroundSeed;
  final VoidCallback onTap;
  static const _gap = 8.0;

  /// Also consumed by the timetable's fit-to-screen row calculation.
  static double extent(TextScaler scaler) =>
      math.max(40.0, scaler.scale(13) * 1.4 + 10) + _gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = backgroundSeed == null
        ? theme.colorScheme
        : ColorScheme.fromSeed(
            seedColor: HexColor(backgroundSeed!),
            brightness: theme.brightness,
          );
    final container = backgroundSeed == null
        ? scheme.surfaceContainer
        : scheme.primaryContainer;
    final foreground = backgroundSeed == null
        ? scheme.onSurface
        : scheme.onPrimaryContainer;
    final action = backgroundSeed == null
        ? scheme.primary
        : scheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, _gap),
      child: SizedBox(
        height: extent(MediaQuery.textScalerOf(context)) - _gap,
        child: AdaptiveCard(
          color: container,
          borderRadius: BorderRadius.circular(12),
          child: AdaptiveButton.text(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              foregroundColor: foreground,
              backgroundColor: Colors.transparent,
              textStyle: const TextStyle(fontSize: 13, height: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    S.of(context).free_courses_entry(count.toString()),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  S.of(context).free_class_button,
                  style: TextStyle(color: action),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: action),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
