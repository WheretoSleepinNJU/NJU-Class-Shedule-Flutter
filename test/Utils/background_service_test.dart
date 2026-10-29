import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheretosleepinnju/Utils/BackgroundService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory doc, sources;
  late BackgroundService service;
  late SharedPreferences prefs;
  final now = DateTime(2026, 10, 25, 23, 59);
  Future<List<XFile>> files(int count) async {
    return Future.wait(
      List.generate(count, (i) async {
        final file = File('${sources.path}/$i.jpg');
        await file.writeAsBytes([1, 2, i]);
        return XFile(file.path);
      }),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    doc = await Directory.systemTemp.createTemp('background-doc');
    sources = await Directory.systemTemp.createTemp('background-sources');
    service = BackgroundService(
      documents: () async => doc,
      random: Random(42),
      whiteMode: (_) async => true,
    );
  });
  tearDown(() async {
    await doc.delete(recursive: true);
    await sources.delete(recursive: true);
  });
  test(
    'background samples are cached and never change the global accent',
    () async {
      var samples = 0;
      final colors = BackgroundService(
        documents: () async => doc,
        whiteMode: (_) async => true,
        colorSeed: (file) async {
          samples++;
          return File(file).readAsBytesSync().last == 0 ? '#336699' : '#aa5522';
        },
      );
      await prefs.setString('themeCustomColor', '#872574');
      await prefs.setInt('themeIndex', 9);
      await colors.ensureCurrent();
      expect(samples, 0); // No image means no decoding.
      await colors.addImages(await files(2));
      final images = (await colors.load()).images;
      expect(colors.seedFor(images[0]), '#336699');
      await colors.selectImage(images[1]);
      expect(colors.seedFor(images[1]), '#aa5522');
      expect(colors.seedFor(images[0]), isNull);
      await colors.selectImage(images[0]);
      await colors.load();
      expect(samples, 2);
      expect(prefs.getString('themeCustomColor'), '#872574');
      expect(prefs.getInt('themeIndex'), 9);
      final reopened = BackgroundService(
        documents: () async => doc,
        whiteMode: (_) async => true,
        colorSeed: (_) async =>
            throw StateError('cache should survive restart'),
      );
      await reopened.load();
      expect(reopened.seedFor(images[0]), '#336699');
      await colors.removeImage(images[0]);
      expect(colors.seedFor(images[1]), '#aa5522');
      await colors.clear();
      expect(colors.backgroundSeed.value, isNull);
      expect(prefs.getString('backgroundColorSeeds'), isNull);
      expect(prefs.getString('themeCustomColor'), '#872574');
    },
  );

  test(
    'replaced and unreadable images invalidate safely without repeated decoding',
    () async {
      var samples = 0;
      final colors = BackgroundService(
        documents: () async => doc,
        whiteMode: (_) async => true,
        colorSeed: (file) async {
          samples++;
          return File(file).lengthSync() == 3 ? '#334455' : null;
        },
      );
      await colors.addImages(await files(1));
      final image = (await colors.load()).current;
      expect(colors.seedFor(image), '#334455');
      await File(image).writeAsBytes([4, 3, 2, 1]);
      await colors.load();
      expect(colors.seedFor(image), isNull);
      await colors.load();
      expect(samples, 2);
      await File(image).delete();
      await colors.ensureCurrent();
      expect(colors.backgroundSeed.value, isNull);
    },
  );

  test(
    'single-image visits preserve the manual title-color preference',
    () async {
      await service.addImages(await files(1));
      await service.setWhiteMode(false);
      await service.ensureCurrent(newVisit: true);
      expect(prefs.getBool('whiteMode'), false);
    },
  );
  test(
    'title colors are detected and overrides are saved per picture',
    () async {
      var detections = 0;
      final perImage = BackgroundService(
        documents: () async => doc,
        whiteMode: (image) async {
          detections++;
          return File(image).readAsBytesSync().last == 0;
        },
      );
      await perImage.addImages(await files(2));
      final images = (await perImage.load()).images;
      expect((await perImage.load()).whiteMode, isTrue);
      await perImage.selectImage(images[1]);
      expect((await perImage.load()).whiteMode, isFalse);
      expect(prefs.getBool('whiteMode'), isFalse);
      await perImage.setWhiteMode(true);
      await perImage.selectImage(images[0]);
      await perImage.setWhiteMode(false);
      // The legacy global value must not overwrite either picture's setting.
      await prefs.setBool('whiteMode', true);
      expect((await perImage.load()).whiteMode, isFalse);
      await perImage.selectImage(images[1]);
      expect((await perImage.load()).whiteMode, isTrue);
      final reopened = BackgroundService(
        documents: () async => doc,
        whiteMode: (_) async => throw StateError('saved preference was lost'),
      );
      await reopened.selectImage(images[0]);
      expect((await reopened.load()).whiteMode, isFalse);
      expect(detections, 2);
      await reopened.removeImage(images[0]);
      expect(prefs.getString('backgroundWhiteModes'), isNot(contains('0.jpg')));
      await reopened.clear();
      expect(prefs.getString('backgroundWhiteModes'), isNull);
      expect(prefs.getBool('whiteMode'), isFalse);
    },
  );
  test(
    'empty state, single image and clearing never reuse stale selection',
    () async {
      expect(await service.ensureCurrent(), '');
      final source = await files(1);
      await service.addImages(source);
      final image = await service.ensureCurrent(newVisit: true);
      expect(File(image).existsSync(), isTrue);
      expect(await service.ensureCurrent(newVisit: true), image);
      await service.clear();
      expect(await service.ensureCurrent(), '');
      expect((await service.load()).images, isEmpty);
      expect(prefs.getBool('whiteMode'), false);
      expect(File(source.first.path).existsSync(), isTrue);
    },
  );
  test(
    'copies multiple images, ordinary reads keep selection, visits avoid repeats',
    () async {
      await service.addImages(await files(3));
      final first = (await service.load()).current;
      expect(await service.ensureCurrent(), first);
      expect(await service.ensureCurrent(), first);
      final second = await service.ensureCurrent(newVisit: true);
      expect(second, isNot(first));
      final third = await service.ensureCurrent(newVisit: true);
      expect(third, isNot(second));
      expect((await service.load()).images, hasLength(3));
      expect(
        prefs
            .getStringList('backgroundImages')!
            .every((p) => !p.startsWith('/')),
        isTrue,
      );
    },
  );
  test(
    'day interval persists across service restarts and changes on calendar date boundary',
    () async {
      await service.addImages(await files(2));
      await service.setFrequency(BackgroundFrequency.days, 3, now: now);
      final first = await service.ensureCurrent(now: now);
      final recreated = BackgroundService(
        documents: () async => doc,
        whiteMode: (_) async => false,
      );
      expect(
        await recreated.ensureCurrent(
          newVisit: true,
          now: DateTime(2026, 10, 27, 23, 59),
        ),
        first,
      );
      final next = await recreated.ensureCurrent(now: DateTime(2026, 10, 28));
      expect(next, isNot(first));
      expect(
        await recreated.ensureCurrent(now: DateTime(2026, 10, 28, 23)),
        next,
      );
      expect(prefs.getBool('whiteMode'), false);
    },
  );
  test('manual shuffle resets the day interval', () async {
    await service.addImages(await files(2));
    await service.setFrequency(BackgroundFrequency.days, 3, now: now);
    final next = await service.ensureCurrent(
      force: true,
      now: DateTime(2026, 10, 27),
    );
    expect(await service.ensureCurrent(now: DateTime(2026, 10, 28)), next);
    expect(
      await service.ensureCurrent(now: DateTime(2026, 10, 30)),
      isNot(next),
    );
  });
  test(
    'clock moving backwards resets anchor without replacing the picture',
    () async {
      await service.addImages(await files(2));
      await service.setFrequency(BackgroundFrequency.days, 1, now: now);
      final first = await service.ensureCurrent(now: DateTime(2026, 10, 20));
      expect(
        await service.ensureCurrent(now: DateTime(2026, 10, 21)),
        isNot(first),
      );
    },
  );
  test(
    'legacy single image and relocated iOS paths migrate without loss',
    () async {
      final legacy = File('${doc.path}/background_42.jpg');
      await legacy.writeAsBytes([1]);
      await prefs.setString(
        'bgImgPath',
        '/obsolete-container/Documents/background_42.jpg',
      );
      expect(await service.ensureCurrent(), legacy.path);
      expect((await service.load()).images, [legacy.path]);
      expect(prefs.getStringList('backgroundImages'), ['background_42.jpg']);
    },
  );
  test(
    'missing current image falls back, last missing image yields empty background',
    () async {
      await service.addImages(await files(2));
      final current = (await service.load()).current;
      await File(current).delete();
      final next = await service.ensureCurrent();
      expect(next, isNot(current));
      expect(next, isNotEmpty);
      await File(next).delete();
      expect(await service.ensureCurrent(), '');
    },
  );
  test(
    'remove active selects another; clear deletes only managed copies',
    () async {
      final original = await files(2);
      await service.addImages(original);
      final old = (await service.load()).current;
      await service.removeImage(old);
      expect(File(old).existsSync(), isFalse);
      expect((await service.load()).current, isNot(old));
      await service.clear();
      expect(
        await Directory('${doc.path}/backgrounds').list().toList(),
        isEmpty,
      );
      expect(original.every((f) => File(f.path).existsSync()), isTrue);
    },
  );
  test(
    'failed batch import preserves previous images and cleans incomplete copies',
    () async {
      await service.addImages(await files(1));
      final before = await service.load();
      await expectLater(
        service.addImages([
          ...(await files(1)),
          XFile('${sources.path}/missing.jpg'),
        ]),
        throwsA(isA<FileSystemException>()),
      );
      expect((await service.load()).images, before.images);
      expect(
        await Directory('${doc.path}/backgrounds').list().toList(),
        hasLength(1),
      );
    },
  );
  test(
    'invalid frequency, empty picker result and too many pictures preserve configuration',
    () async {
      await expectLater(
        service.setFrequency(BackgroundFrequency.days, 0),
        throwsRangeError,
      );
      await expectLater(
        service.setFrequency(BackgroundFrequency.days, 366),
        throwsRangeError,
      );
      await service.addImages([]);
      await expectLater(service.addImages(await files(21)), throwsRangeError);
      expect((await service.load()).images, isEmpty);
    },
  );
  test('overlapping writes are serialized and no picture is lost', () async {
    final input = await files(3);
    await Future.wait(input.map((f) => service.addImages([f])));
    expect((await service.load()).images, hasLength(3));
  });
}
