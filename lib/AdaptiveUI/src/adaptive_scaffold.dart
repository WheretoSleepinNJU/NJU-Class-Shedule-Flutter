import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adaptive_ui_controller.dart';
import 'adaptive_content.dart';
import 'adaptive_navigation.dart';
import 'theme/deadliner_color_theme.dart';
import 'android/compose_glass_surface.dart';
import 'native_top_bar_configuration.dart';

/// Declarative top-bar content. Arbitrary titles/actions keep their original
/// layout through an internal compatibility renderer; pages never select it.
class AdaptiveTopAppBar {
  const AdaptiveTopAppBar({
    this.title,
    this.preserveLayout = false,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.systemOverlayStyle,
    this.iconTheme,
    this.centerTitle,
    this.automaticallyImplyLeading = true,
    this.titleSpacing,
    this.toolbarHeight,
  });

  /// Preserve a floating/custom header layout, with native glass icon actions.
  final bool preserveLayout;
  final Widget? title, leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final IconThemeData? iconTheme;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final double? titleSpacing, toolbarHeight;

  bool get _simple =>
      !preserveLayout &&
      (title == null ||
          (title is Text &&
              (title as Text).data != null &&
              (title as Text).style == null)) &&
      leading == null &&
      automaticallyImplyLeading &&
      backgroundColor == null &&
      systemOverlayStyle == null &&
      iconTheme == null &&
      toolbarHeight == null &&
      (actions ?? const []).every(
        (action) =>
            action is IconButton &&
            action.key == null &&
            action.onPressed != null &&
            action.icon is Icon &&
            (action.icon as Icon).icon?.fontFamily == 'MaterialIcons',
      );

  NativeTopBarConfiguration? _nativeConfiguration(
    BuildContext context, {
    bool preservesTitleLayout = false,
  }) {
    if (leading != null ||
        (!preservesTitleLayout &&
            (preserveLayout ||
                !automaticallyImplyLeading ||
                toolbarHeight != null))) {
      return null;
    }
    final titleWidget = title;
    Text? text;
    VoidCallback? titleTap;
    NativeTitleContent? titleContent;
    if (titleWidget is AdaptiveNativeTitle) {
      titleContent = (titleWidget as AdaptiveNativeTitle).nativeTitleContent(
        context,
      );
      text = Text(titleContent.title);
      titleTap = titleContent.onTap;
    } else if (titleWidget is Text) {
      text = titleWidget;
    } else if (titleWidget is GestureDetector && titleWidget.child is Text) {
      text = titleWidget.child as Text;
      titleTap = titleWidget.onTap;
    } else if (titleWidget != null) {
      return null;
    }
    if (text != null && text.data == null) return null;
    final converted = <NativeTopBarAction>[];
    for (final action in actions ?? const <Widget>[]) {
      if (action is SizedBox && action.child == null) continue;
      if (action is AdaptiveTopBarActionButton) {
        converted.add(
          NativeTopBarAction(
            title: action.label,
            label: action.label,
            onPressed: action.onPressed ?? _ignoreAction,
            enabled: action.onPressed != null,
            loading: action.loading,
            prominent: action.prominent,
            tintColor: action.prominent
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        );
      } else if (action is TextButton &&
          action.child is Text &&
          (action.child as Text).data != null) {
        final label = (action.child as Text).data!;
        converted.add(
          NativeTopBarAction(
            title: label,
            label: label,
            onPressed: action.onPressed ?? _ignoreAction,
            enabled: action.onPressed != null,
          ),
        );
      } else if (action is IconButton &&
          action.icon is Icon &&
          (action.icon as Icon).icon?.fontFamily == 'MaterialIcons') {
        converted.add(
          NativeTopBarAction(
            icon: (action.icon as Icon).icon,
            iosSymbol: nativeSymbolForIcon((action.icon as Icon).icon!),
            label: action.tooltip,
            onPressed: action.onPressed ?? _ignoreAction,
            enabled: action.onPressed != null,
          ),
        );
      } else {
        return null;
      }
    }
    return NativeTopBarConfiguration(
      title: text?.data,
      onTitleTap: titleTap,
      actions: converted,
      textScale:
          titleContent?.textScale ??
          MediaQuery.textScalerOf(context).scale(16) / 16,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle:
          systemOverlayStyle ??
          Theme.of(context).appBarTheme.systemOverlayStyle,
      subtitle: titleContent?.subtitle,
      leadingTitle: preserveLayout,
      semanticLabel: titleContent?.semanticLabel,
      foreground:
          titleContent?.foreground ??
          iconTheme?.color ??
          Theme.of(context).colorScheme.onSurface,
    );
  }

  static void _ignoreAction() {}

  platform.AdaptiveAppBar _configuration({required bool native}) =>
      platform.AdaptiveAppBar(
        title: title is Text ? (title as Text).data : null,
        titleWidget: title is Text ? null : title,
        useNativeToolbar: native,
        actions: native
            ? [
                for (final action in actions ?? const <Widget>[])
                  if (action is IconButton)
                    platform.AdaptiveAppBarAction(
                      icon: (action.icon as Icon).icon,
                      label: action.tooltip,
                      onPressed: action.onPressed!,
                    ),
              ]
            : null,
      );
  AppBar _material(BuildContext context, {bool glass = false}) => AppBar(
    title: title,
    actions: [
      for (final action in actions ?? const <Widget>[])
        if (glass &&
            preserveLayout &&
            action is IconButton &&
            action.icon is Icon &&
            (action.icon as Icon).icon?.fontFamily == 'MaterialIcons')
          _ComposeTopBarIconButton(button: action, foreground: iconTheme?.color)
        else
          action,
    ],
    leading: leading,
    backgroundColor: glass && !preserveLayout
        ? Colors.transparent
        : backgroundColor,
    forceMaterialTransparency: glass && !preserveLayout,
    elevation: glass && !preserveLayout ? 0 : null,
    scrolledUnderElevation: glass && !preserveLayout ? 0 : null,
    surfaceTintColor: glass && !preserveLayout ? Colors.transparent : null,
    systemOverlayStyle:
        systemOverlayStyle ??
        (glass && !preserveLayout
            ? SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: Theme.of(context).brightness,
                systemStatusBarContrastEnforced: false,
              )
            : null),
    iconTheme: iconTheme,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    titleSpacing: titleSpacing,
    toolbarHeight: toolbarHeight,
  );
}

