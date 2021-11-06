import '../../generated/l10n.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:azlistview/azlistview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../Import/ImportFromJWView.dart';
import '../Import/ImportFromCerView.dart';
import '../Import/ImportFromXKView.dart';
import '../Import/ImportFromBEView.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';

class School extends ISuspensionBean {
  String name;
  String? tagIndex;
  String? namePinyin;
  Map? config;
  bool? isGrey;

  School(
      {required this.name,
      this.tagIndex,
      this.namePinyin,
      this.config,
      this.isGrey});

  School.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        tagIndex = json['tagIndex'],
        namePinyin = json['namePinyin'],
        config = json['config'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'tagIndex': tagIndex,
        'namePinyin': namePinyin,
        // 'isShowSuspension': isShowSuspension
      };

  @override
  String getSuspensionTag() => tagIndex!;

  @override
  String toString() => json.encode(this);
}

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
          title: Text(S.of(context).import_settings_title),
        ),
        body:
            // SingleChildScrollView(
            //     child:
            Column(
                children: ListTile.divideTiles(context: context, tiles: [
          Container(
            child: Text(S.of(context).import_inline, style: TextStyle()),
            padding: const EdgeInsets.only(left: 15.0, top: 10.0, bottom: 5.0),
            alignment: Alignment.centerLeft,
            color: Color(0xffeeeeee),
          ),
          ListTile(
            title: Text(S.of(context).import_from_NJU_cer_title),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).import_from_NJU_cer_subtitle)),
            onTap: () async {
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      ImportFromCerView(config: Config.jw_config)));
              if (status == true) Navigator.of(context).pop(status);
            },
          ),
          ListTile(
            title: Text(S.of(context).import_from_NJU_title),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).import_from_NJU_subtitle)),
            onTap: () async {
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => ImportFromJWView()));
              if (status == true) Navigator.of(context).pop(status);
            },
          ),
          ListTile(
            title: Text(S.of(context).import_from_NJU_xk_title),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).import_from_NJU_xk_subtitle)),
            onTap: () async {
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      ImportFromXKView(config: Config.xk_config)));
              if (status == true) Navigator.of(context).pop(status);
            },
          ),
          Container(
            child: Text(S.of(context).import_online, style: TextStyle()),
            padding: const EdgeInsets.only(left: 15.0, top: 5.0, bottom: 5.0),
            alignment: Alignment.centerLeft,
            color: Color(0xffeeeeee),
          ),
          Expanded(
              child: FutureBuilder<List>(
                  future: getOnlineConfig(),
                  builder:
                      (BuildContext context, AsyncSnapshot<List> snapshot) {
                    if (snapshot.hasData) {
                      // List configList = snapshot.data!;
                      List<School> schoolList = snapshot.data!
                          .map((data) => School(
                              name: data['title'],
                              namePinyin: data['pinyin'],
                              tagIndex: data['pinyin'][0].toUpperCase(),
                              config: data,
                              isGrey: data['isGrey']))
                          .toList();
                      schoolList.add(School(
                          name: S.of(context).import_more_schools,
                          namePinyin: '#',
                          tagIndex: '#',
                          config: {}));

                      // A-Z sort.
                      SuspensionUtil.sortListBySuspensionTag(schoolList);

                      // show sus tag.
                      SuspensionUtil.setShowSuspensionStatus(schoolList);
                      return AzListView(
                        data: schoolList,
                        itemCount: schoolList.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == schoolList.length - 1) {
                            return moreSchools();
                          }
                          return ListTile(
                            title: Text(schoolList[index].name),
                            subtitle: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    schoolList[index].config!['description'])),
                            enabled: !(schoolList[index].isGrey ?? false),
                            onTap: () async {
                              bool? status = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          ImportFromBEView(
                                              config:
                                                  schoolList[index].config!)));
                              if (status == true)
                                Navigator.of(context).pop(status);
                            },
                          );
                        },
                        indexBarData:
                            SuspensionUtil.getTagIndexList(schoolList),
                      );
                    } else {
                      return moreSchools();
                    }
                  }))
        ]).toList())
        // )
        );
  }

  Future<List> getOnlineConfig() async {
    try {
      Dio dio = new Dio();
      String url = Url.UPDATE_ROOT + '/schoolList.json';
      Response response = await dio.get(url);
      List rst = response.data['data'];
      return rst;
    } catch (e) {
      return [];
    }
  }

  Widget moreSchools() {
    return InkWell(
        child: Container(
            child: Text(S.of(context).import_more_schools,
                style: TextStyle(color: Theme.of(context).primaryColor)),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 5.0, bottom: 5.0)),
        onTap: () => launch(Url.OPEN_SOURCE_URL));
  }
}
