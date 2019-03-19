import 'package:flutter/material.dart';
import '../Resources/Strings.dart';
import '../Import/ImportView.dart';

class SettingsView extends StatefulWidget {
  SettingsView() : super();
  final String title = 'Settings';

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[
            ListTile(
              title: Text(Strings.import_from_NJU_title),
              subtitle: Text(Strings.import_from_NJU_subtitle),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => ImportView()));
              },
            )
          ],
        ));
  }
}