/// The page supplies action state once; AdaptiveUI renders native and original
/// controls from the same label, loading state and callback.
class AdaptiveTopBarActionButton extends StatelessWidget {
  const AdaptiveTopBarActionButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.prominent = false,
  });
  final Key? buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final bool loading, prominent;
  @override
  Widget build(BuildContext context) => TextButton(
    key: buttonKey,
    onPressed: loading ? null : onPressed,
    child: loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.scrollUnderAppBar = true,
  });
  final AdaptiveTopAppBar? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar, extendBody, scrollUnderAppBar;
  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  final _scrollOffset = ValueNotifier<double>(0);
  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AdaptiveEmbeddedPage.contains(context)) {
      return MediaQuery(
        data: MediaQuery.of(context).removePadding(removeBottom: true),
        child: AdaptiveContentInsets(
          top: AdaptiveContentInsets.topOf(context),
          bottom: AdaptiveContentInsets.bottomOf(context),
          child: widget.body ?? const SizedBox.shrink(),
        ),
      );
    }
    final barConfig = widget.appBar;
    final original =
        AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? false;
    final nativeIOS = platform.PlatformInfo.isIOS && barConfig != null;
    final backend = platform.AndroidToolbarScope.maybeOf(context);
    final configuration = barConfig?._nativeConfiguration(
      context,
      preservesTitleLayout: nativeIOS,
    );
    final nativeAndroid =
        !original &&
        backend != null &&
        configuration != null &&
        backend.supports(configuration);
    final fallback =
        nativeIOS ||
        (!nativeAndroid && barConfig?._simple == false) ||
        widget.bottomNavigationBar != null ||
        (original && !platform.PlatformInfo.isIOS);
    final bar = nativeIOS
        ? configuration
        : nativeAndroid
        ? configuration
        : barConfig?._configuration(native: !fallback);
    final glass =
        fallback &&
        !nativeAndroid &&
        !nativeIOS &&
        !original &&
        barConfig != null &&
        AdaptiveUIScope.supportsNativeGlass(context);
    final underUIKit =
        nativeIOS && !barConfig.preserveLayout && widget.scrollUnderAppBar;
    final underGlass =
        (glass && !barConfig.preserveLayout && widget.scrollUnderAppBar) ||
        underUIKit;
    final resize =
        widget.resizeToAvoidBottomInset ?? AdaptiveKeyboardInsets.resizesPage;
    // Material Scaffold removes top viewPadding when it owns an AppBar.
    // Read the window inset before entering its body subtree.
    final statusInset = MediaQuery.viewPaddingOf(context).top;
    final content = Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        final immersiveScroll = widget.scrollUnderAppBar;
        final bottomClearance = widget.bottomNavigationBar != null
            ? 0.0
            : AdaptiveNavigationScope.maybeOf(context) != null
            ? AdaptiveNavigationScope.scrollClearanceOf(context)
            : media.padding.bottom;
        final inset = underGlass
            ? statusInset +
                  (barConfig.toolbarHeight ?? (nativeIOS ? 44 : kToolbarHeight))
            : platform.AndroidToolbarBodyScope.topInsetOf(context);
        return Padding(
          padding: EdgeInsets.only(
            top:
                nativeIOS &&
                    !widget.scrollUnderAppBar &&
                    !widget.extendBodyBehindAppBar
                ? statusInset + (barConfig.toolbarHeight ?? 44)
                : 0,
          ),
          child: MediaQuery(
            data: (underGlass || nativeIOS || nativeAndroid || immersiveScroll)
                ? media.removePadding(
                    removeTop: underGlass || nativeIOS || nativeAndroid,
                    removeBottom: immersiveScroll,
                  )
                : media,
            child: AdaptiveContentInsets(
              top: inset,
              bottom: immersiveScroll ? bottomClearance : null,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 &&
                      notification.metrics.axis == Axis.vertical) {
                    _scrollOffset.value = notification.metrics.pixels.clamp(
                      0.0,
                      double.infinity,
                    );
                  }
                  return false;
                },
                child: miuix.MiuixPopupScope(
                  child: miuix.MiuixPopupHost(
                    windowDimmingColor: DeadlinerColorTheme.of(
                      Theme.of(context),
                    ).miuixColors.windowDimming,
                    child: widget.body ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return platform.AdaptiveScaffold(
      appBar: bar,
      resizeToAvoidBottomInset: resize,
      // CupertinoPageScaffold does not inherit Material scaffold defaults.
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.floatingActionButton,
      extendBodyBehindAppBar:
          widget.extendBodyBehindAppBar ||
          (widget.scrollUnderAppBar && nativeAndroid),
      extendBody: widget.extendBody,
      body: content,
      fallbackUsesNativeToolbar: nativeAndroid,
      fallbackBuilder: fallback
          ? (context, body) => Scaffold(
              appBar: nativeAndroid || nativeIOS || barConfig == null
                  ? null
                  : _AdaptiveFlutterTopBar(
                      foreground: barConfig._material(context, glass: glass),
                      glass: glass && !barConfig.preserveLayout,
                      scrollOffset: _scrollOffset,
                    ),
              body: body,
              resizeToAvoidBottomInset: resize,
              backgroundColor:
                  widget.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              floatingActionButton: widget.floatingActionButton,
              bottomNavigationBar: widget.bottomNavigationBar,
              extendBodyBehindAppBar:
                  widget.extendBodyBehindAppBar || underGlass,
              extendBody: widget.extendBody,
            )
          : null,
    );
  }
}

/// The background can extend beyond the foreground bar, retaining Deadliner's
/// progressive fade without clipping it at AppBar's flexibleSpace boundary.
class _AdaptiveFlutterTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdaptiveFlutterTopBar({
    required this.foreground,
    required this.glass,
    required this.scrollOffset,
  });
  final AppBar foreground;
  final bool glass;
  final ValueNotifier<double> scrollOffset;
  @override
  Size get preferredSize => foreground.preferredSize;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final occupied = math.max(
        constraints.maxHeight,
        MediaQuery.viewPaddingOf(context).top + 56,
      );
      // Canonical resolveProgressiveTopBarHeightMetrics: content fraction .75,
      // with the 6dp material trim and 12dp transparent bottom clearance.
      final materialHeight = math.max(
        occupied,
        (occupied / .75).ceilToDouble() - 18,
      );
      return Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: materialHeight,
            child: ValueListenableBuilder<double>(
              valueListenable: scrollOffset,
              builder: (context, offset, _) => glass
                  ? ComposeGlassSurface(
                      kind: 'topbar',
                      properties: {
                        'scrollOffset': offset,
                        'contentHeight': occupied,
                      },
                      fallback: ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          foreground,
        ],
      );
    },
  );
}

