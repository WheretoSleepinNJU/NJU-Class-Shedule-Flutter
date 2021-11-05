import 'package:flutter/material.dart';
// import 'package:auto_size_text/auto_size_text.dart';

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
      title:
          // Column(
          //   mainAxisSize: MainAxisSize.min,
          //   children: <Widget>[Container(
          //     child: AutoSizeText(
          //       title,
          //       style: TextStyle(fontSize: 20),
          //       maxLines: 1,
          //     ))]),
          // Expanded(
          //   child: AutoSizeText(
          //   title,
          //   style: TextStyle(fontSize: 20),
          //   maxLines: 1,
          // )),

          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text((title.length <= 15)
                  ? title
                  : '${title.substring(0, 15)}...')),
      content: content,
      actions: actions,
    );
  }
}
