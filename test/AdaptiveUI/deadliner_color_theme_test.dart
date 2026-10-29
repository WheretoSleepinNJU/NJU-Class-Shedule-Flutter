import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wheretosleepinnju/AdaptiveUI/adaptive_ui.dart';
import 'package:wheretosleepinnju/Resources/Themes.dart';

void main() {
  // Independently generated with Deadliner's pinned Kotlin MaterialKolor 4.1.1
  // (SPEC_2025/PHONE/TonalSpot, or its explicit-primary SPEC_2021 preset path).
  final vectors =
      (jsonDecode(
                File(
                  'test/AdaptiveUI/fixtures/deadliner_materialkolor_4_1_1.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  for (final vector in vectors) {
    test(
      'matches Kotlin seed ${vector['seed']} dark=${vector['dark']} monet=${vector['monet']}',
      () {
        final palette = DeadlinerColorTheme.fromSeed(
          seed: Color(vector['seed'] as int),
          brightness: vector['dark'] == true
              ? Brightness.dark
              : Brightness.light,
          useMonet: vector['monet'] as bool,
        );
        final material = palette.toNativeMap()['materialColors'] as Map;
        for (final role in vector.keys.where(
          (key) =>
              !['seed', 'dark', 'monet', 'textFieldContainer'].contains(key),
        )) {
          expect(material[role], vector[role], reason: role);
        }
        expect(
          palette.textFieldContainer.toARGB32(),
          vector['textFieldContainer'],
          reason: 'componentContainerColor harmonization',
        );
      },
    );
  }
  for (final dark in [false, true]) {
    test('HyperOS neutrals and both renderers agree, dark=$dark', () {
      final mode = dark ? Brightness.dark : Brightness.light;
      final palette = DeadlinerColorTheme.fromSeed(
        seed: Colors.green,
        brightness: mode,
        useMonet: true,
      );
      final m = palette.material, x = palette.miuixColors;
      expect(m.surface.toARGB32(), dark ? 0xff000000 : 0xfff3f3f3);
      expect(m.surfaceContainer.toARGB32(), dark ? 0xff242424 : 0xffffffff);
      expect(m.onSurface.toARGB32(), dark ? 0xfff2f2f2 : 0xff191919);
      expect(m.onSurfaceVariant.toARGB32(), dark ? 0xffa6a6a6 : 0xff6f6f6f);
      expect(x.background, m.surface);
      expect(x.surfaceContainer, m.surfaceContainer);
      expect(x.primary, m.primary);
      expect(x.onPrimary, m.onPrimary);
      expect(x.disabledPrimary, m.primary.withValues(alpha: .45));
      expect(x.dividerLine, m.outlineVariant);
      expect(x.windowDimming, m.scrim);
      final other = DeadlinerColorTheme.fromSeed(
        seed: Colors.red,
        brightness: mode,
        useMonet: true,
      );
      expect(other.material.surface, m.surface);
      expect(other.material.surfaceContainer, m.surfaceContainer);
      expect(other.material.onSurface, m.onSurface);
      final theme = AppThemes.build('#0095F9', mode, useSeedScheme: true);
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainer);
      expect(
        theme.dialogTheme.backgroundColor,
        theme.colorScheme.surfaceContainer,
      );
      expect(theme.dialogTheme.barrierColor, theme.colorScheme.scrim);
      expect(
        theme.inputDecorationTheme.fillColor,
        theme.extension<DeadlinerColorTheme>()!.textFieldContainer,
      );
    });
  }
  test('theme interpolation keeps the two color consumers synchronized', () {
    final a = DeadlinerColorTheme.fromSeed(
      seed: Colors.blue,
      brightness: Brightness.light,
      useMonet: true,
    );
    final b = DeadlinerColorTheme.fromSeed(
      seed: Colors.red,
      brightness: Brightness.dark,
      useMonet: true,
    );
    for (final t in [0.0, .25, .5, .75, 1.0]) {
      final mid = a.lerp(b, t);
      expect(mid.material.primary, mid.miuixColors.primary);
      expect(mid.material.surfaceContainer, mid.miuixColors.surfaceContainer);
      expect(mid.material.onSurface, mid.miuixColors.onSurface);
    }
  });
}
