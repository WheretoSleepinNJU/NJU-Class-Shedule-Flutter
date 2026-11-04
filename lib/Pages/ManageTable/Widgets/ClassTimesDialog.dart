import 'package:flutter/material.dart';

import '../../../Components/Dialog.dart';
import '../../../Resources/Constant.dart';
import '../../../generated/l10n.dart';

class ClassTimesDialog extends StatefulWidget {
  const ClassTimesDialog({super.key, required this.times});

  final List<Map> times;

  @override
  State<ClassTimesDialog> createState() => _ClassTimesDialogState();
}

class _ClassTimesDialogState extends State<ClassTimesDialog> {
  static const _fudanTimes = '''
08:00-08:45
08:55-09:40
09:55-10:40
10:50-11:35
11:45-12:30
13:30-14:15
14:25-15:10
15:25-16:10
16:20-17:05
17:15-18:00
18:30-19:15
19:25-20:10
20:20-21:05''';

  static const _clock = r'(?:[01]\d|2[0-3]):[0-5]\d';
  static final _period = RegExp('^($_clock)\\s*-\\s*($_clock)\$');

  late final _controller = TextEditingController(text: _format(widget.times));
  bool _invalid = false;

  static String _format(List<Map> times) =>
      times.map((time) => "${time['start']}-${time['end']}").join('\n');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _usePreset(String text) {
    _controller.text = text;
    setState(() => _invalid = false);
  }

  void _save() {
    final lines = _controller.text.trim().split('\n');
    final times = <Map<String, String>>[];
    for (final line in lines) {
      final match = _period.firstMatch(line.trim());
      if (match == null) break;
      final start = match.group(1)!;
      final end = match.group(2)!;
      if (start.compareTo(end) >= 0) break;
      if (times.isNotEmpty && start.compareTo(times.last['end']!) < 0) break;
      times.add({'start': start, 'end': end});
    }
    if (times.length != lines.length || times.length != widget.times.length) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, times);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MDialog(
      s.edit_class_times,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.class_times_hint),
          if (widget.times.length == Constant.CLASS_TIME_LIST.length)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      _usePreset(_format(Constant.CLASS_TIME_LIST)),
                  child: const Text('NJU'),
                ),
                TextButton(
                  onPressed: () => _usePreset(_fudanTimes),
                  child: const Text('FDU'),
                ),
              ],
            ),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '08:00-08:45',
              errorText: _invalid ? s.class_times_invalid : null,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
          ),
        ],
      ),
      widgetCancelAction: () => Navigator.pop(context),
      widgetOK: Text(s.save),
      widgetOKAction: _save,
    );
  }
}
