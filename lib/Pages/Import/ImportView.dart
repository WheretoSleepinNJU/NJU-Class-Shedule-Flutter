import '../../generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../Import/ImportFromJWView.dart';
import '../Import/ImportFromCerView.dart';
import '../Import/ImportFromXKView.dart';
import '../Import/ImportFromBEView.dart';

class ImportView extends StatefulWidget {
  ImportView() : super();

  @override
  _ImportViewState createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).settings_title),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            SingleChildScrollView(
                child: Column(
                    children: ListTile.divideTiles(context: context, tiles: [
              ListTile(
                title: Text(S.of(context).import_from_NJU_title),
                subtitle: Text(S.of(context).import_from_NJU_subtitle),
                onTap: () async {
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) => ImportFromJWView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              ListTile(
                title: Text(S.of(context).import_from_NJU_cer_title),
                subtitle: Text(S.of(context).import_from_NJU_cer_subtitle),
                onTap: () async {
                  bool status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ImportFromCerView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              ListTile(
                title: Text(S.of(context).import_from_NJU_xk_title),
                subtitle: Text(S.of(context).import_from_NJU_xk_subtitle),
                onTap: () async {
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ImportFromXKView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              ListTile(
                title: Text(S.of(context).import_from_NJU_xk_title),
                subtitle: Text(S.of(context).import_from_NJU_xk_subtitle),
                onTap: () async {
                  bool? status = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              ImportFromBEView()));
                  if (status == true) Navigator.of(context).pop(status);
                },
              ),
              // ListTile(
              //   title: Text(S.of(context).import_or_export_title),
              //   subtitle: Text(S.of(context).import_or_export_subtitle),
              //   onTap: () {
              //     Navigator.of(context).push(MaterialPageRoute(
              //         builder: (BuildContext context) => ShareView()));
              //   },
              // ),
              
            ]).toList())),
          ],
        )));
  }
}
