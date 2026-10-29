// ignore_for_file: deprecated_member_use
// Deadliner retains surfaceVariant independently from surfaceContainerHighest.
import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'package:libmonet/material_color_utilities.dart' as monet;

/// Port of DeadlinerColorTokenFactory, DeadlinerMiuixColorSchemeFactory,
/// DeadlinerMaterial3ColorSchemeFactory and ComponentContainerColors at
/// Deadliner 967b7da573fdfa537b45900755ec630640d2cf80 (MIT).
/// SPEC_2025 / PHONE / TonalSpot and the HyperOS neutral surface roles are
/// shared by Material, Flutter MIUIX and the Compose chrome. No re-seeding of
/// an already generated primary is performed.
@immutable
class DeadlinerColorTheme extends ThemeExtension<DeadlinerColorTheme> {
  const DeadlinerColorTheme._({
    required this.material,
    required this.miuixColors,
    required this.textFieldContainer,
    required this.seed,
    required this.useMonet,
  });
  final ColorScheme material;
  final miuix.MiuixColors miuixColors;
  final Color textFieldContainer;
  final Color seed;
  final bool useMonet;
  static final Map<(int, Brightness, bool), DeadlinerColorTheme> _cache = {};

  factory DeadlinerColorTheme.fromSeed({
    required Color seed,
    required Brightness brightness,
    required bool useMonet,
  }) {
    final key = (seed.toARGB32(), brightness, useMonet);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final result = _create(seed, brightness, useMonet);
    if (_cache.length >= 64) _cache.remove(_cache.keys.first);
    _cache[key] = result;
    return result;
  }
  static DeadlinerColorTheme of(ThemeData theme) =>
      theme.extension<DeadlinerColorTheme>() ??
      DeadlinerColorTheme._fromMaterial(theme.colorScheme);

  factory DeadlinerColorTheme._fromMaterial(ColorScheme material) =>
      DeadlinerColorTheme._(
        material: material,
        miuixColors: _miuixFor(material),
        textFieldContainer: material.secondaryContainer,
        seed: material.primary,
        useMonet: true,
      );

