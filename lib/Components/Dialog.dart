import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import './TransBgTextButton.dart';

class MDialog extends StatelessWidget {
  // Keep dialog controls usable at the largest accessibility sizes while
  // enlarging titles, content, and actions together. The page is unaffected.
  static const maxTextScale = 2.0;

  final String title;
  final Widget content;
  final List<Widget>? overrideActions;
  final Widget? widgetOK;
  final VoidCallback? widgetOKAction;
  final Widget? widgetCancel;
  final VoidCallback? widgetCancelAction;

  const MDialog(
    this.title,
    this.content, {
    this.overrideActions,
    this.widgetOK,
    this.widgetOKAction,
    this.widgetCancel,
    this.widgetCancelAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // iOS keyboard transitions can briefly report a negative inset. Dialog's
    // AnimatedPadding requires nonnegative values, including during dismissal.
    final insets = media.viewInsets;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: EdgeInsets.fromLTRB(
          insets.left.clamp(0.0, double.infinity),
          insets.top.clamp(0.0, double.infinity),
          insets.right.clamp(0.0, double.infinity),
          insets.bottom.clamp(0.0, double.infinity),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            scrollable: true,
            title: Text(title, softWrap: true),
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
            content: content,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsAlignment: MainAxisAlignment.end,
            actionsOverflowAlignment: OverflowBarAlignment.end,
            actionsOverflowButtonSpacing: 8,
            actions:
                overrideActions ??
                [
                  if (widgetCancelAction != null)
                    TransBgTextButton(
                      color: Colors.grey,
                      onPressed: widgetCancelAction,
                      child: widgetCancel ?? Text(S.of(context).cancel),
                    ),
                  TransBgTextButton(
                    color:
                        Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                    onPressed: widgetOKAction,
                    child: widgetOK ?? Text(S.of(context).ok),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
