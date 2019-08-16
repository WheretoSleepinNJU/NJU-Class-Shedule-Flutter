import 'package:flutter/material.dart';
import '../../Resources/Strings.dart';

class AboutView extends StatelessWidget {
  AboutView() : super();
  final String title = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          Container(
            padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
            child: Text('GitHub 开源'),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
            child: Text('GitHub 开源\nQAQ'),
          )
        ]))
//    )
        );
  }
}
