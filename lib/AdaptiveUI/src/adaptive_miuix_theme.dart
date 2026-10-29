import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'theme/deadliner_color_theme.dart';
import 'adaptive_typography.dart';

class AdaptiveMiuixTheme extends StatelessWidget {
  const AdaptiveMiuixTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DeadlinerColorTheme.of(theme);
    return miuix.MiuixTheme(
      data: miuix.MiuixThemeData.of(
        theme.brightness,
        lightColors: palette.miuixColors,
        darkColors: palette.miuixColors,
        textStyles: miuix.defaultTextStyles().copy(
          main: AdaptiveTypography.item,
          paragraph: AdaptiveTypography.body,
          body1: AdaptiveTypography.item,
          body2: AdaptiveTypography.body,
          button: AdaptiveTypography.action,
          headline1: AdaptiveTypography.item,
          headline2: AdaptiveTypography.item,
          footnote1: AdaptiveTypography.caption,
          subtitle: AdaptiveTypography.section,
          title3: AdaptiveTypography.title,
        ),
        fontWeightAdjustment: MediaQuery.boldTextOf(context) ? 100 : 0,
      ),
      child: child,
    );
  }
}
