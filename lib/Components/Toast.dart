import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toast {
  static showToast(String text, BuildContext context) {
    Fluttertoast.showToast(
        msg: text,
        backgroundColor: Theme.of(context).primaryColor,
        textColor: Colors.white);
//    Scaffold.of(context).showSnackBar(SnackBar(
//      content: Text(text),
//      backgroundColor: Theme.of(context).primaryColor,
//    ));
  }
}
