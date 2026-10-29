import 'package:flutter/material.dart';

/// Shared content hierarchy. Platform fonts and native chrome remain native;
/// logical sizes scale with the user's accessibility text setting.
abstract final class AdaptiveTypography {
  static const title = TextStyle(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const item = TextStyle(
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const caption = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const action = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
  static const section = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static TextTheme textTheme(TextTheme base) => base.copyWith(
    titleLarge: base.titleLarge?.merge(title),
    titleMedium: base.titleMedium?.merge(item),
    titleSmall: base.titleSmall?.merge(
      body.copyWith(fontWeight: FontWeight.w500),
    ),
    bodyLarge: base.bodyLarge?.merge(item),
    bodyMedium: base.bodyMedium?.merge(body),
    bodySmall: base.bodySmall?.merge(caption),
    labelLarge: base.labelLarge?.merge(action),
    labelMedium: base.labelMedium?.merge(section),
    labelSmall: base.labelSmall?.merge(caption),
  );
}
