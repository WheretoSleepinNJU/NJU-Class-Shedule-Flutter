import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

/// Native-only metadata stays in AdaptiveUI rather than page platform branches.
class NativeTopBarAction extends AdaptiveAppBarAction {
  const NativeTopBarAction({
    super.icon,
    super.iosSymbol,
    super.title,
    super.label,
    required super.onPressed,
    super.prominent,
    super.tintColor,
    super.enabled,
    super.loading,
  });
}

class NativeTopBarConfiguration extends AdaptiveAppBar {
  const NativeTopBarConfiguration({
    super.title,
    super.tabLabels,
    super.selectedTabIndex,
    super.tabRowHeight,
    super.onTabSelected,
    super.actions,
    super.onTitleTap,
    super.textScale,
    super.subtitle,
    super.leadingTitle,
    super.semanticLabel,
    super.foreground,
    super.toolbarHeight,
    super.systemOverlayStyle,
  }) : super(nativeTitleLayout: true);
}

String nativeSymbolForIcon(IconData icon) =>
    {
      Icons.settings: 'gearshape',
      Icons.add: 'plus',
      Icons.add_rounded: 'plus',
      Icons.refresh: 'arrow.clockwise',
      Icons.play_arrow: 'play.fill',
      Icons.delete_outline: 'trash',
      Icons.delete: 'trash',
      Icons.info_outline: 'info.circle',
      Icons.info: 'info.circle',
      Icons.close: 'xmark',
      Icons.share: 'square.and.arrow.up',
      Icons.edit: 'pencil',
      Icons.check: 'checkmark',
      Icons.search: 'magnifyingglass',
      Icons.more_vert: 'ellipsis',
    }[icon] ??
    'circle';

abstract interface class AdaptiveNativeTitle {
  NativeTitleContent nativeTitleContent(BuildContext context);
}

class NativeTitleContent {
  const NativeTitleContent({
    required this.title,
    this.subtitle,
    this.onTap,
    this.semanticLabel,
    this.foreground,
    this.textScale,
  });
  final String title;
  final String? subtitle, semanticLabel;
  final VoidCallback? onTap;
  final Color? foreground;
  final double? textScale;
}
