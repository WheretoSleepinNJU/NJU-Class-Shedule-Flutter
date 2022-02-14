import '../../generated/l10n.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:azlistview/azlistview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
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
  const ImportView({Key? key}) : super(key: key);

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
            child: Text(S.of(context).import_inline, style: const TextStyle()),
            padding: const EdgeInsets.only(left: 15.0, top: 10.0, bottom: 5.0),
            alignment: Alignment.centerLeft,
            color: const Color(0xffeeeeee),
          ),
          ListTile(
            title: Text(S.of(context).import_from_NJU_cer_title),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(S.of(context).import_from_NJU_cer_subtitle)),
            onTap: () async {
              UmengCommonSdk.onEvent(
                  "class_import", {"type": "cer", "action": "show"});
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ImportFromCerView(config: Config.jw_config)));
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
              UmengCommonSdk.onEvent(
                  "class_import", {"type": "jw", "action": "show"});
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => const ImportFromJWView()));
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
              UmengCommonSdk.onEvent(
                  "class_import", {"type": "xk", "action": "show"});
              bool? status = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ImportFromXKView(config: Config.xk_config)));
              if (status == true) Navigator.of(context).pop(status);
            },
          ),
          Container(
            child: Text(S.of(context).import_online, style: const TextStyle()),
            padding: const EdgeInsets.only(left: 15.0, top: 5.0, bottom: 5.0),
            alignment: Alignment.centerLeft,
            color: const Color(0xffeeeeee),
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
                              isGrey: data['isGrey3.1.0']))
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
                              UmengCommonSdk.onEvent("class_import",
                                  {"type": "be", "action": "show"});
                              bool? status = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          ImportFromBEView(
                                              config:
                                                  schoolList[index].config!)));
                              if (status == true) {
                                Navigator.of(context).pop(status);
                              }
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
      Dio dio = Dio();
      String url = Url.UPDATE_ROOT + '/schoolList.json';
      Response response = await dio.get(url);
      List rst = response.data['data'];
      //
      // Below are test codes.
      //
      // rst = [
      //   {
      //     "title": "南京大学本科生选课系统（beta）",
      //     "pinyin": "nanjingdaxuebenke",
      //     "description": "测试中，请确保APP版本>=3.1.0!",
      //     "page_title": "选课系统登录",
      //     "initialUrl":
      //         "https://authserver.nju.edu.cn/authserver/login?service=http%3A%2F%2Felite.nju.edu.cn%2Fjiaowu%2Fcaslogin.jsp",
      //     "redirectUrl": "http://elite.nju.edu.cn/jiaowu/login.do",
      //     "targetUrl":
      //         "http://elite.nju.edu.cn/jiaowu/student/teachinginfo/courseList.do?method=currentTermCourse",
      //     "preExtractJS": "",
      //     "delayTime": 3,
      //     "extractJS":
      //         "function scheduleHtmlParser(){let WEEK_WITH_BIAS=[\"\",\"周一\",\"周二\",\"周三\",\"周四\",\"周五\",\"周六\",\"周日\"];let name=document.querySelector(\"body > div:nth-child(10) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1)\").textContent;let rst={'name':name,'courses':[]};let table_1=document.getElementsByClassName(\"TABLE_TR_01\");let table_2=document.getElementsByClassName(\"TABLE_TR_02\");let table=table_1.concat(table_2);table.forEach(e=>{let state=e.children[6].innerText;if(state.includes('已退选'))return;let course_name=e.children[1].innerText;let class_number=e.children[0].innerText;let teacher=e.children[3].innerText;let test_time=e.children[8].innerText;let test_location=e.children[9].innerText;let course_info=e.children[10].innerText;let info_str=e.children[4].innerText;let info_list=info_str.split('\\n');info_list.forEach(i=>{let week_time=0;let strs=i.split(' ');let start_time=0;let time_count=0;let weeks=[];for(let z=0;z<WEEK_WITH_BIAS.length;z++){if(WEEK_WITH_BIAS[z]==strs[0])week_time=z}let pattern1=new RegExp('第(\\\\d{1,2})-(\\\\d{1,2})节','i');strs.forEach(w=>{let r=pattern1.exec(w);if(r){start_time=parseInt(r[1]);time_count=parseInt(r[2])-parseInt(r[1])}});let pattern2=new RegExp('(\\\\d{1,2})-(\\\\d{1,2})周','i');strs.forEach(x=>{let s=pattern2.exec(x);if(s){if(strs.includes('单周')){for(let z=parseInt(s[1]);z<=parseInt(s[2]);z+=2)weeks.push(z)}else if(strs.includes('双周')){for(let z=parseInt(s[1]);z<=parseInt(s[2]);z+=2)weeks.push(z)}else{for(let z=parseInt(s[1]);z<=parseInt(s[2]);z++)weeks.push(z)}}});let pattern3=new RegExp('第(\\\\d{1,2})周','i');strs.forEach(y=>{let t=pattern3.exec(y);if(t){weeks.push(parseInt(t[1]))}});rst['courses'].push({\"name\":course_name,\"classroom\":\"仙Ⅰ-109\",\"class_number\":class_number,\"teacher\":teacher,\"test_time\":test_time,\"test_location\":test_location,\"link\":null,\"weeks\":weeks,\"week_time\":week_time,\"start_time\":start_time,\"time_count\":time_count,\"import_type\":1,\"info\":course_info,\"data\":null})})});return JSON.stringify(rst)}scheduleHtmlParser();",
      //     // "extractJSfile": "http://127.0.0.1/njubksxk.js",
      //     "extractJSfile":
      //         "https://cdn.idealclover.cn/Projects/wheretosleepinnju/production/tools/njubksxk.js",
      //     "banner_content":
      //         "注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准教务系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常",
      //     "banner_action": "下载南京大学VPN",
      //     "banner_url": "https://vpn.nju.edu.cn",
      //     "isGrey": true,
      //     "isGrey3.1.0": false
      //   },
      //   {
      //     "title": "南京大学研究生选课系统（alpha）",
      //     "pinyin": "nanjingdaxueyanjiu",
      //     "description": "测试中，请确保APP版本>=3.1.0!",
      //     "page_title": "选课系统登录",
      //     "initialUrl":
      //         "https://yjsxk.nju.edu.cn/yjsxkapp/sys/xsxkapp/index_nju.html",
      //     "redirectUrl":
      //         "https://yjsxk.nju.edu.cn/yjsxkapp/sys/xsxkapp/course_nju.html",
      //     "targetUrl":
      //         "https://yjsxk.nju.edu.cn/yjsxkapp/sys/xsxkapp/xsxkCourse/loadStdCourseInfo.do",
      //     "preExtractJS": "",
      //     "delayTime": 3,
      //     "extractJS":
      //         "function scheduleHtmlParser(){let WEEK_WITH_BIAS=['','一','二','三','四','五','六','日',];data=JSON.parse(document.body.innerText.replaceAll('\\n',''));let name=data['results'][data['results'].length-1]['XNXQMC'];let rst={name:name,courses:[]};data['results'].forEach((e)=>{let sem=e['XNXQMC'];if(sem!=name)return;let course_name=e['KCMC'];let class_number=e['KCDM'];let teacher=e['RKJS'];let test_time='';let test_location='';let course_info=e['XKBZ'];let info_str=e['PKSJDD'];let info_list=info_str.split(';');info_list.forEach((i)=>{let week_time=0;let start_time=0;let time_count=0;let weeks=[];let pattern=new RegExp('(\\\\d{1,2})(-(\\\\d{1,2}))?(单|双)?周 星期(.)\\\\[(\\\\d{1,2})(-(\\\\d{1,2}))?节](.*)','i');let strs=pattern.exec(i);for(let z=0;z<WEEK_WITH_BIAS.length;z++){if(WEEK_WITH_BIAS[z]==strs[5])week_time=z}if(strs[4]=='单'){for(let z=parseInt(strs[1]);z<=parseInt(strs[3]);z+=2)weeks.push(z)}else if(strs[4]=='双'){for(let z=parseInt(strs[1]);z<=parseInt(strs[3]);z+=2)weeks.push(z)}else{for(let z=parseInt(strs[1]);z<=parseInt(strs[3]);z++)weeks.push(z)}start_time=parseInt(strs[6]);if(typeof(strs[8])!='undefined'){time_count=parseInt(strs[8])-parseInt(strs[6])}else{time_count=1}let classroom=strs[9];rst['courses'].push({name:course_name,classroom:classroom,class_number:class_number,teacher:teacher,test_time:test_time,test_location:test_location,link:null,weeks:weeks,week_time:week_time,start_time:start_time,time_count:time_count,import_type:1,info:course_info,data:null,})})});return JSON.stringify(rst)}scheduleHtmlParser();",
      //     // "extractJSfile": "http://127.0.0.1/njuyjsxk.js",
      //     "extractJSfile":
      //         "https://cdn.idealclover.cn/Projects/wheretosleepinnju/production/tools/njuyjsxk.js",
      //     "banner_content":
      //         "注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准教务系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常",
      //     "banner_action": "下载南京大学VPN",
      //     "banner_url": "https://vpn.nju.edu.cn",
      //     "isGrey": true,
      //     "isGrey3.1.0": false
      //   }
      // ];
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
        onTap: () {
          UmengCommonSdk.onEvent(
              "class_import", {"type": "be", "action": "more"});
          launch(Url.OPEN_SOURCE_URL);
        });
  }
}