  static DeadlinerColorTheme _create(
    Color seed,
    Brightness brightness,
    bool useMonet,
  ) {
    final dark = brightness == Brightness.dark;
    final defaults = dark ? miuix.darkColorScheme() : miuix.lightColorScheme();
    // Deadliner's fixed-accent mode uses SPEC_2021 and an explicit primary
    // palette. Keep the app's existing selected seed and raw/Monet preference.
    final dynamic = monet.DynamicScheme.fromPalettesOrKeyColors(
      sourceColorHct: monet.Hct.fromInt(seed.toARGB32()),
      variant: monet.Variant.tonalSpot,
      isDark: dark,
      contrastLevel: 0,
      platform: monet.Platform.phone,
      specVersion: useMonet
          ? monet.SpecVersion.spec2025
          : monet.SpecVersion.spec2021,
      primaryPalette: useMonet
          ? null
          : monet.TonalPalette.fromInt(seed.toARGB32()),
    );
    final primary = useMonet ? Color(dynamic.primary) : seed;
    final onPrimary = useMonet
        ? Color(dynamic.onPrimary)
        : const Color(0xffffffff);
    final canvas = dark ? const Color(0xff000000) : const Color(0xfff3f3f3);
    final foreground = dark ? const Color(0xfff2f2f2) : const Color(0xff191919);
    final summary = dark ? const Color(0xffa6a6a6) : const Color(0xff6f6f6f);
    final material = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: Color(dynamic.primaryContainer),
      onPrimaryContainer: Color(dynamic.onPrimaryContainer),
      inversePrimary: Color(dynamic.inversePrimary),
      secondary: Color(dynamic.secondary),
      onSecondary: Color(dynamic.onSecondary),
      secondaryContainer: Color(dynamic.secondaryContainer),
      onSecondaryContainer: Color(dynamic.onSecondaryContainer),
      tertiary: Color(dynamic.tertiary),
      onTertiary: Color(dynamic.onTertiary),
      tertiaryContainer: Color(dynamic.tertiaryContainer),
      onTertiaryContainer: Color(dynamic.onTertiaryContainer),
      error: Color(dynamic.error),
      onError: Color(dynamic.onError),
      errorContainer: Color(dynamic.errorContainer),
      onErrorContainer: Color(dynamic.onErrorContainer),
      surface: canvas,
      onSurface: foreground,
      surfaceVariant: dark ? const Color(0xff333333) : const Color(0xffececec),
      onSurfaceVariant: summary,
      surfaceContainer: defaults.surfaceContainer,
      surfaceContainerLow: canvas,
      surfaceContainerLowest: canvas,
      surfaceContainerHigh: defaults.surfaceContainerHigh,
      surfaceContainerHighest: defaults.surfaceContainerHighest,
      surfaceBright: defaults.surfaceVariant,
      surfaceDim: defaults.surfaceContainerHigh,
      outline: defaults.outline,
      outlineVariant: defaults.dividerLine,
      surfaceTint: primary,
      inverseSurface: foreground,
      onInverseSurface: canvas,
      scrim: const Color(0xff000000).withValues(alpha: dark ? .6 : .3),
      shadow: Color(dynamic.shadow),
      primaryFixed: Color(dynamic.primaryContainer),
      primaryFixedDim: primary,
      onPrimaryFixed: Color(dynamic.onPrimaryContainer),
      onPrimaryFixedVariant: onPrimary,
      secondaryFixed: Color(dynamic.secondaryContainer),
      secondaryFixedDim: Color(dynamic.secondary),
      onSecondaryFixed: Color(dynamic.onSecondaryContainer),
      onSecondaryFixedVariant: Color(dynamic.onSecondary),
      tertiaryFixed: Color(dynamic.tertiaryContainer),
      tertiaryFixedDim: Color(dynamic.tertiary),
      onTertiaryFixed: Color(dynamic.onTertiaryContainer),
      onTertiaryFixedVariant: Color(dynamic.onTertiary),
    );
    final input = useMonet
        ? Color(
            monet.Blend.harmonize(
              defaults.secondaryContainer.toARGB32(),
              material.secondary.toARGB32(),
            ),
          )
        : defaults.secondaryContainer;
    return DeadlinerColorTheme._(
      material: material,
      miuixColors: _miuixFor(material),
      textFieldContainer: input,
      seed: seed,
      useMonet: useMonet,
    );
  }

  static miuix.MiuixColors _miuixFor(ColorScheme m) {
    final dark = m.brightness == Brightness.dark;
    final defaults = dark ? miuix.darkColorScheme() : miuix.lightColorScheme();
    return defaults.copy(
      primary: m.primary,
      onPrimary: m.onPrimary,
      primaryVariant: m.inversePrimary,
      onPrimaryVariant: m.onPrimaryContainer,
      primaryContainer: m.primaryContainer,
      onPrimaryContainer: m.onPrimaryContainer,
      error: m.error,
      onError: m.onError,
      errorContainer: m.errorContainer,
      onErrorContainer: m.onErrorContainer,
      disabledPrimary: m.primary.withValues(alpha: .45),
      disabledOnPrimary: m.onPrimary.withValues(alpha: .6),
      disabledPrimaryButton: m.primary.withValues(alpha: .45),
      disabledOnPrimaryButton: m.onPrimary.withValues(alpha: .6),
      disabledPrimarySlider: m.primary.withValues(alpha: .55),
      secondaryContainer: m.secondaryContainer,
      onSecondaryContainer: m.onSecondaryContainer,
      secondaryContainerVariant: m.surfaceContainerHigh,
      onSecondaryContainerVariant: m.onSurfaceVariant,
      tertiaryContainer: m.tertiaryContainer,
      onTertiaryContainer: m.onTertiaryContainer,
      tertiaryContainerVariant: m.surfaceContainerHighest,
      background: m.surface,
      onBackground: m.onSurface,
      onBackgroundVariant: m.onSurfaceVariant,
      surface: m.surface,
      onSurface: m.onSurface,
      surfaceVariant: m.surfaceVariant,
      onSurfaceSecondary: m.onSurface.withValues(alpha: .8),
      onSurfaceVariantSummary: m.onSurfaceVariant,
      onSurfaceVariantActions: m.onSurface,
      disabledOnSurface: m.onSurfaceVariant.withValues(alpha: .5),
      surfaceContainer: m.surfaceContainer,
      onSurfaceContainer: m.onSurface,
      onSurfaceContainerVariant: m.onSurfaceVariant,
      surfaceContainerHigh: m.surfaceContainerHigh,
      onSurfaceContainerHigh: m.onSurface,
      surfaceContainerHighest: m.surfaceContainerHighest,
      onSurfaceContainerHighest: m.onSurface,
      outline: m.outline,
      dividerLine: m.outlineVariant,
      windowDimming: const Color(0xff000000).withValues(alpha: dark ? .6 : .3),
      sliderKeyPoint: m.onSurfaceVariant.withValues(alpha: .55),
      sliderKeyPointForeground: m.onPrimary.withValues(alpha: .85),
      sliderBackground: Color.alphaBlend(
        m.outlineVariant.withValues(alpha: dark ? .48 : .28),
        m.surfaceContainerHigh,
      ),
    );
  }

  Map<String, Object> toNativeMap() => {
    'materialColors': {
      'primary': material.primary.toARGB32(),
      'onPrimary': material.onPrimary.toARGB32(),
      'primaryContainer': material.primaryContainer.toARGB32(),
      'onPrimaryContainer': material.onPrimaryContainer.toARGB32(),
      'inversePrimary': material.inversePrimary.toARGB32(),
      'secondary': material.secondary.toARGB32(),
      'onSecondary': material.onSecondary.toARGB32(),
      'secondaryContainer': material.secondaryContainer.toARGB32(),
      'onSecondaryContainer': material.onSecondaryContainer.toARGB32(),
      'tertiary': material.tertiary.toARGB32(),
      'onTertiary': material.onTertiary.toARGB32(),
      'tertiaryContainer': material.tertiaryContainer.toARGB32(),
      'onTertiaryContainer': material.onTertiaryContainer.toARGB32(),
      'error': material.error.toARGB32(),
      'onError': material.onError.toARGB32(),
      'errorContainer': material.errorContainer.toARGB32(),
      'onErrorContainer': material.onErrorContainer.toARGB32(),
      'surface': material.surface.toARGB32(),
      'onSurface': material.onSurface.toARGB32(),
      'surfaceVariant': material.surfaceVariant.toARGB32(),
      'onSurfaceVariant': material.onSurfaceVariant.toARGB32(),
      'surfaceContainer': material.surfaceContainer.toARGB32(),
      'surfaceContainerLow': material.surfaceContainerLow.toARGB32(),
      'surfaceContainerHigh': material.surfaceContainerHigh.toARGB32(),
      'surfaceContainerHighest': material.surfaceContainerHighest.toARGB32(),
      'surfaceContainerLowest': material.surfaceContainerLowest.toARGB32(),
      'surfaceBright': material.surfaceBright.toARGB32(),
      'surfaceDim': material.surfaceDim.toARGB32(),
      'outline': material.outline.toARGB32(),
      'outlineVariant': material.outlineVariant.toARGB32(),
      'scrim': material.scrim.toARGB32(),
      'surfaceTint': material.surfaceTint.toARGB32(),
      'inverseSurface': material.inverseSurface.toARGB32(),
      'onInverseSurface': material.onInverseSurface.toARGB32(),
      'primaryFixed': material.primaryFixed.toARGB32(),
      'primaryFixedDim': material.primaryFixedDim.toARGB32(),
      'onPrimaryFixed': material.onPrimaryFixed.toARGB32(),
      'onPrimaryFixedVariant': material.onPrimaryFixedVariant.toARGB32(),
      'secondaryFixed': material.secondaryFixed.toARGB32(),
      'secondaryFixedDim': material.secondaryFixedDim.toARGB32(),
      'onSecondaryFixed': material.onSecondaryFixed.toARGB32(),
      'onSecondaryFixedVariant': material.onSecondaryFixedVariant.toARGB32(),
      'tertiaryFixed': material.tertiaryFixed.toARGB32(),
      'tertiaryFixedDim': material.tertiaryFixedDim.toARGB32(),
      'onTertiaryFixed': material.onTertiaryFixed.toARGB32(),
      'onTertiaryFixedVariant': material.onTertiaryFixedVariant.toARGB32(),
      'background': material.surface.toARGB32(),
      'onBackground': material.onSurface.toARGB32(),
    },
    'miuixColors': {
      'primary': miuixColors.primary.toARGB32(),
      'onPrimary': miuixColors.onPrimary.toARGB32(),
      'primaryVariant': miuixColors.primaryVariant.toARGB32(),
      'onPrimaryVariant': miuixColors.onPrimaryVariant.toARGB32(),
      'error': miuixColors.error.toARGB32(),
      'onError': miuixColors.onError.toARGB32(),
      'errorContainer': miuixColors.errorContainer.toARGB32(),
      'onErrorContainer': miuixColors.onErrorContainer.toARGB32(),
      'disabledPrimary': miuixColors.disabledPrimary.toARGB32(),
      'disabledOnPrimary': miuixColors.disabledOnPrimary.toARGB32(),
      'disabledPrimaryButton': miuixColors.disabledPrimaryButton.toARGB32(),
      'disabledOnPrimaryButton': miuixColors.disabledOnPrimaryButton.toARGB32(),
      'disabledPrimarySlider': miuixColors.disabledPrimarySlider.toARGB32(),
      'primaryContainer': miuixColors.primaryContainer.toARGB32(),
      'onPrimaryContainer': miuixColors.onPrimaryContainer.toARGB32(),
      'secondary': miuixColors.secondary.toARGB32(),
      'onSecondary': miuixColors.onSecondary.toARGB32(),
      'secondaryVariant': miuixColors.secondaryVariant.toARGB32(),
      'onSecondaryVariant': miuixColors.onSecondaryVariant.toARGB32(),
      'disabledSecondary': miuixColors.disabledSecondary.toARGB32(),
      'disabledOnSecondary': miuixColors.disabledOnSecondary.toARGB32(),
      'disabledSecondaryVariant': miuixColors.disabledSecondaryVariant
          .toARGB32(),
      'disabledOnSecondaryVariant': miuixColors.disabledOnSecondaryVariant
          .toARGB32(),
      'secondaryContainer': miuixColors.secondaryContainer.toARGB32(),
      'onSecondaryContainer': miuixColors.onSecondaryContainer.toARGB32(),
      'secondaryContainerVariant': miuixColors.secondaryContainerVariant
          .toARGB32(),
      'onSecondaryContainerVariant': miuixColors.onSecondaryContainerVariant
          .toARGB32(),
      'tertiaryContainer': miuixColors.tertiaryContainer.toARGB32(),
      'onTertiaryContainer': miuixColors.onTertiaryContainer.toARGB32(),
      'tertiaryContainerVariant': miuixColors.tertiaryContainerVariant
          .toARGB32(),
      'background': miuixColors.background.toARGB32(),
      'onBackground': miuixColors.onBackground.toARGB32(),
      'onBackgroundVariant': miuixColors.onBackgroundVariant.toARGB32(),
      'surface': miuixColors.surface.toARGB32(),
      'onSurface': miuixColors.onSurface.toARGB32(),
      'surfaceVariant': miuixColors.surfaceVariant.toARGB32(),
      'onSurfaceSecondary': miuixColors.onSurfaceSecondary.toARGB32(),
      'onSurfaceVariantSummary': miuixColors.onSurfaceVariantSummary.toARGB32(),
      'onSurfaceVariantActions': miuixColors.onSurfaceVariantActions.toARGB32(),
      'disabledOnSurface': miuixColors.disabledOnSurface.toARGB32(),
      'surfaceContainer': miuixColors.surfaceContainer.toARGB32(),
      'onSurfaceContainer': miuixColors.onSurfaceContainer.toARGB32(),
      'onSurfaceContainerVariant': miuixColors.onSurfaceContainerVariant
          .toARGB32(),
      'surfaceContainerHigh': miuixColors.surfaceContainerHigh.toARGB32(),
      'onSurfaceContainerHigh': miuixColors.onSurfaceContainerHigh.toARGB32(),
      'surfaceContainerHighest': miuixColors.surfaceContainerHighest.toARGB32(),
      'onSurfaceContainerHighest': miuixColors.onSurfaceContainerHighest
          .toARGB32(),
      'outline': miuixColors.outline.toARGB32(),
      'dividerLine': miuixColors.dividerLine.toARGB32(),
      'windowDimming': miuixColors.windowDimming.toARGB32(),
      'sliderKeyPoint': miuixColors.sliderKeyPoint.toARGB32(),
      'sliderKeyPointForeground': miuixColors.sliderKeyPointForeground
          .toARGB32(),
      'sliderBackground': miuixColors.sliderBackground.toARGB32(),
    },
  };

  @override
  DeadlinerColorTheme copyWith({
    ColorScheme? material,
    miuix.MiuixColors? miuixColors,
    Color? textFieldContainer,
    Color? seed,
    bool? useMonet,
  }) => DeadlinerColorTheme._(
    material: material ?? this.material,
    miuixColors: miuixColors ?? this.miuixColors,
    textFieldContainer: textFieldContainer ?? this.textFieldContainer,
    seed: seed ?? this.seed,
    useMonet: useMonet ?? this.useMonet,
  );
  @override
  DeadlinerColorTheme lerp(covariant DeadlinerColorTheme? other, double t) {
    if (other == null || identical(other, this)) return this;
    return DeadlinerColorTheme._(
      material: ColorScheme.lerp(material, other.material, t),
      seed: Color.lerp(seed, other.seed, t)!,
      useMonet: t < .5 ? useMonet : other.useMonet,
      textFieldContainer: Color.lerp(
        textFieldContainer,
        other.textFieldContainer,
        t,
      )!,
      miuixColors: miuixColors.copy(
        primary: Color.lerp(miuixColors.primary, other.miuixColors.primary, t)!,
        onPrimary: Color.lerp(
          miuixColors.onPrimary,
          other.miuixColors.onPrimary,
          t,
        )!,
        primaryVariant: Color.lerp(
          miuixColors.primaryVariant,
          other.miuixColors.primaryVariant,
          t,
        )!,
        onPrimaryVariant: Color.lerp(
          miuixColors.onPrimaryVariant,
          other.miuixColors.onPrimaryVariant,
          t,
        )!,
        error: Color.lerp(miuixColors.error, other.miuixColors.error, t)!,
        onError: Color.lerp(miuixColors.onError, other.miuixColors.onError, t)!,
        errorContainer: Color.lerp(
          miuixColors.errorContainer,
          other.miuixColors.errorContainer,
          t,
        )!,
        onErrorContainer: Color.lerp(
          miuixColors.onErrorContainer,
          other.miuixColors.onErrorContainer,
          t,
        )!,
        disabledPrimary: Color.lerp(
          miuixColors.disabledPrimary,
          other.miuixColors.disabledPrimary,
          t,
        )!,
        disabledOnPrimary: Color.lerp(
          miuixColors.disabledOnPrimary,
          other.miuixColors.disabledOnPrimary,
          t,
        )!,
        disabledPrimaryButton: Color.lerp(
          miuixColors.disabledPrimaryButton,
          other.miuixColors.disabledPrimaryButton,
          t,
        )!,
        disabledOnPrimaryButton: Color.lerp(
          miuixColors.disabledOnPrimaryButton,
          other.miuixColors.disabledOnPrimaryButton,
          t,
        )!,
        disabledPrimarySlider: Color.lerp(
          miuixColors.disabledPrimarySlider,
          other.miuixColors.disabledPrimarySlider,
          t,
        )!,
        primaryContainer: Color.lerp(
          miuixColors.primaryContainer,
          other.miuixColors.primaryContainer,
          t,
        )!,
        onPrimaryContainer: Color.lerp(
          miuixColors.onPrimaryContainer,
          other.miuixColors.onPrimaryContainer,
          t,
        )!,
        secondary: Color.lerp(
          miuixColors.secondary,
          other.miuixColors.secondary,
          t,
        )!,
        onSecondary: Color.lerp(
          miuixColors.onSecondary,
          other.miuixColors.onSecondary,
          t,
        )!,
        secondaryVariant: Color.lerp(
          miuixColors.secondaryVariant,
          other.miuixColors.secondaryVariant,
          t,
        )!,
        onSecondaryVariant: Color.lerp(
          miuixColors.onSecondaryVariant,
          other.miuixColors.onSecondaryVariant,
          t,
        )!,
        disabledSecondary: Color.lerp(
          miuixColors.disabledSecondary,
          other.miuixColors.disabledSecondary,
          t,
        )!,
        disabledOnSecondary: Color.lerp(
          miuixColors.disabledOnSecondary,
          other.miuixColors.disabledOnSecondary,
          t,
        )!,
        disabledSecondaryVariant: Color.lerp(
          miuixColors.disabledSecondaryVariant,
          other.miuixColors.disabledSecondaryVariant,
          t,
        )!,
        disabledOnSecondaryVariant: Color.lerp(
          miuixColors.disabledOnSecondaryVariant,
          other.miuixColors.disabledOnSecondaryVariant,
          t,
        )!,
        secondaryContainer: Color.lerp(
          miuixColors.secondaryContainer,
          other.miuixColors.secondaryContainer,
          t,
        )!,
        onSecondaryContainer: Color.lerp(
          miuixColors.onSecondaryContainer,
          other.miuixColors.onSecondaryContainer,
          t,
        )!,
        secondaryContainerVariant: Color.lerp(
          miuixColors.secondaryContainerVariant,
          other.miuixColors.secondaryContainerVariant,
          t,
        )!,
        onSecondaryContainerVariant: Color.lerp(
          miuixColors.onSecondaryContainerVariant,
          other.miuixColors.onSecondaryContainerVariant,
          t,
        )!,
        tertiaryContainer: Color.lerp(
          miuixColors.tertiaryContainer,
          other.miuixColors.tertiaryContainer,
          t,
        )!,
        onTertiaryContainer: Color.lerp(
          miuixColors.onTertiaryContainer,
          other.miuixColors.onTertiaryContainer,
          t,
        )!,
        tertiaryContainerVariant: Color.lerp(
          miuixColors.tertiaryContainerVariant,
          other.miuixColors.tertiaryContainerVariant,
          t,
        )!,
        background: Color.lerp(
          miuixColors.background,
          other.miuixColors.background,
          t,
        )!,
        onBackground: Color.lerp(
          miuixColors.onBackground,
          other.miuixColors.onBackground,
          t,
        )!,
        onBackgroundVariant: Color.lerp(
          miuixColors.onBackgroundVariant,
          other.miuixColors.onBackgroundVariant,
          t,
        )!,
        surface: Color.lerp(miuixColors.surface, other.miuixColors.surface, t)!,
        onSurface: Color.lerp(
          miuixColors.onSurface,
          other.miuixColors.onSurface,
          t,
        )!,
        surfaceVariant: Color.lerp(
          miuixColors.surfaceVariant,
          other.miuixColors.surfaceVariant,
          t,
        )!,
        onSurfaceSecondary: Color.lerp(
          miuixColors.onSurfaceSecondary,
          other.miuixColors.onSurfaceSecondary,
          t,
        )!,
        onSurfaceVariantSummary: Color.lerp(
          miuixColors.onSurfaceVariantSummary,
          other.miuixColors.onSurfaceVariantSummary,
          t,
        )!,
        onSurfaceVariantActions: Color.lerp(
          miuixColors.onSurfaceVariantActions,
          other.miuixColors.onSurfaceVariantActions,
          t,
        )!,
        disabledOnSurface: Color.lerp(
          miuixColors.disabledOnSurface,
          other.miuixColors.disabledOnSurface,
          t,
        )!,
        surfaceContainer: Color.lerp(
          miuixColors.surfaceContainer,
          other.miuixColors.surfaceContainer,
          t,
        )!,
        onSurfaceContainer: Color.lerp(
          miuixColors.onSurfaceContainer,
          other.miuixColors.onSurfaceContainer,
          t,
        )!,
        onSurfaceContainerVariant: Color.lerp(
          miuixColors.onSurfaceContainerVariant,
          other.miuixColors.onSurfaceContainerVariant,
          t,
        )!,
        surfaceContainerHigh: Color.lerp(
          miuixColors.surfaceContainerHigh,
          other.miuixColors.surfaceContainerHigh,
          t,
        )!,
        onSurfaceContainerHigh: Color.lerp(
          miuixColors.onSurfaceContainerHigh,
          other.miuixColors.onSurfaceContainerHigh,
          t,
        )!,
        surfaceContainerHighest: Color.lerp(
          miuixColors.surfaceContainerHighest,
          other.miuixColors.surfaceContainerHighest,
          t,
        )!,
        onSurfaceContainerHighest: Color.lerp(
          miuixColors.onSurfaceContainerHighest,
          other.miuixColors.onSurfaceContainerHighest,
          t,
        )!,
        outline: Color.lerp(miuixColors.outline, other.miuixColors.outline, t)!,
        dividerLine: Color.lerp(
          miuixColors.dividerLine,
          other.miuixColors.dividerLine,
          t,
        )!,
        windowDimming: Color.lerp(
          miuixColors.windowDimming,
          other.miuixColors.windowDimming,
          t,
        )!,
        sliderKeyPoint: Color.lerp(
          miuixColors.sliderKeyPoint,
          other.miuixColors.sliderKeyPoint,
          t,
        )!,
        sliderKeyPointForeground: Color.lerp(
          miuixColors.sliderKeyPointForeground,
          other.miuixColors.sliderKeyPointForeground,
          t,
        )!,
        sliderBackground: Color.lerp(
          miuixColors.sliderBackground,
          other.miuixColors.sliderBackground,
          t,
        )!,
      ),
    );
  }
}
