import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ColorUtil.dart';

enum BackgroundFrequency { everyVisit, days }

class BackgroundSettings {
  const BackgroundSettings({
    required this.images,
    required this.current,
    required this.frequency,
    required this.days,
    required this.whiteMode,
  });
  final List<String> images;
  final String current;
  final BackgroundFrequency frequency;
  final int days;
  final bool whiteMode;
}

/// Owns copied images and persists one selection. Reads/rebuilds never shuffle;
/// only a new timetable visit, a due date or an explicit request can do that.
class BackgroundService {
  BackgroundService({
    Future<Directory> Function()? documents,
    Future<bool> Function(String)? whiteMode,
    Random? random,
  }) : _documents = documents ?? getApplicationDocumentsDirectory,
       _whiteMode = whiteMode ?? ColorUtil.shouldApplyWhiteMode,
       _random = random ?? Random();

  static final instance = BackgroundService();
  static const maxImages = 20;
  final Future<Directory> Function() _documents;
  final Future<bool> Function(String) _whiteMode;
  final Random _random;
  Future<void> _pending = Future.value();

  // Home/lifecycle/settings can overlap; serialize preferences and file writes.
  Future<T> _run<T>(Future<T> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static int _day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  Future<BackgroundSettings> load() => _run(() async {
    final sp = await SharedPreferences.getInstance();
    return _load(sp);
  });

  Future<BackgroundSettings> _load(SharedPreferences sp) async {
    final doc = await _documents();
    final stored =
        sp.getStringList('backgroundImages') ??
        [
          if ((sp.getString('bgImgPath') ?? '').isNotEmpty)
            sp.getString('bgImgPath')!,
        ];
    final images = <String>[];
    for (final item in stored) {
      // Old single-image installs and iOS data-container relocations migrate.
      final candidates = [
        path.isAbsolute(item) ? item : path.join(doc.path, item),
        path.join(doc.path, path.basename(item)),
        path.join(doc.path, 'backgrounds', path.basename(item)),
      ];
      for (final candidate in candidates) {
        if (await File(candidate).exists()) {
          if (!images.contains(candidate)) images.add(candidate);
          break;
        }
      }
    }
    final rawCurrent = sp.getString('bgImgPath') ?? '';
    final current =
        images
            .where(
              (image) =>
                  image == rawCurrent ||
                  path.basename(image) == path.basename(rawCurrent),
            )
            .firstOrNull ??
        '';
    await sp.setStringList(
      'backgroundImages',
      images.map((p) => path.relative(p, from: doc.path)).toList(),
    );
    final settings = BackgroundSettings(
      images: images,
      current: current,
      frequency:
          sp.getString('backgroundFrequency') == 'days'
              ? BackgroundFrequency.days
              : BackgroundFrequency.everyVisit,
      days: (sp.getInt('backgroundDays') ?? 1).clamp(1, 365),
      whiteMode: await _applyWhiteMode(sp, current),
    );
    if (current != rawCurrent) await sp.setString('bgImgPath', current);
    return settings;
  }

  Future<void> _select(SharedPreferences sp, String image, DateTime now) async {
    await _applyWhiteMode(sp, image);
    await sp.setString('bgImgPath', image);
    await sp.setInt('backgroundChangedDay', _day(now));
  }

  Map<String, bool> _titleModes(SharedPreferences sp) {
    try {
      final value = jsonDecode(sp.getString('backgroundWhiteModes') ?? '{}');
      if (value is Map) {
        return {
          for (final entry in value.entries)
            if (entry.key is String && entry.value is bool)
              entry.key as String: entry.value as bool,
        };
      }
    } on FormatException {
      // A malformed cache can be rebuilt from the pictures.
    }
    return {};
  }

  Future<String> _titleModeKey(String image) async =>
      path.relative(image, from: (await _documents()).path);

  Future<bool> _applyWhiteMode(SharedPreferences sp, String image) async {
    var white = false;
    if (image.isNotEmpty) {
      final key = await _titleModeKey(image);
      final modes = _titleModes(sp);
      if (!modes.containsKey(key)) {
        modes[key] = await _whiteMode(image);
        await sp.setString('backgroundWhiteModes', jsonEncode(modes));
      }
      white = modes[key]!;
    }
    // Keep the existing timetable reader compatible, but never use this global
    // value as the preference for a different picture.
    await sp.setBool('whiteMode', white);
    return white;
  }

  Future<void> selectImage(String image, {DateTime? now}) => _run(() async {
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    if (!settings.images.contains(image)) return;
    await _select(sp, image, now ?? DateTime.now());
  });

  Future<void> setWhiteMode(bool white) => _run(() async {
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    if (settings.current.isEmpty) return;
    final modes = _titleModes(sp);
    modes[await _titleModeKey(settings.current)] = white;
    await sp.setString('backgroundWhiteModes', jsonEncode(modes));
    await sp.setBool('whiteMode', white);
  });

  Future<String> ensureCurrent({
    bool newVisit = false,
    bool force = false,
    DateTime? now,
  }) => _run(() async {
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    final time = now ?? DateTime.now();
    if (settings.images.isEmpty) {
      await _select(sp, '', time);
      return '';
    }
    final changed = sp.getInt('backgroundChangedDay');
    final due =
        settings.frequency == BackgroundFrequency.everyVisit
            ? newVisit
            : changed == null || _day(time) - changed >= settings.days;
    if (force || due || settings.current.isEmpty) {
      final choices =
          settings.images.where((p) => p != settings.current).toList();
      final next =
          choices.isEmpty
              ? settings.images.first
              : choices[_random.nextInt(choices.length)];
      if (next != settings.current || settings.current.isEmpty) {
        await _select(sp, next, time);
      } else {
        // A single-image pool keeps the preference for that picture.
        await sp.setInt('backgroundChangedDay', _day(time));
      }
      return next;
    }
    // Clock correction must not hold the same background indefinitely.
    if (changed == null || changed > _day(time)) {
      await sp.setInt('backgroundChangedDay', _day(time));
    }
    return settings.current;
  });

  Future<void> setFrequency(
    BackgroundFrequency frequency,
    int days, {
    DateTime? now,
  }) => _run(() async {
    if (days < 1 || days > 365) throw RangeError.range(days, 1, 365);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('backgroundFrequency', frequency.name);
    await sp.setInt('backgroundDays', days);
    await sp.setInt('backgroundChangedDay', _day(now ?? DateTime.now()));
  });

  Future<void> addImages(List<XFile> files) => _run(() async {
    if (files.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    if (settings.images.length + files.length > maxImages) {
      throw RangeError('At most $maxImages background images');
    }
    final doc = await _documents();
    final folder = Directory(path.join(doc.path, 'backgrounds'));
    await folder.create(recursive: true);
    final added = <String>[];
    try {
      for (var i = 0; i < files.length; i++) {
        final extension = path.extension(files[i].path).toLowerCase();
        final safeExtension =
            RegExp(r'^\.[a-z0-9]{1,6}$').hasMatch(extension)
                ? extension
                : '.jpg';
        final destination = path.join(
          folder.path,
          '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 30)}_$i$safeExtension',
        );
        added.add(destination);
        await files[i].saveTo(destination);
      }
      final all = [...settings.images, ...added];
      await sp.setStringList(
        'backgroundImages',
        all.map((p) => path.relative(p, from: doc.path)).toList(),
      );
    } catch (_) {
      for (final file in added) {
        if (await File(file).exists()) await File(file).delete();
      }
      rethrow;
    }
    if (settings.current.isEmpty) {
      await _select(sp, added.first, DateTime.now());
    }
  });

  Future<void> removeImage(String image) => _run(() async {
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    if (!settings.images.contains(image)) return;
    final remaining = settings.images.where((p) => p != image).toList();
    final doc = await _documents();
    await sp.setStringList(
      'backgroundImages',
      remaining.map((p) => path.relative(p, from: doc.path)).toList(),
    );
    if (settings.current == image) {
      await _select(
        sp,
        remaining.isEmpty ? '' : remaining[_random.nextInt(remaining.length)],
        DateTime.now(),
      );
    }
    final modes = _titleModes(sp)..remove(await _titleModeKey(image));
    await sp.setString('backgroundWhiteModes', jsonEncode(modes));
    await _deleteOwned(image, doc);
  });

  Future<void> clear() => _run(() async {
    final sp = await SharedPreferences.getInstance();
    final settings = await _load(sp);
    final doc = await _documents();
    await sp.setStringList('backgroundImages', []);
    await sp.remove('backgroundWhiteModes');
    await _select(sp, '', DateTime.now());
    for (final image in settings.images) {
      await _deleteOwned(image, doc);
    }
  });

  Future<void> _deleteOwned(String image, Directory doc) async {
    final managed =
        path.isWithin(path.join(doc.path, 'backgrounds'), image) ||
        (path.dirname(image) == doc.path &&
            RegExp(r'^background_\d+\.jpg$').hasMatch(path.basename(image)));
    if (managed && await File(image).exists()) await File(image).delete();
  }
}
