import 'Widgets/MiuixSettings.dart';
import 'dart:io';

import 'package:flutter/material.dart';
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
    return SettingsScaffold(
      title: s.background_settings_title,
      body: settings == null
          ? const Center(child: MiuixCircularProgressIndicator())
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
                          Text(s.background_empty, textAlign: TextAlign.center),
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
                                child: MiuixPressable(
                                  key: ValueKey('use-background-$i'),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => _service.selectImage(image),
                                        ),
                                  child: Image.file(
                                    File(image),
                                    cacheWidth: 320,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image_outlined),
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
                                child: MiuixIconButton(
                                  key: ValueKey('remove-background-$i'),
                                  backgroundColor: colors.surface.withValues(
                                    alpha: .9,
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => _service.removeImage(image),
                                        ),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  if (settings.images.isNotEmpty)
                    SettingsSwitchTile(
                      key: const ValueKey('background-white-title'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.white_title_mode_title),
                      subtitle: Text(s.background_title_color_hint),
                      value: settings.whiteMode,
                      onChanged: _busy
                          ? null
                          : (white) => _run(() => _service.setWhiteMode(white)),
                    ),
                  SettingsIconButton(
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
                  SettingsTile(
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: colors.primary),
                      ),
                    ),
                    onTap: _busy ? null : _frequency,
                  ),
                  const SizedBox(height: 16),
                  SettingsIconButton(
                    key: const ValueKey('shuffle-background'),
                    onPressed: _busy || settings.images.length < 2
                        ? null
                        : () => _run(() async {
                            await _service.ensureCurrent(force: true);
                          }),
                    icon: const Icon(Icons.shuffle),
                    label: Text(s.background_shuffle),
                  ),
                  if (settings.images.isNotEmpty)
                    MiuixButton(
                      key: const ValueKey('clear-backgrounds'),
                      onPressed: _busy ? null : () => _run(_service.clear),
                      child: Text(s.background_clear),
                    ),
                  if (_busy) const MiuixLinearProgressIndicator(),
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
  late int _days = widget.settings.days.clamp(1, 365);
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SettingsDialog(
      title: Text(s.background_frequency),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixRadioButtonPreference(
            key: const ValueKey('background-mode-visit'),
            title: s.background_every_visit,
            selected: _frequency == BackgroundFrequency.everyVisit,
            onClick: () =>
                setState(() => _frequency = BackgroundFrequency.everyVisit),
          ),
          MiuixRadioButtonPreference(
            key: const ValueKey('background-mode-days'),
            title: s.background_by_days,
            selected: _frequency == BackgroundFrequency.days,
            onClick: () =>
                setState(() => _frequency = BackgroundFrequency.days),
          ),
          if (_frequency == BackgroundFrequency.days)
            MiuixNumberPicker(
              key: const ValueKey('background-days'),
              value: _days,
              min: 1,
              max: 365,
              label: (value) => s.background_every_days(value),
              onValueChanged: (value) => setState(() => _days = value),
            ),
        ],
      ),
      actions: [
        MiuixButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        MiuixButton(
          key: const ValueKey('save-background-frequency'),
          onPressed: () => Navigator.pop(context, (_frequency, _days)),
          child: Text(s.save),
        ),
      ],
    );
  }
}
