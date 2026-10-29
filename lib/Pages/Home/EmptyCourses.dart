import 'package:flutter/material.dart';
import '../../AdaptiveUI/adaptive_ui.dart';
import '../../generated/l10n.dart';

class EmptyCourses extends StatelessWidget {
  const EmptyCourses({super.key, required this.onAdd, required this.onImport});
  final VoidCallback onAdd, onImport;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AdaptiveCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 40),
              const SizedBox(height: 16),
              Text(
                s.home_empty_title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(s.home_empty_message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  AdaptiveButton.filled(
                    onPressed: onImport,
                    child: Text(s.import_title),
                  ),
                  AdaptiveButton.text(
                    onPressed: onAdd,
                    child: Text(s.import_manually_title),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
