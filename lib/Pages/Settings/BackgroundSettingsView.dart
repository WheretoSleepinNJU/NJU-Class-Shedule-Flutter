import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../Components/Toast.dart';
import '../../Utils/BackgroundService.dart';
import '../../generated/l10n.dart';

class BackgroundSettingsView extends StatefulWidget {
  const BackgroundSettingsView({super.key});

  @override
  State<BackgroundSettingsView> createState() => _BackgroundSettingsViewState();
}

class _BackgroundSettingsViewState extends State<BackgroundSettingsView> {
  BackgroundSettings? _settings;
  bool _busy = false;
  final _service = BackgroundService.instance;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await _service.ensureCurrent();
    final value = await _service.load();
    if (mounted) setState(() => _settings = value);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
    } catch (_) {
      if (mounted) Toast.showToast(S.of(context).background_error, context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() => _run(() async {
    final remaining = BackgroundService.maxImages - _settings!.images.length;
    if (remaining <= 0) return;
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (!mounted || files.isEmpty) return;
    if (files.length > remaining) {
      Toast.showToast(
        S.of(context).background_limit(BackgroundService.maxImages),
        context,
      );
      return;
    }
    await _service.addImages(files);
  });

  Future<void> _frequency() async {
    final result = await showDialog<(BackgroundFrequency, int)>(
      context: context,
      builder: (_) => _FrequencyDialog(settings: _settings!),
    );
    if (result != null && mounted) {
      await _run(() => _service.setFrequency(result.$1, result.$2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), colors = Theme.of(context).colorScheme;
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.background_settings_title)),
      body:
          settings == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      s.background_intro,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (settings.images.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 48,
                              color: colors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.background_empty,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: settings.images.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: .75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, i) {
                          final image = settings.images[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Semantics(
                                  button: true,
                                  selected: image == settings.current,
                                  label: s.background_use,
                                  child: InkWell(
                                    key: ValueKey('use-background-$i'),
                                    onTap:
                                        _busy
                                            ? null
                                            : () => _run(
                                              () => _service.selectImage(image),
                                            ),
                                    child: Image.file(
                                      File(image),
                                      cacheWidth: 320,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                    ),
                                  ),
                                ),
                                if (image == settings.current)
                                  Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.background_current,
                                        style: TextStyle(
                                          color: colors.onPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filledTonal(
                                    key: ValueKey('remove-background-$i'),
                                    tooltip: s.background_remove,
                                    style: IconButton.styleFrom(
                                      backgroundColor: colors.surface
                                          .withValues(alpha: .9),
                                    ),
                                    onPressed:
                                        _busy
                                            ? null
                                            : () => _run(
                                              () => _service.removeImage(image),
                                            ),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    if (settings.images.isNotEmpty)
                      SwitchListTile(
                        key: const ValueKey('background-white-title'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.white_title_mode_title),
                        subtitle: Text(s.background_title_color_hint),
                        value: settings.whiteMode,
                        onChanged:
                            _busy
                                ? null
                                : (white) =>
                                    _run(() => _service.setWhiteMode(white)),
                      ),
                    OutlinedButton.icon(
                      key: const ValueKey('add-backgrounds'),
                      onPressed:
                          _busy ||
                                  settings.images.length >=
                                      BackgroundService.maxImages
                              ? null
                              : _add,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(s.background_add),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.background_limit(BackgroundService.maxImages),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      key: const ValueKey('background-frequency'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.background_frequency),
                      subtitle: Text(s.background_frequency_subtitle),
                      trailing: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .42,
                        ),
                        child: Text(
                          settings.frequency == BackgroundFrequency.everyVisit
                              ? s.background_every_visit
                              : s.background_every_days(settings.days),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                      onTap: _busy ? null : _frequency,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('shuffle-background'),
                      onPressed:
                          _busy || settings.images.length < 2
                              ? null
                              : () => _run(() async {
                                await _service.ensureCurrent(force: true);
                              }),
                      icon: const Icon(Icons.shuffle),
                      label: Text(s.background_shuffle),
                    ),
                    if (settings.images.isNotEmpty)
                      TextButton(
                        key: const ValueKey('clear-backgrounds'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: colors.error,
                        ),
                        onPressed: _busy ? null : () => _run(_service.clear),
                        child: Text(s.background_clear),
                      ),
                    if (_busy) const LinearProgressIndicator(),
                  ],
                ),
              ),
    );
  }
}

class _FrequencyDialog extends StatefulWidget {
  const _FrequencyDialog({required this.settings});
  final BackgroundSettings settings;
  @override
  State<_FrequencyDialog> createState() => _FrequencyDialogState();
}

class _FrequencyDialogState extends State<_FrequencyDialog> {
  late BackgroundFrequency _frequency = widget.settings.frequency;
  late final _days = TextEditingController(text: '${widget.settings.days}');
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(s.background_frequency),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: RadioGroup<BackgroundFrequency>(
            groupValue: _frequency,
            onChanged: (value) => setState(() => _frequency = value!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<BackgroundFrequency>(
                  key: const ValueKey('background-mode-visit'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.background_every_visit),
                  value: BackgroundFrequency.everyVisit,
                ),
                RadioListTile<BackgroundFrequency>(
                  key: const ValueKey('background-mode-days'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.background_by_days),
                  value: BackgroundFrequency.days,
                ),
                if (_frequency == BackgroundFrequency.days)
                  TextFormField(
                    key: const ValueKey('background-days'),
                    controller: _days,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: s.background_days_label,
                      suffixText: s.background_days_unit,
                    ),
                    validator: (value) {
                      final days = int.tryParse(value ?? '');
                      return days == null || days < 1 || days > 365
                          ? s.background_days_error
                          : null;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          key: const ValueKey('save-background-frequency'),
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (
                _frequency,
                int.tryParse(_days.text) ?? 1,
              ));
            }
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}
