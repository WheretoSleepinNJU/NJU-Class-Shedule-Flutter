import 'package:flutter/material.dart';

class mDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  mDialog(this.title, this.content, this.actions);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: Text(title),
      content: content,
      actions: actions,
    );
  }
}
