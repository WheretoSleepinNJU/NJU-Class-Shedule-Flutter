import '../../AdaptiveUI/adaptive_ui.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import 'ImportFromBEView.dart';

/// Session-only draft: scripts and login URLs are never uploaded or persisted.
class ImportTestView extends StatefulWidget {
  const ImportTestView({super.key, this.runImport});
  final Future<bool?> Function(BuildContext, Map<String, dynamic>)? runImport;
  @override
  State<ImportTestView> createState() => _ImportTestViewState();
}

class _ImportTestViewState extends State<ImportTestView> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final name in [
      'initialUrl',
      'redirectUrl',
      'targetUrl',
      'preExtractJS',
      'delayTime',
      'extractJS',
    ])
      name: TextEditingController(text: name == 'delayTime' ? '0' : ''),
  };
  bool _running = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _url(String? value, {bool optional = false}) {
    final text = (value ?? '').trim();
    if (optional && text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri != null &&
            ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? null
        : S.of(context).import_test_url_required;
  }

  Future<void> _start() async {
    if (!_form.currentState!.validate() || _running) return;
    FocusScope.of(context).unfocus();
    final config = <String, dynamic>{
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      'delayTime': int.parse(_fields['delayTime']!.text.trim()),
      'page_title': S.of(context).import_test_title,
    };
    setState(() => _running = true);
    try {
      final result = widget.runImport != null
          ? await widget.runImport!(context, config)
          : await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ImportFromBEView(config: config, testMode: true),
              ),
            );
      if (mounted && result == true) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(title: Text(s.import_test_title)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AdaptivePageScroll(
            padding: const EdgeInsets.all(16),
            child: AdaptiveSection(
              padding: const EdgeInsets.all(16),
              separated: false,
              children: [
                Text(
                  s.import_test_hint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                for (final name in _fields.keys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AdaptiveTextFormField(
                      key: ValueKey('import-field-$name'),
                      controller: _fields[name],
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: name == 'delayTime'
                          ? TextInputType.number
                          : name.endsWith('JS')
                          ? TextInputType.multiline
                          : TextInputType.url,
                      minLines: name.endsWith('JS') ? 4 : 1,
                      maxLines: name.endsWith('JS') ? 10 : 3,
                      decoration: InputDecoration(
                        labelText: name,
                        border: const OutlineInputBorder(),
                        helperText: name == 'redirectUrl'
                            ? s.import_test_redirect_hint
                            : null,
                        helperMaxLines: 3,
                      ),
                      validator: (value) {
                        if (name.endsWith('Url')) {
                          return _url(value, optional: name == 'redirectUrl');
                        }
                        if (name == 'delayTime') {
                          final delay = int.tryParse((value ?? '').trim());
                          if (delay == null || delay < 0 || delay > 60) {
                            return s.import_test_delay_invalid;
                          }
                        }
                        if (name == 'extractJS' &&
                            (value ?? '').trim().isEmpty) {
                          return s.import_test_script_required;
                        }
                        return null;
                      },
                    ),
                  ),
                AdaptiveButton.icon(
                  variant: AdaptiveButtonVariant.filled,
                  key: const ValueKey('start-import-test'),
                  onPressed: _running ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(s.import_test_start),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