class _ComposeTopBarIconButton extends StatelessWidget {
  const _ComposeTopBarIconButton({required this.button, this.foreground});
  final IconButton button;
  final Color? foreground;
  @override
  Widget build(BuildContext context) {
    final icon = button.icon as Icon;
    final data = icon.icon!;
    final route = ModalRoute.of(context);
    final enabled = button.onPressed != null && (route?.isCurrent ?? true);
    void press() {
      if (route?.isCurrent ?? true) button.onPressed?.call();
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: button.tooltip,
      onTap: enabled ? press : null,
      child: SizedBox(
        width: 48,
        height: 48,
        // Preserve the 48dp action slot/hit area while allowing the canonical
        // 44dp lens and its diffuse shadow to paint beyond that slot.
        child: OverflowBox(
          minWidth: 100,
          maxWidth: 100,
          minHeight: 100,
          maxHeight: 100,
          child: ComposeGlassSurface(
            kind: 'icon',
            onPressed: enabled ? press : null,
            fallback: button,
            properties: {
              'codePoint': data.codePoint,
              'enabled': enabled,
              'foreground':
                  (icon.color ??
                          button.color ??
                          foreground ??
                          Theme.of(context).colorScheme.onSurface)
                      .toARGB32(),
              'mirror': data.matchTextDirection,
            },
          ),
        ),
      ),
    );
  }
}

abstract final class AdaptiveKeyboardInsets {
  static bool get resizesPage => Platform.operatingSystem != 'ohos';
  static double bottomOf(BuildContext context) =>
      resizesPage ? 0 : MediaQuery.viewInsetsOf(context).bottom;
}
