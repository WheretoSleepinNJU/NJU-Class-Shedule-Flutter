import 'dart:io';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adaptive_ui_controller.dart';

/// Declarative top-bar content. Arbitrary titles/actions keep their original
/// layout through an internal compatibility renderer; pages never select it.
class AdaptiveTopAppBar {
  const AdaptiveTopAppBar({
    this.title,
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
  final Widget? title, leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final IconThemeData? iconTheme;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final double? titleSpacing, toolbarHeight;

  bool get _simple =>
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
  AppBar _material() => AppBar(
    title: title,
    actions: actions,
    leading: leading,
    backgroundColor: backgroundColor,
    systemOverlayStyle: systemOverlayStyle,
    iconTheme: iconTheme,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    titleSpacing: titleSpacing,
    toolbarHeight: toolbarHeight,
  );
}

class AdaptiveScaffold extends StatelessWidget {
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
    this.scrollUnderAppBar = false,
  });
  final AdaptiveTopAppBar? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar, extendBody, scrollUnderAppBar;
  @override
  Widget build(BuildContext context) {
    final original =
        AdaptiveUIScope.maybeOf(context)?.useOriginalComponents ?? false;
    final fallback =
        appBar?._simple == false ||
        bottomNavigationBar != null ||
        (original && !platform.PlatformInfo.isIOS);
    final bar = appBar?._configuration(native: !fallback);
    final backend = platform.AndroidToolbarScope.maybeOf(context);
    final nativeAndroid =
        bar != null && backend != null && backend.supports(bar) && !fallback;
    final resize =
        resizeToAvoidBottomInset ?? AdaptiveKeyboardInsets.resizesPage;
    return platform.AdaptiveScaffold(
      appBar: bar,
      resizeToAvoidBottomInset: resize,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      extendBodyBehindAppBar:
          extendBodyBehindAppBar || (scrollUnderAppBar && nativeAndroid),
      extendBody: extendBody,
      body: body,
      fallbackBuilder: fallback
          ? (context, content) => Scaffold(
              appBar: appBar?._material(),
              body: content,
              resizeToAvoidBottomInset: resize,
              backgroundColor: backgroundColor,
              floatingActionButton: floatingActionButton,
              bottomNavigationBar: bottomNavigationBar,
              extendBodyBehindAppBar: extendBodyBehindAppBar,
              extendBody: extendBody,
            )
          : null,
    );
  }
}

abstract final class AdaptiveKeyboardInsets {
  static bool get resizesPage => Platform.operatingSystem != 'ohos';
  static double bottomOf(BuildContext context) =>
      resizesPage ? 0 : MediaQuery.viewInsetsOf(context).bottom;
}
