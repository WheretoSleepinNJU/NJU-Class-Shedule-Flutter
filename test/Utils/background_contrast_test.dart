import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/Utils/ColorUtil.dart';

void main() {
  testWidgets('small dark and light photos choose readable title contrast', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp(
        'background-contrast',
      );
      try {
        for (final color in [Colors.black, Colors.white]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 8, 16),
            Paint()..color = color,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(8, 16);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('${folder.path}/photo.png');
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
          picture.dispose();
          expect(
            await ColorUtil.shouldApplyWhiteMode(file.path),
            color == Colors.black,
          );
        }
      } finally {
        await folder.delete(recursive: true);
      }
    });
  });
}
