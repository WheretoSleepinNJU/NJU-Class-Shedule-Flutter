import '../../../AdaptiveUI/adaptive_ui.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../Resources/Config.dart';
import '../../../generated/l10n.dart';

class WeekSelection {
  const WeekSelection(this.week, {this.changesCurrentWeek = false});

  final int week;
  final bool changesCurrentWeek;
}

Future<WeekSelection?> showWeekPickerSheet(
  BuildContext context, {
  required int currentWeek,
  required int displayedWeek,
}) => showModalBottomSheet<WeekSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder:
      (_) => WeekPickerSheet(
        currentWeek: currentWeek,
        displayedWeek: displayedWeek
      ),
);

class WeekPickerSheet extends StatefulWidget {
  const WeekPickerSheet({
    super.key,
    required this.currentWeek,
    required this.displayedWeek,
  });

  final int currentWeek;
  final int displayedWeek;

  @override
  State<WeekPickerSheet> createState() => _WeekPickerSheetState();
}

class _WeekPickerSheetState extends State<WeekPickerSheet> {
  bool _editingCurrentWeek = false;
  late int _selectedWeek = widget.displayedWeek;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final maxWeek = math.max(
      Config.MAX_WEEKS,
      math.max(widget.currentWeek, widget.displayedWeek),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 2,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editingCurrentWeek
                            ? s.change_week_title
                            : s.view_week_timetable,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdaptiveButton.text(
                      key: const ValueKey('week-picker-mode'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onPressed:
                          () => setState(() {
                            _editingCurrentWeek = !_editingCurrentWeek;
                            _selectedWeek =
                                _editingCurrentWeek
                                    ? math.max(1, widget.currentWeek)
                                    : widget.displayedWeek;
                          }),
                      child: Text(
                        _editingCurrentWeek
                            ? s.view_week_timetable
                            : s.change_week_title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _editingCurrentWeek
                      ? s.change_current_week_hint
                      : '${s.change_week_subtitle}'
                          '${widget.currentWeek < 1 ? s.not_open : s.week(widget.currentWeek)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final columns = (constraints.maxWidth /
                              (56 * math.min(scale, 1.6)))
                          .floor()
                          .clamp(3, 5);
                      return GridView.builder(
                        key: const ValueKey('week-picker-grid'),
                        shrinkWrap: true,
                        itemCount: maxWeek,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 52 * math.min(scale, 1.6),
                        ),
                        itemBuilder: (context, index) {
                          final week = index + 1;
                          final selected = week == _selectedWeek;
                          final current = week == widget.currentWeek;
                          return Semantics(
                            selected: selected,
                            label:
                                '${s.week(week)}${current ? '，${s.this_week}' : ''}',
                            child: Material(
                              color:
                                  selected
                                      ? colors.primary
                                      : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                key: ValueKey('week-picker-$week'),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (_editingCurrentWeek) {
                                    setState(() => _selectedWeek = week);
                                  } else {
                                    Navigator.pop(context, WeekSelection(week));
                                  }
                                },
                                child: Center(
                                  child: Text(
                                    current ? s.this_week : '$week',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          selected || current
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                      color:
                                          selected
                                              ? colors.onPrimary
                                              : colors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_editingCurrentWeek) ...[
                  const SizedBox(height: 16),
                  AdaptiveButton.filled(
                    key: const ValueKey('confirm-current-week'),
                    onPressed:
                        _selectedWeek == widget.currentWeek
                            ? null
                            : () => Navigator.pop(
                              context,
                              WeekSelection(
                                _selectedWeek,
                                changesCurrentWeek: true,
                              ),
                            ),
                    child: Text(s.set_current_week),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
