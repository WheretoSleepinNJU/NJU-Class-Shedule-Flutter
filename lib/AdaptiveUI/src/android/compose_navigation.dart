import 'package:flutter/material.dart';
import '../native_navigation.dart';

class ComposeNavigation extends NativeNavigation {
  const ComposeNavigation({
    super.key,
    required super.items,
    required super.selectedIndex,
    required super.visible,
    required super.onSelected,
    required super.fallback,
    super.channelName = 'nju/compose-navigation',
    super.contentPadding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 3,
    ),
  });
}

/// Independent native slot; the root shares its backdrop and input lifecycle.
class ComposeTabRow extends ComposeNavigation {
  ComposeTabRow({
    super.key,
    required List<String> labels,
    required super.selectedIndex,
    required super.visible,
    required super.onSelected,
    required super.fallback,
  }) : super(
         items: [
           for (final label in labels) {'label': label, 'icon': ''},
         ],
         channelName: 'nju/compose-tabs',
         contentPadding: const EdgeInsets.all(3),
       );
}
