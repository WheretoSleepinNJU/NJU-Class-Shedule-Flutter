import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../Components/Dialog.dart';
import '../../Components/TransBgTextButton.dart';
import '../../Utils/States/MainState.dart';
import '../../generated/l10n.dart';
import '../../Components/Toast.dart';
import '../../Models/CourseModel.dart';
import '../../Models/CourseTableModel.dart';
import '../../Resources/Url.dart';

class ImportFromBEView extends StatefulWidget {
  final String? title;
  final Map config;

  const ImportFromBEView({Key? key, this.title, required this.config})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ImportFromBEViewState();
  }
}

JavascriptChannel snackbarJavascriptChannel(BuildContext context) {
  return JavascriptChannel(
    name: 'SnackbarJSChannel',
    onMessageReceived: (JavascriptMessage message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message.message),
      ));
    },
  );
}

class ImportFromBEViewState extends State<ImportFromBEView> {
  late WebViewController _webViewController;
  final CookieManager cookieManager = CookieManager();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config['page_title']),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await cookieManager.clearCookies();
              _webViewController.loadUrl(widget.config['initialUrl']);
            },
          ),
          /// 作弊器
          IconButton(
            icon: const Icon(Icons.gamepad),
            onPressed: () async {
              // String rsp =
              //     "\u003Chtml lang=\"zh-CN\">\u003Chead>\u003Cmeta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n\u003Cmeta name=\"renderer\" content=\"webkit\">\n\u003Cmeta name=\"format-detection\" content=\"telephone=no\">\n\u003Cmeta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,Chrome=1\">\n\u003Cmeta name=\"viewport\" content=\"width=device-width,initial-scale=0.35986999999999997,maximum-scale=10.0,minimum-scale=0.35986999999999997,user-scalable=yes\">\n\u003Cmeta http-equiv=\"Pragma\" content=\"no-cache\">\n\u003Cmeta http-equiv=\"Cache-Control\" content=\"no-cache\">\n\u003Cmeta http-equiv=\"Expires\" content=\"0\">\n\n\n\n\n\n\n    \u003Ctitle data-i18n-text=\"title\">选课\u003C/title>\n    \u003Clink rel=\"stylesheet\" href=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/css/bhwindow.css?av=1661754447031\"> \n    \u003Clink rel=\"stylesheet\" href=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/css/grablessons/reset.css?av=1661754447031\">\n    \u003Clink rel=\"stylesheet\" href=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/css/bhTip.css?av=1661754447031\">\n    \u003Clink rel=\"stylesheet\" href=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/css/grablessons/grablessons.css?av=1661754447031\">\n    \u003Clink rel=\"stylesheet\" href=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/css/electiveBatchAndXz.css?av=1661754447031\">\n\u003C/head>\n\n\u003Cbody>\n    \u003Cdiv class=\"main\" style=\"min-width: 1000px;\">\n        \u003C!--头部-->\n        \u003Cheader class=\"cv-page-header cv-bg-color-primary cv-clearfix\">\n            \u003C!--logo-->\n            \u003Cdiv class=\"logo-container cv-pull-left\">\n\t            \u003Cimg class=\"logo-img\" data-i18n-title=\"logout\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/images/common/logo1.png?av=1661754447031\" id=\"cv-log-img\" title=\"退出\">\n\t\t\t\t\u003Cdiv class=\"descript cv-pull-left\">\n\t\t\t\t\t\u003Cdiv class=\"cn\">南京大学选课系统\u003C/div>\n\t\t\t\t\u003C/div>\n            \u003C/div>\n            \u003C!--选课类型tab-->\n            \u003Cdiv class=\"cv-pull-left\" cv-role=\"tabs\">\n                \u003Cul id=\"cvPageHeadTab\" class=\"cv-tabs\" cv-role=\"tabList\">\u003Cli class=\"cv-active\">\u003Ca href=\"javascript:void(0);\" class=\"tab-first\" data-teachingclasstype=\"ZY\">专业\u003C/a>\u003C/li>\u003Cli>\u003Ca href=\"javascript:void(0);\" class=\"tab-first\" data-teachingclasstype=\"GG\">公共\u003C/a>\u003C/li>\u003Cli>\u003Ca href=\"javascript:void(0);\" class=\"tab-first\" data-teachingclasstype=\"KZY\">跨专业\u003C/a>\u003C/li>\u003Cli>\u003Ca href=\"javascript:void(0);\" class=\"tab-first\" data-teachingclasstype=\"TX\">通修\u003C/a>\u003C/li>\u003C/ul>\n            \u003C/div>\n            \u003Cdiv class=\"cv-pull-right\">\n                \u003Cdiv class=\"cv-clearfix\">\n                    \u003Cdiv id=\"change_language\" class=\"cv-pull-left\" data-value=\"zh_cn\" onclick=\"\">\u003C/div>\n                    \u003Cdiv id=\"change_electiveBatch\" data-i18n-title=\"changeElectiveBatch\" onclick=\"\" class=\"cv-pull-left\" title=\"切换轮次\">\u003C/div>\n                    \u003Cdiv class=\"userinfo cv-pull-right\">\n                        \u003Cdiv class=\"user-top cv-clearfix\">\n                            \u003Cimg class=\"user-img\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/images/common/men.png\">\n                            \u003Cspan class=\"username\" title=\"焦玺瑞\">焦玺瑞\u003C/span>\n                            \u003Cimg class=\"arrow-icon\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/images/common/down-rounded.png?av=1661754447031\">\n                        \u003C/div>\n                        \u003Cdiv class=\"user-dropdown\" style=\"\">\n                            \u003Cdiv id=\"logout\" data-i18n-text=\"logout\">退出\u003C/div>\n                        \u003C/div>\n                    \u003C/div>\n                \u003C/div>\n            \u003C/div>\n        \u003C/header>\n\n        \u003C!--推荐选课模块-->\n        \u003Carticle id=\"course-main\">\n            \u003Cdiv class=\"top\">\n                \u003Cdiv class=\"top-title cv-clearfix\">\n                    \u003Cspan class=\"cv-color-prey cv-pull-left\" data-i18n-text=\"firstPage\">首页\u003C/span>\n                    \u003Cspan class=\"cv-color-prey cv-mh-4 cv-pull-left\">/\u003C/span>\n                    \u003Cspan class=\"menuName cv-pull-left\">专业\u003C/span>\n                    \u003Cdiv class=\"zyyx-container cv-pull-left\">\u003C/div>\n                \u003C/div>\n                \u003Cdiv class=\"top-second cv-clearfix\">\n                    \u003Cspan class=\"cv-color-prey\" data-i18n-text=\"currentTerm\">当前学期：\u003C/span>\n                    \u003Cspan class=\"currentTerm\">2022-2023学年 第1学期\u003C/span>\n                    \u003Cspan class=\"campus-info cv-ml-16\">\n                        \u003Cspan class=\"cv-color-prey\" data-i18n-text=\"currentCampus\">当前校区：\u003C/span>\n                        \u003Cspan class=\"currentcampus\">全部\u003C/span>\n                        \u003Cspan class=\"home-change-campus\" style=\"margin-left: 4px;color: #047ADC;cursor: pointer;\" data-i18n-text=\"change\">切换\u003C/span>\n                    \u003C/span>\n                \u003C/div>\n                \u003Cdiv class=\"top-search searchInput\">\n                    \u003Cinput class=\"search-input\" type=\"text\" data-i18n-placeholder=\"courseSearchPlaceholder\" placeholder=\"课程名称/课程号/教师\">\n                    \u003Cbutton class=\"cv-btn search-btn\" data-i18n-text=\"search\">搜索\u003C/button>\n                    \u003Cbutton class=\"cv-btn yxkc-window-btn\" data-i18n-text=\"home.selectedCourse\">已选课程\u003C/button>\n                \u003C/div>\n                \u003Cdiv class=\"second-tab-list cv-clearfix\">\u003C/div>\n            \u003C/div>\n            \u003Cdiv class=\"content-container\" style=\"height: 1232.33px;\">\n\t            \u003Cdiv class=\"search-container cv-clearfix\">\u003Cdiv class=\"cv-pull-left search-item\">\u003Cdiv class=\"cv-clearfix\">\u003Cdiv class=\"cv-pull-left search-label\">上课年级:\u003C/div>\u003Cdiv class=\"cv-pull-left search-item-warp\">\u003Cinput class=\"cv-search-dropdown\" data-search=\"SKNJ\" placeholder=\"请选择年级\" data-code=\"2022\" title=\"2022\" disabled=\"disabled\">\u003C/div>\u003C/div>\u003C/div>\u003Cdiv class=\"cv-pull-left search-item\">\u003Cdiv class=\"cv-clearfix\">\u003Cdiv class=\"cv-pull-left search-label\">上课专业:\u003C/div>\u003Cdiv class=\"cv-pull-left search-item-warp\">\u003Cinput class=\"cv-search-dropdown\" data-search=\"SKZY\" placeholder=\"请选择专业\" data-code=\"109\" title=\"朝鲜语\" disabled=\"disabled\">\u003C/div>\u003C/div>\u003C/div>\u003C/div>\n\t            \u003Cdiv class=\"result-container\" data-teachingclasstype=\"ZY\">\u003Ctable class=\"course-list\" cellspacing=\"0\">\u003Cthead class=\"course-head\">\u003Ctr>\u003Ctd class=\"kch course-cell course-order\" data-type=\"KCH\" data-order=\"normal\">\u003Cspan>课程号\u003C/span>\u003C/td>\u003Ctd class=\"kcmc course-cell course-order\" data-type=\"KCMC\" data-order=\"normal\">\u003Cspan>课程名\u003C/span>\u003C/td>\u003Ctd class=\"xf course-cell course-order\" data-type=\"XF\" data-order=\"normal\">\u003Cspan>学分\u003C/span>\u003C/td>\u003Ctd class=\"kcxz course-cell course-order\" data-type=\"KCXZ\" data-order=\"normal\">\u003Cspan>课程性质\u003C/span>\u003C/td>\u003Ctd class=\"xkfs course-cell course-order\" data-type=\"XKFS\" data-order=\"normal\">\u003Cspan>选课方式\u003C/span>\u003C/td>\u003Ctd class=\"bjs course-cell course-order\" data-type=\"BJS\" data-order=\"normal\">\u003Cspan>班级数\u003C/span>\u003C/td>\u003Ctd class=\"cz course-cell\">操作\u003C/td>\u003C/tr>\u003C/thead>\u003Ctbody class=\"course-body program-course\">\u003Ctr class=\"course-tr course  cv-has-selected\" data-coursenumber=\"00000110\">\u003Ctd class=\"kch course-cell\">\u003Ca class=\"cv-view-detail\" data-number=\"00000110\" href=\"javascript:void(0);\">00000110\u003C/a>\u003C/td>\u003Ctd class=\"kcmc course-cell\">马克思主义基本原理\u003C/td>\u003Ctd class=\"xf course-cell\">3\u003C/td>\u003Ctd class=\"kcxz course-cell\">通修\u003C/td>\u003Ctd class=\"xkfs course-cell\">必选\u003C/td>\u003Ctd class=\"bjs course-cell\">1\u003C/td>\u003Ctd class=\"cz course-cell\">\u003Ca class=\"cv-zy-expand\" data-number=\"00000110\" href=\"javascript:void(0);\" data-isopen=\"0\">查看班级\u003C/a>\u003C/td>\u003C/tr>\u003Ctr class=\"course-jxb-container-tr\">\u003Ctd colspan=\"7\">\u003Cdiv class=\"cv-clearfix course-jxb-container\" data-coursenumber=\"00000110\" \"=\"\">\u003Cdiv class=\"cv-pull-left jxb-item ischoosed\">\u003Cdiv class=\"content\">\u003Cdiv class=\"head\">\u003Cspan class=\"jxb-title\" title=\"李乾坤\">李乾坤\u003C/span>\u003Ca class=\"cv-jxb-detail\" data-number=\"00000110\" data-teachingclassid=\"2022202310000011018\" href=\"javascript:void(0);\" title=\"大纲-周历\">大纲-周历\u003C/a>\u003C/div>\u003Cdiv class=\"value\" title=\"鼓楼校区\">鼓楼校区\u003C/div>\u003Cdiv class=\"value\" title=\"周三 9-11节 3-16周 教213\">周三 9-11节 3-16周 教213\u003C/div>\u003Cdiv class=\"label krl-label\">\u003Cspan>已选/容量\u003C/span>\u003Cspan class=\"value\">\u003Cspan class=\"yxrs-value cv-color-danger\">已满\u003C/span>/135\u003C/span>\u003C/div>\u003C/div>\u003Cdiv class=\"buttons\">\u003Cbutton class=\"cv-btn cv-delete-select\" disabled=\"disabled\" type=\"button\" data-tcid=\"2022202310000011018\" data-number=\"00000110\" data-capacitysuffix=\"undefined\" data-isfull=\"undefined\" data-teachingclasstype=\"undefined\" data-isconflict=\"undefined\" data-limitgender=\"undefined\" data-capacityofmale=\"undefined\" data-capacityoffemale=\"undefined\" data-numberofmale=\"undefined\" data-numberoffemale=\"undefined\" data-coursenaturename=\"通修\">退选\u003C/button>\u003C/div>\u003C/div>\u003C/div>\u003C/td>\u003C/tr>\u003Ctr class=\"course-tr course  cv-has-selected\" data-coursenumber=\"00010013\">\u003Ctd class=\"kch course-cell\">\u003Ca class=\"cv-view-detail\" data-number=\"00010013\" href=\"javascript:void(0);\">00010013\u003C/a>\u003C/td>\u003Ctd class=\"kcmc course-cell\">简明微积分\u003C/td>\u003Ctd class=\"xf course-cell\">4\u003C/td>\u003Ctd class=\"kcxz course-cell\">通修\u003C/td>\u003Ctd class=\"xkfs course-cell\">必选\u003C/td>\u003Ctd class=\"bjs course-cell\">1\u003C/td>\u003Ctd class=\"cz course-cell\">\u003Ca class=\"cv-zy-expand\" data-number=\"00010013\" href=\"javascript:void(0);\" data-isopen=\"0\">查看班级\u003C/a>\u003C/td>\u003C/tr>\u003Ctr class=\"course-jxb-container-tr\">\u003Ctd colspan=\"7\">\u003Cdiv class=\"cv-clearfix course-jxb-container\" data-coursenumber=\"00010013\" \"=\"\">\u003Cdiv class=\"cv-pull-left jxb-item ischoosed\">\u003Cdiv class=\"content\">\u003Cdiv class=\"head\">\u003Cspan class=\"jxb-title\" title=\"聂梓伟\">聂梓伟\u003C/span>\u003Ca class=\"cv-jxb-detail\" data-number=\"00010013\" data-teachingclassid=\"2022202310001001304\" href=\"javascript:void(0);\" title=\"大纲-周历\">大纲-周历\u003C/a>\u003C/div>\u003Cdiv class=\"value\" title=\"鼓楼校区\">鼓楼校区\u003C/div>\u003Cdiv class=\"value\" title=\"周三 3-4节 3-16周 馆3-203;周五 1-2节 3-16周 馆3-203\">周三 3-4节 3-16周 馆3-203;周五 1-2节 3-16周 馆3-203\u003C/div>\u003Cdiv class=\"label krl-label\">\u003Cspan>已选/容量\u003C/span>\u003Cspan class=\"value\">\u003Cspan class=\"yxrs-value cv-color-danger\">已满\u003C/span>/140\u003C/span>\u003C/div>\u003C/div>\u003Cdiv class=\"buttons\">\u003Cbutton class=\"cv-btn cv-delete-select\" disabled=\"disabled\" type=\"button\" data-tcid=\"2022202310001001304\" data-number=\"00010013\" data-capacitysuffix=\"undefined\" data-isfull=\"undefined\" data-teachingclasstype=\"undefined\" data-isconflict=\"undefined\" data-limitgender=\"undefined\" data-capacityofmale=\"undefined\" data-capacityoffemale=\"undefined\" data-numberofmale=\"undefined\" data-numberoffemale=\"undefined\" data-coursenaturename=\"通修\">退选\u003C/button>\u003C/div>\u003C/div>\u003C/div>\u003C/td>\u003C/tr>\u003Ctr class=\"course-tr course  cv-has-selected\" data-coursenumber=\"10070200\">\u003Ctd class=\"kch course-cell\">\u003Ca class=\"cv-view-detail\" data-number=\"10070200\" href=\"javascript:void(0);\">10070200\u003C/a>\u003C/td>\u003Ctd class=\"kcmc course-cell\">朝鲜（韩国）语（一）\u003C/td>\u003Ctd class=\"xf course-cell\">8\u003C/td>\u003Ctd class=\"kcxz course-cell\">核心\u003C/td>\u003Ctd class=\"xkfs course-cell\">必选\u003C/td>\u003Ctd class=\"bjs course-cell\">1\u003C/td>\u003Ctd class=\"cz course-cell\">\u003Ca class=\"cv-zy-expand\" data-number=\"10070200\" href=\"javascript:void(0);\" data-isopen=\"0\">查看班级\u003C/a>\u003C/td>\u003C/tr>\u003Ctr class=\"course-jxb-container-tr\">\u003Ctd colspan=\"7\">\u003Cdiv class=\"cv-clearfix course-jxb-container\" data-coursenumber=\"10070200\" \"=\"\">\u003Cdiv class=\"cv-pull-left jxb-item ischoosed\">\u003Cdiv class=\"content\">\u003Cdiv class=\"head\">\u003Cspan class=\"jxb-title\" title=\"尹海燕,李锦花\">尹海燕,李锦花\u003C/span>\u003Ca class=\"cv-jxb-detail\" data-number=\"10070200\" data-teachingclassid=\"2022202311007020001\" href=\"javascript:void(0);\" title=\"大纲-周历\">大纲-周历\u003C/a>\u003C/div>\u003Cdiv class=\"value\" title=\"鼓楼校区\">鼓楼校区\u003C/div>\u003Cdiv class=\"value\" title=\"周一 3-4节 3-16周 教207;周二 3-6节 3-16周 教207;周四 3-4节 3-16周 教207\">周一 3-4节 3-16周 教207;周二 3-6节 3-16周 教207;周四 3-4节 3-16周 教207\u003C/div>\u003Cdiv class=\"label krl-label\">\u003Cspan>已选/容量\u003C/span>\u003Cspan class=\"value\">\u003Cspan class=\"yxrs-value cv-color-danger\">已满\u003C/span>/15\u003C/span>\u003C/div>\u003C/div>\u003Cdiv class=\"buttons\">\u003Cbutton class=\"cv-btn cv-delete-select\" disabled=\"disabled\" type=\"button\" data-tcid=\"2022202311007020001\" data-number=\"10070200\" data-capacitysuffix=\"undefined\" data-isfull=\"undefined\" data-teachingclasstype=\"undefined\" data-isconflict=\"undefined\" data-limitgender=\"undefined\" data-capacityofmale=\"undefined\" data-capacityoffemale=\"undefined\" data-numberofmale=\"undefined\" data-numberoffemale=\"undefined\" data-coursenaturename=\"核心\">退选\u003C/button>\u003C/div>\u003C/div>\u003C/div>\u003C/td>\u003C/tr>\u003Ctr class=\"course-tr course  cv-has-selected\" data-coursenumber=\"10083590\">\u003Ctd class=\"kch course-cell\">\u003Ca class=\"cv-view-detail\" data-number=\"10083590\" href=\"javascript:void(0);\">10083590\u003C/a>\u003C/td>\u003Ctd class=\"kcmc course-cell\">朝鲜（韩国）语视听说（一）\u003C/td>\u003Ctd class=\"xf course-cell\">2\u003C/td>\u003Ctd class=\"kcxz course-cell\">选修\u003C/td>\u003Ctd class=\"xkfs course-cell\">可选\u003C/td>\u003Ctd class=\"bjs course-cell\">1\u003C/td>\u003Ctd class=\"cz course-cell\">\u003Ca class=\"cv-zy-expand\" data-number=\"10083590\" href=\"javascript:void(0);\" data-isopen=\"0\">查看班级\u003C/a>\u003C/td>\u003C/tr>\u003Ctr class=\"course-jxb-container-tr\">\u003Ctd colspan=\"7\">\u003Cdiv class=\"cv-clearfix course-jxb-container\" data-coursenumber=\"10083590\" \"=\"\">\u003Cdiv class=\"cv-pull-left jxb-item ischoosed\">\u003Cdiv class=\"content\">\u003Cdiv class=\"head\">\u003Cspan class=\"jxb-title\" title=\"吴玉梅,郑墡谟\">吴玉梅,郑墡谟\u003C/span>\u003Ca class=\"cv-jxb-detail\" data-number=\"10083590\" data-teachingclassid=\"2022202311008359001\" href=\"javascript:void(0);\" title=\"大纲-周历\">大纲-周历\u003C/a>\u003C/div>\u003Cdiv class=\"value\" title=\"鼓楼校区\">鼓楼校区\u003C/div>\u003Cdiv class=\"value\" title=\"周四 1-2节 3-16周 馆3-206;周五 3-4节 3-16周 馆3-206\">周四 1-2节 3-16周 馆3-206;周五 3-4节 3-16周 馆3-206\u003C/div>\u003Cdiv class=\"label krl-label\">\u003Cspan>已选/容量\u003C/span>\u003Cspan class=\"value\">\u003Cspan class=\"yxrs-value cv-color-danger\">已满\u003C/span>/15\u003C/span>\u003C/div>\u003C/div>\u003Cdiv class=\"buttons\">\u003Cbutton class=\"cv-btn cv-delete-select\" type=\"button\" data-tcid=\"2022202311008359001\" data-number=\"10083590\" data-capacitysuffix=\"undefined\" data-isfull=\"undefined\" data-teachingclasstype=\"undefined\" data-isconflict=\"undefined\" data-limitgender=\"undefined\" data-capacityofmale=\"undefined\" data-capacityoffemale=\"undefined\" data-numberofmale=\"undefined\" data-numberoffemale=\"undefined\" data-coursenaturename=\"选修\">退选\u003C/button>\u003C/div>\u003C/div>\u003C/div>\u003C/td>\u003C/tr>\u003Ctr class=\"course-tr course \" data-coursenumber=\"10083670\">\u003Ctd class=\"kch course-cell\">\u003Ca class=\"cv-view-detail\" data-number=\"10083670\" href=\"javascript:void(0);\">10083670\u003C/a>\u003C/td>\u003Ctd class=\"kcmc course-cell\">朝鲜（韩国）语言文学专业通览\u003C/td>\u003Ctd class=\"xf course-cell\">1\u003C/td>\u003Ctd class=\"kcxz course-cell\">选修\u003C/td>\u003Ctd class=\"xkfs course-cell\">可选\u003C/td>\u003Ctd class=\"bjs course-cell\">1\u003C/td>\u003Ctd class=\"cz course-cell\">\u003Ca class=\"cv-zy-expand\" data-number=\"10083670\" href=\"javascript:void(0);\" data-isopen=\"0\">查看班级\u003C/a>\u003C/td>\u003C/tr>\u003Ctr class=\"course-jxb-container-tr\">\u003Ctd colspan=\"7\">\u003Cdiv class=\"cv-clearfix course-jxb-container\" data-coursenumber=\"10083670\" \"=\"\">\u003Cdiv class=\"cv-pull-left jxb-item \">\u003Cdiv class=\"content\">\u003Cdiv class=\"head\">\u003Cspan class=\"jxb-title\" title=\"尹海燕,郑墡谟,徐黎明,吴玉梅,李锦花\">尹海燕,郑墡谟,徐黎明,吴玉梅,李锦花\u003C/span>\u003Ca class=\"cv-jxb-detail\" data-number=\"10083670\" data-teachingclassid=\"2022202311008367001\" href=\"javascript:void(0);\" title=\"大纲-周历\">大纲-周历\u003C/a>\u003C/div>\u003Cdiv class=\"value\" title=\"鼓楼校区\">鼓楼校区\u003C/div>\u003Cdiv class=\"value\" title=\"周一 7-8节 6-13周 馆3-206\">周一 7-8节 6-13周 馆3-206\u003C/div>\u003Cdiv class=\"label krl-label\">\u003Cspan>已选/容量\u003C/span>\u003Cspan class=\"value\">\u003Cspan class=\"yxrs-value cv-color-danger\">已满\u003C/span>/15\u003C/span>\u003C/div>\u003C/div>\u003Cdiv class=\"buttons\">\u003Cbutton class=\"cv-btn cv-choice\" type=\"button\" data-number=\"10083670\" data-tcid=\"2022202311008367001\" data-capacitysuffix=\"\" data-isfull=\"0\" data-isconflict=\"1\" data-limitgender=\"0\" data-capacityofmale=\"\" data-capacityoffemale=\"\" data-numberofmale=\"\" data-numberoffemale=\"\">选择\u003C/button>\u003C/div>\u003C/div>\u003C/div>\u003C/td>\u003C/tr>\u003C/tbody>\u003C/table>\u003Cdiv class=\"course-table-footer\" onclick=\"\" style=\"display: none;\">\u003Cspan>加载更多\u003C/span>\u003Cimg src=\"public/images/common/down-double.png\">\u003C/div>\u003C/div>\n            \u003C/div>\n        \u003C/article>\n\n        \u003C!--页脚-->\n        \u003Cfooter class=\"cv-page-footer\">\n            \u003Cdiv>\n                \u003Cspan class=\"cv-copyright\" id=\"cv-copyright\">版权信息：© 2020 南京大学本科生院\u003C/span>\n                \u003Cspan id=\"noline-tip\">（当前选课在线人数 1065 人）\u003C/span>\n                \u003Cspan class=\"cv-mh-4 cv-color-danger\">选课如有问题请联系89682303\u003C/span>\n            \u003C/div>\n        \u003C/footer>\n    \u003C/div>\n\n    \u003C!-- 引导页 -->\n    \u003Cdiv class=\"jszp\" style=\"display:none;\">\n        \u003Cdiv class=\"step1\">\n            \u003Cdiv>\n                \u003Cimg src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/images/curriculaVariable/01.png?av=1661754447031\">\n            \u003C/div>\n            \u003Cdiv class=\"btns\">\n                \u003Cdiv class=\"cv-btn\">我知道了\u003C/div>\n            \u003C/div>\n        \u003C/div>\n        \u003Cdiv class=\"step2\" style=\"display: none;\">\n            \u003Cdiv>\n                \u003Cimg src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/images/curriculaVariable/02.png?av=1661754447031\">\n            \u003C/div>\n            \u003Cdiv class=\"btns\">\n                \u003Cdiv class=\"cv-btn\">我知道了\u003C/div>\n            \u003C/div>\n        \u003C/div>\n    \u003C/div>\n\n    \u003C!--我的课表模板-->\n    \u003Cscript type=\"text/template\" id=\"tpl-mycourse-model\">\n        \u003Cdiv class=\"my-course-table\">\n            \u003Cdiv class=\"my-course-top cv-clearfix\">\n            \t\u003Cdiv class=\"bh-checkbox cv-pull-right\">\n\t\t            \u003Clabel class=\"bh-checkbox-label\">\n\t\t                \u003Cinput type=\"checkbox\" name=\"table-list\" class=\"change-table-list\" data-type=\"table\" value=\"0\" data-caption=\"@tablelist\">\n\t\t                \u003Ci class=\"bh-choice-helper\">\u003C/i>@tablelist\n\t\t            \u003C/label>\n\t\t        \u003C/div>\n            \u003C/div>\n            \u003Cdiv class=\"course-table\">\n\t\t\t\t\u003Cdiv class=\"course-table-container\">\u003C/div>\n\t\t\t\t\u003Cdiv class=\"not-arranged\">\n\t\t\t\t\t\u003Ch3 class=\"cv-font-bold cv-mv-16\">@wapkcbt\u003C/h3>\n\t\t\t\t\t\u003Cdiv class=\"myNoArrangedCourseList\">\u003C/div>\n\t\t\t\t\u003C/div>\n\t\t\t\u003C/div>\n            \u003Cdiv class=\"my-course-list cv-hide\">\u003C/div>\n        \u003C/div>\n    \u003C/script>\n\n    \u003Cscript type=\"text/template\" id=\"electiveBatch_list_select\">\n        \u003Cdiv class=\"xzlc-container\">\n\t\t\t\u003Cdiv class=\"lc-container\">\n\t        \t\u003Ctable class=\"electiveBatch-list-table\" cellspacing=\"0\">\n\t\t\t\t\t\u003Cthead class=\"electiveBatch-head\">\n\t            \t\t\u003Cth class=\"cv-electiveBatch-operate\">@operate\u003C/th>\n\t            \t\t\u003Cth class=\"cv-electiveBatch-name\">@name\u003C/th>\n\t\t\t\t\t\t\u003Cth class=\"cv-electiveBatch-kssj\">@begintime\u003C/th>\n\t            \t\t\u003Cth class=\"cv-electiveBatch-jssj\">@endtime\u003C/th>\n\t            \t\t\u003Cth class=\"cv-electiveBatch-cause\">@bkxyy\u003C/th>\n\t\t\t\t\t\u003C/thead>\n\t\t\t\t\t\u003Ctbody class=\"electiveBatch-body\">@electiveBatchBody\u003C/tbody>\n\t        \t\u003C/table>\n\t\t\t\u003C/div>\n\t\t\t\u003C/div>\n\t\t\u003C/div>\n    \u003C/script>\n    \n    \u003Cscript type=\"text/template\" id=\"tpl-schoolcourse-view\">\n        \u003Cdiv class=\"schoolcourse-view-table\">\n\t\t\t\u003Ch2>@courseTitle\u003C/h2>\n\t\t\t\u003Ch4>能否选课原因分析\u003C/h4>\n\t\t\t\u003Cdiv>\n\t\t\t\t@chooseBody\n\t\t\t\u003C/div>\n        \u003C/div>\n    \u003C/script>\n    \n    \u003Cscript type=\"text/template\" id=\"electiveBatch_list_select\">\n        \u003Cdiv class=\"xzlc-container\">\n\t\t\t\u003Cdiv class=\"lc-container\">\n\t        \t\u003Ctable class=\"electiveBatch-list-table\" cellspacing=\"0\">\n\t\t\t\t\t\u003Cthead class=\"electiveBatch-head\">\n\t            \t\t\u003Cth class=\"cv-electiveBatch-operate\">操作\u003C/th>\n\t            \t\t\u003Cth class=\"cv-electiveBatch-name\">名称\u003C/th>\n\t            \t\t\u003Cth class=\"cv-electiveBatch-cause\">不可选原因\u003C/th>\n\t\t\t\t\t\u003C/thead>\n\t\t\t\t\t\u003Ctbody class=\"electiveBatch-body\">@electiveBatchBody\u003C/tbody>\n\t        \t\u003C/table>\n\t\t\t\u003C/div>\n\t\t\u003C/div>\n    \u003C/script>\n\n    \u003Cscript type=\"text/javascript\">\n        var BaseUrl = \"https://xk.nju.edu.cn/xsxkapp\";\n        var length = BaseUrl.length;\n        if (BaseUrl.indexOf(length - 1, length) == '/') {\n            BaseUrl = BaseUrl.substring(0, length - 1);\n        }\n\n        var uid = 'null';\n        var loginType = 'ldap';\n        var casUrl = 'http://authserver.nju.edu.cn/authserver/login';\n        var casUrlOut = 'http://authserver.nju.edu.cn/authserver/logout';\n        var resUrl = 'https://xkres.nju.edu.cn/products/jwfw/xsxkapp';\n        var socketUrl = 'null';\n        var pageType = 'grablessons';\n    \u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/plugins/jquery.min.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/plugins/i18n/jquery.i18n.properties.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/jqxwidget/jquery.nicescroll.min.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/jqxcore.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/jqxtabs.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/jqxwindow.js?av=1661754447031\">\u003C/script>\n\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/bh_utils.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/plugins/sortable/Sortable-1.3.0.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/bhTip.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/window.js?av=1661754447031\">\u003C/script>\n\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/loginInUserRegister.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/index/indexBS.js?av=1661754447031\">\u003C/script>\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/grablessons/grablessons.js?av=1661754447031\">\u003C/script>\n\n    \u003Cscript type=\"text/javascript\" src=\"https://xkres.nju.edu.cn/products/jwfw/xsxkapp/public/js/xsxkpub.js?av=1661754447031\">\u003C/script>\n\n\n\u003C/body>\u003C/html>";
              String rsp = "";
              import(_webViewController, context, rsp: rsp);
            },
          )
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Column(children: <Widget>[
            widget.config['banner_content'] == null
                ? Container()
                : MaterialBanner(
                    forceActionsBelow: true,
                    content: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(widget.config['banner_content'],
                            style: const TextStyle(color: Colors.white))),
                    backgroundColor: Theme.of(context).primaryColor,
                    actions: [
                      TextButton(
                          style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor),
                          child: Text(widget.config['banner_action']),
                          onPressed: () => launch(widget.config['banner_url'])),
                    ],
                  ),
            Expanded(
                child: WebView(
              initialUrl: widget.config['initialUrl'],
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) async {
                _webViewController = webViewController;
              },
              javascriptChannels: <JavascriptChannel>{
                snackbarJavascriptChannel(context),
              },
              onPageFinished: (url) {
                if (widget.config['redirectUrl'] != '' &&
                    url.startsWith(widget.config['redirectUrl'])) {
                  _webViewController.loadUrl(widget.config['targetUrl']);
                } else if (url.startsWith(widget.config['targetUrl'])) {
                  import(_webViewController, context);
                }
              },
            ))
          ]);
        },
      ),
    );
  }

  import(WebViewController controller, BuildContext context, {String? rsp}) async {
    try {
      String response = "";
      CourseTableProvider courseTableProvider = CourseTableProvider();
      Toast.showToast(S
          .of(context)
          .class_parse_toast_importing, context);
      if(rsp == null) {
        await controller.runJavascript(widget.config['preExtractJS'] ?? '');
        await Future.delayed(
            Duration(seconds: widget.config['delayTime'] ?? 0));
        Dio dio = Dio();
        // 他妈的，屁事真多
        String url = '';
        if (Platform.isIOS) {
          url = widget.config['extractJSfileiOS'];
        } else if (Platform.isAndroid) {
          url = widget.config['extractJSfileAndroid'];
        }
        Response rsp = await dio.get(url);
        String js = rsp.data;
        response = await controller.runJavascriptReturningResult(js);
      } else {
        response = rsp;
      }
      response = Uri.decodeComponent(response.replaceAll('"', ''));
      Map courseTableMap = json.decode(response);
      CourseTable courseTable;
      if (widget.config['class_time_list'] == null &&
          widget.config['semester_start_monday'] == null) {
        courseTable = await courseTableProvider
            .insert(CourseTable(courseTableMap['name']));
      } else {
        try {
          Map data = {};
          if (widget.config['class_time_list'] != null) {
            data["class_time_list"] = widget.config['class_time_list'];
          }
          if (widget.config['semester_start_monday'] != null) {
            data["semester_start_monday"] =
                widget.config['semester_start_monday'];
          }
          String dataString = json.encode(data);
          courseTable = await courseTableProvider
              .insert(CourseTable(courseTableMap['name'], data: dataString));
        } catch (e) {
          courseTable = await courseTableProvider
              .insert(CourseTable(courseTableMap['name']));
        }
      }
      int index = (courseTable.id!);
      CourseProvider courseProvider = CourseProvider();
      await ScopedModel.of<MainStateModel>(context).changeclassTable(index);
      Iterable courses;
      // 因为这里有的可能会被encode有的不会 所以做下特殊处理...
      if (courseTableMap['courses'].runtimeType != String) {
        courses = courseTableMap['courses'];
      } else if (json.decode(courseTableMap['courses']).runtimeType != String) {
        courses = json.decode(courseTableMap['courses']);
      } else {
        courses = json.decode(json.decode(courseTableMap['courses']));
      }
      List<Map<String, dynamic>> coursesMap =
          List<Map<String, dynamic>>.from(courses);
      for (var courseMap in coursesMap) {
        courseMap.remove('id');
        courseMap['tableid'] = index;
        Course course = Course.fromMap(courseMap);
        await courseProvider.insert(course);
      }
      UmengCommonSdk.onEvent(
          "class_import", {"type": "be", "action": "success"});
      Toast.showToast(S.of(context).class_parse_toast_success, context);
      Navigator.of(context).pop(true);
    } catch (e) {
      String response = await controller.runJavascriptReturningResult(
          "window.document.getElementsByTagName('html')[0].outerHTML;");
      String url = await controller.currentUrl() ?? "";

      String now = DateTime.now().toString();
      String errorCode = now
          .replaceAll("-", "")
          .replaceAll(":", "")
          .replaceAll(" ", "")
          .replaceAll(".", "");
      Map<String, String> info = {
        "errorCode": errorCode,
        "response": response,
        "errorMsg": e.toString(),
        "url": url,
        "way": "be"
      };
      await Dio()
          .post(Url.URL_BACKEND + "/log/log", data: FormData.fromMap(info));

      UmengCommonSdk.onEvent("class_import", {"type": "be", "action": "fail"});
      // Toast.showToast(S.of(context).online_parse_error_toast, context);
      showDialog<String>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return MDialog(
              S.of(context).parse_error_dialog_title,
              Text(S.of(context).parse_error_dialog_content(errorCode)),
              overrideActions: <Widget>[
                Container(
                    alignment: Alignment.centerRight,
                    child: TransBgTextButton(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        child: Text(S.of(context).parse_error_dialog_add_group),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: errorCode));
                          if (Platform.isIOS) {
                            launch(Url.QQ_GROUP_APPLE_URL);
                          } else if (Platform.isAndroid) {
                            launch(Url.QQ_GROUP_ANDROID_URL);
                          }
                          Navigator.of(context).pop();
                        })),
                Container(
                    alignment: Alignment.centerRight,
                    child: TransBgTextButton(
                        color: Colors.grey,
                        child: Text(S.of(context).parse_error_dialog_other_ways,
                            style: const TextStyle(color: Colors.grey)),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }))
              ],
            );
          });
      return;
    }
  }
}
