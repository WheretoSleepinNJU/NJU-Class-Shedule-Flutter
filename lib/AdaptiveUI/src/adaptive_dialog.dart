import 'package:flutter/material.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;
import 'adaptive_ui_controller.dart';
import 'theme/deadliner_color_theme.dart';
import 'package:flutter_miuix/miuix.dart' as miuix;
import 'dart:math' as math;

/// Arbitrary form content using the MIUIX popup on Android and the existing
/// iOS dialog. The Flutter route retains results, barriers and navigation.
/// Renderer selection stays here, never in the caller's page or form.
class AdaptiveDialog extends AlertDialog {
  const AdaptiveDialog({
    super.key,
    this.platformAdaptive = false,
    super.title,
    super.content,
    super.actions,
    super.icon,
    super.iconPadding,
    super.iconColor,
    super.titlePadding,
    super.titleTextStyle,
    super.contentPadding,
    super.contentTextStyle,
    super.actionsPadding,
    super.actionsAlignment,
    super.actionsOverflowAlignment,
    super.actionsOverflowDirection,
    super.actionsOverflowButtonSpacing,
    super.buttonPadding,
    super.backgroundColor,
    super.elevation,
    super.shadowColor,
    super.surfaceTintColor,
    super.semanticLabel,
    super.insetPadding,
    super.clipBehavior,
    super.shape,
    super.alignment,
    super.constraints,
    super.scrollable,
  });

  final bool platformAdaptive;

  @override
  Widget build(BuildContext context) {
    if (platformAdaptive && platform.PlatformInfo.isIOS) {
      return AlertDialog.adaptive(
        title: title,
        content: content,
        actions: actions,
        icon: icon,
        iconPadding: iconPadding,
        iconColor: iconColor,
        titlePadding: titlePadding,
        titleTextStyle: titleTextStyle,
        contentPadding: contentPadding,
        contentTextStyle: contentTextStyle,
        actionsPadding: actionsPadding,
        actionsAlignment: actionsAlignment,
        actionsOverflowAlignment: actionsOverflowAlignment,
        actionsOverflowDirection: actionsOverflowDirection,
        actionsOverflowButtonSpacing: actionsOverflowButtonSpacing,
        buttonPadding: buttonPadding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        semanticLabel: semanticLabel,
        insetPadding:
            insetPadding ??
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        clipBehavior: clipBehavior,
        shape: shape,
        alignment: alignment,
        constraints: constraints,
        scrollable: scrollable,
      );
    }
    final built = super.build(context);
    if (built is! Dialog) return built;
    return _AdaptiveDialogPresentation(dialog: built);
  }
}

/// A custom dialog body can use the same popup without choosing a platform.
class AdaptiveDialogFrame extends Dialog {
  const AdaptiveDialogFrame({
    super.key,
    super.child,
    super.backgroundColor,
    super.elevation,
    super.shadowColor,
    super.surfaceTintColor,
    super.insetPadding,
    super.clipBehavior,
    super.shape,
    super.alignment,
    super.constraints,
  });
  @override
  Widget build(BuildContext context) => _AdaptiveDialogPresentation(
    dialog: Dialog(
      child: child,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      alignment: alignment,
      constraints: constraints,
    ),
  );
}

/// A modal retains its chosen renderer until dismissal. Reparenting an arbitrary
/// form into/out of a registered popup would otherwise discard editing state.
class _AdaptiveDialogPresentation extends StatefulWidget {
  const _AdaptiveDialogPresentation({required this.dialog});
  final Dialog dialog;
  @override
  State<_AdaptiveDialogPresentation> createState() =>
      _AdaptiveDialogPresentationState();
}

class _AdaptiveDialogPresentationState
    extends State<_AdaptiveDialogPresentation> {
  bool? _miuix;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _miuix ??= AdaptiveUIScope.usesMiuix(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_miuix!) return widget.dialog;
    final route = ModalRoute.of(context);
    final media = MediaQuery.of(context);
    final safe = media.padding;
    final keyboard = math.max(0.0, media.viewInsets.bottom);
    // DialogRoute may already consume system safe areas while MediaQuery.size
    // still describes the entire window. Bound the form by the actual viewport.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = math.max(
          0.0,
          constraints.maxHeight -
              safe.top -
              math.max(safe.bottom, keyboard) -
              24,
        );
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - safe.horizontal - 24,
        );
        final requested = widget.dialog.constraints;
        final preferredWidth = requested?.constrainWidth(560) ?? 560.0;
        final dialogWidth = math.min(
          availableWidth,
          preferredWidth.isFinite ? preferredWidth : 560.0,
        );
        return miuix.MiuixPopupScope(
          establishRoot: true,
          child: miuix.MiuixPopupHost(
            windowDimmingColor: DeadlinerColorTheme.of(
              Theme.of(context),
            ).miuixColors.windowDimming,
            child: miuix.MiuixOverlayDialog(
              show: true,
              backgroundColor:
                  widget.dialog.backgroundColor ??
                  Theme.of(context).dialogTheme.backgroundColor,
              enableWindowDim: false,
              insideMargin: Size.zero,
              maxWidth: dialogWidth,
              onDismissRequest: route is PopupRoute && route.barrierDismissible
                  ? () => Navigator.of(context).maybePop()
                  : null,
              content: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: widget.dialog.child!,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
