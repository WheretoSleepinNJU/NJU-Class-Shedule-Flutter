// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(start, end) => "第 ${start}-${end} 节";

  static String m1(num) => "第 ${num} 节";

  static String m2(className) => "确定删除课程【 ${className} 】吗？";

  static String m3(num) => "另有 ${num} 节「自由时间」课程 >>";

  static String m4(num) => "加入当前课表(${num}人已添加)";

  static String m5(num) => "已添加(${num}人已添加)";

  static String m6(num) => "已结束(${num}人已添加)";

  static String m7(code) =>
      "看起来导入失败了，都怪傻翠！\n\n本次导入错误码：${code}\n\n点击下方按钮将复制该错误码并加入用户群，你可以报告傻翠并等待修复，当然，也可以试试其他方式是否可以正常导入";

  static String m8(num) => "第 ${num} 周";

  static String m9(start, end) => "${start}-${end} 周";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "QQ_copy_success_toast":
            MessageLookupByLibrary.simpleMessage("已复制群号到剪贴板"),
        "QQ_open_fail_toast":
            MessageLookupByLibrary.simpleMessage("打开失败，可能是未安装 TIM/QQ"),
        "about_title": MessageLookupByLibrary.simpleMessage("关于"),
        "add_backgound_picture_subtitle":
            MessageLookupByLibrary.simpleMessage("上传背景图片"),
        "add_backgound_picture_success_toast":
            MessageLookupByLibrary.simpleMessage("更换背景图片成功ww"),
        "add_backgound_picture_title":
            MessageLookupByLibrary.simpleMessage("上传背景图片"),
        "add_class": MessageLookupByLibrary.simpleMessage("添加课程"),
        "add_class_table_dialog_title":
            MessageLookupByLibrary.simpleMessage("请输入课程表名称"),
        "add_class_table_success_toast":
            MessageLookupByLibrary.simpleMessage("添加课程表成功"),
        "add_manually_success_toast":
            MessageLookupByLibrary.simpleMessage("添加成功！>v<"),
        "add_manually_title": MessageLookupByLibrary.simpleMessage("添加课程"),
        "all_course_subtitle":
            MessageLookupByLibrary.simpleMessage("查看南哪全校课表，方便添加和蹭课"),
        "all_course_title": MessageLookupByLibrary.simpleMessage("查看全校课表"),
        "already_newest_version_toast":
            MessageLookupByLibrary.simpleMessage("已经是最新版本了呦～"),
        "app_name": MessageLookupByLibrary.simpleMessage("南哪课表"),
        "at": MessageLookupByLibrary.simpleMessage("@"),
        "bug_and_report": MessageLookupByLibrary.simpleMessage("似乎有bug，我要反馈"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "captcha": MessageLookupByLibrary.simpleMessage("验证码"),
        "captcha_error_toast":
            MessageLookupByLibrary.simpleMessage("验证码错误 > <"),
        "change_theme_mode_subtitle":
            MessageLookupByLibrary.simpleMessage("是否跟随系统切换模式"),
        "change_theme_mode_title":
            MessageLookupByLibrary.simpleMessage("浅色/深色模式切换"),
        "change_theme_title": MessageLookupByLibrary.simpleMessage("修改主题"),
        "change_week_subtitle": MessageLookupByLibrary.simpleMessage("当前周数："),
        "change_week_title": MessageLookupByLibrary.simpleMessage("修改当前周"),
        "check_privacy_button": MessageLookupByLibrary.simpleMessage("隐私政策"),
        "check_update_button": MessageLookupByLibrary.simpleMessage("检查更新"),
        "choose_class_time_dialog_title":
            MessageLookupByLibrary.simpleMessage("选择上课时间"),
        "class_duration": m0,
        "class_height_subtitle":
            MessageLookupByLibrary.simpleMessage("仅当强制缩放关闭时生效"),
        "class_height_title": MessageLookupByLibrary.simpleMessage("自定义课程显示长度"),
        "class_info": MessageLookupByLibrary.simpleMessage("备注"),
        "class_name": MessageLookupByLibrary.simpleMessage("课程名称"),
        "class_name_empty": MessageLookupByLibrary.simpleMessage("请输入课程名称"),
        "class_num_invalid_dialog_content":
            MessageLookupByLibrary.simpleMessage("课程结束节数应大于起始节数"),
        "class_num_invalid_dialog_title":
            MessageLookupByLibrary.simpleMessage("课程节数不合法"),
        "class_parse_error_toast":
            MessageLookupByLibrary.simpleMessage("课程解析失败 = =|| 可将课表反馈至翠翠"),
        "class_parse_toast_fail":
            MessageLookupByLibrary.simpleMessage("出现异常，建议提交反馈"),
        "class_parse_toast_importing":
            MessageLookupByLibrary.simpleMessage("数据识别与导入中~"),
        "class_parse_toast_success":
            MessageLookupByLibrary.simpleMessage("数据存储成功 >v<"),
        "class_room": MessageLookupByLibrary.simpleMessage("上课地点"),
        "class_single": m1,
        "class_table_manage_title":
            MessageLookupByLibrary.simpleMessage("课表管理"),
        "class_teacher": MessageLookupByLibrary.simpleMessage("上课老师"),
        "del_class_table_dialog_content":
            MessageLookupByLibrary.simpleMessage("此操作无法恢复，这将删除该课程表下的所有课程。"),
        "del_class_table_dialog_title":
            MessageLookupByLibrary.simpleMessage("确认删除"),
        "del_class_table_success_toast":
            MessageLookupByLibrary.simpleMessage("删除课程表成功"),
        "delete_backgound_picture_subtitle":
            MessageLookupByLibrary.simpleMessage("恢复默认白色背景"),
        "delete_backgound_picture_success_toast":
            MessageLookupByLibrary.simpleMessage("已恢复默认背景ww"),
        "delete_backgound_picture_title":
            MessageLookupByLibrary.simpleMessage("清除背景图片"),
        "delete_class_dialog_content": m2,
        "delete_class_dialog_title":
            MessageLookupByLibrary.simpleMessage("删除课程"),
        "developer": MessageLookupByLibrary.simpleMessage("开发者 idealclover"),
        "donate_subtitle": MessageLookupByLibrary.simpleMessage("给傻翠买支棒棒糖吧！"),
        "donate_title": MessageLookupByLibrary.simpleMessage("投喂"),
        "double_week": MessageLookupByLibrary.simpleMessage("双周"),
        "easter_egg": MessageLookupByLibrary.simpleMessage(
            "感谢小百合工作室\n感谢 @ns @lgt @FengChendian 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n特别感谢 1A335 三位室友的支持\n感谢各位提供反馈的 NJUers\n谨以此 APP 敬我的大学时光"),
        "export_classtable_subtitle": MessageLookupByLibrary.simpleMessage(
            "导出当前课表为二维码/链接\n使用公共服务 file.io"),
        "export_classtable_title":
            MessageLookupByLibrary.simpleMessage("导出当前课表"),
        "export_title": MessageLookupByLibrary.simpleMessage("导出课程表"),
        "fix_week_dialog_content":
            MessageLookupByLibrary.simpleMessage("检测到学期周数与当前不一致，是否立即矫正？"),
        "fix_week_dialog_title": MessageLookupByLibrary.simpleMessage("周数矫正"),
        "fix_week_toast_success":
            MessageLookupByLibrary.simpleMessage("矫正周数成功！OvO"),
        "flutter_lts": MessageLookupByLibrary.simpleMessage("(Flutter LTS)"),
        "force_zoom_subtitle":
            MessageLookupByLibrary.simpleMessage("强制缩放课程表为一页"),
        "force_zoom_title": MessageLookupByLibrary.simpleMessage("强制缩放"),
        "free_class_banner": m3,
        "free_class_button": MessageLookupByLibrary.simpleMessage("查看"),
        "free_time": MessageLookupByLibrary.simpleMessage("自由时间"),
        "github_open_source": MessageLookupByLibrary.simpleMessage("GitHub 开源"),
        "go_to_settings_toast":
            MessageLookupByLibrary.simpleMessage("修改当前周数请前往设置ww"),
        "hide_add_button_subtitle":
            MessageLookupByLibrary.simpleMessage("隐藏主界面右下角添加按钮"),
        "hide_add_button_title": MessageLookupByLibrary.simpleMessage("隐藏添加按钮"),
        "hide_free_class_button": MessageLookupByLibrary.simpleMessage("隐藏"),
        "hide_free_class_dialog_content": MessageLookupByLibrary.simpleMessage(
            "确认隐藏自由时间课程？\n您可在[设置]-[自定义选项]-[显示自由时间课程]选项中再次启用显示该模块～"),
        "hide_free_class_dialog_title":
            MessageLookupByLibrary.simpleMessage("隐藏自由时间课程"),
        "if_show_classtime_subtitle":
            MessageLookupByLibrary.simpleMessage("设置是否显示课程时间"),
        "if_show_classtime_title":
            MessageLookupByLibrary.simpleMessage("显示课程时间"),
        "if_show_freeclass_subtitle":
            MessageLookupByLibrary.simpleMessage("设置是否显示自由时间课程"),
        "if_show_freeclass_title":
            MessageLookupByLibrary.simpleMessage("显示自由时间课程"),
        "if_show_weekend_subtitle":
            MessageLookupByLibrary.simpleMessage("设置是否显示周六周日"),
        "if_show_weekend_title": MessageLookupByLibrary.simpleMessage("显示周末"),
        "import": MessageLookupByLibrary.simpleMessage("导入"),
        "import_auto": MessageLookupByLibrary.simpleMessage("自动导入"),
        "import_banner": MessageLookupByLibrary.simpleMessage(
            "注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常"),
        "import_banner_action":
            MessageLookupByLibrary.simpleMessage("下载南京大学VPN"),
        "import_from_JW_title": MessageLookupByLibrary.simpleMessage("导入课程表"),
        "import_from_NJU_cer_subtitle":
            MessageLookupByLibrary.simpleMessage("推荐通过统一认证进行登录导入"),
        "import_from_NJU_cer_title":
            MessageLookupByLibrary.simpleMessage("南京大学本科生统一认证"),
        "import_from_NJU_subtitle":
            MessageLookupByLibrary.simpleMessage("20级前同学可使用此方法登录导入"),
        "import_from_NJU_title":
            MessageLookupByLibrary.simpleMessage("南京大学本科生教务系统"),
        "import_from_NJU_xk_subtitle":
            MessageLookupByLibrary.simpleMessage("新选课系统，尚不稳定的备选导入方式"),
        "import_from_NJU_xk_title":
            MessageLookupByLibrary.simpleMessage("南京大学本科生选课系统"),
        "import_from_lecture": MessageLookupByLibrary.simpleMessage("讲座导入"),
        "import_from_qrcode_content": MessageLookupByLibrary.simpleMessage(
            "扫描二维码导入此课表\n南哪课表-设置-导入/导出课表-二维码导入课表\n有效期一周，扫描一次后过期"),
        "import_from_qrcode_subtitle":
            MessageLookupByLibrary.simpleMessage("从他人分享的二维码导入课表"),
        "import_from_qrcode_title":
            MessageLookupByLibrary.simpleMessage("二维码导入课表"),
        "import_inline":
            MessageLookupByLibrary.simpleMessage("内置导入：应用内自带的导入方式"),
        "import_manually": MessageLookupByLibrary.simpleMessage("手动导入"),
        "import_manually_subtitle":
            MessageLookupByLibrary.simpleMessage("手动添加课程表数据"),
        "import_manually_title": MessageLookupByLibrary.simpleMessage("手动添加"),
        "import_more_schools": MessageLookupByLibrary.simpleMessage("适配更多学校"),
        "import_online":
            MessageLookupByLibrary.simpleMessage("在线导入：从服务器获取的最新配置"),
        "import_or_export_subtitle":
            MessageLookupByLibrary.simpleMessage("使用南哪课表内置的导入/导出功能"),
        "import_or_export_title":
            MessageLookupByLibrary.simpleMessage("导入/导出课表"),
        "import_qr_title": MessageLookupByLibrary.simpleMessage("二维码导入"),
        "import_settings_title": MessageLookupByLibrary.simpleMessage("导入课程表"),
        "import_subtitle": MessageLookupByLibrary.simpleMessage("自动导入课程表数据"),
        "import_success_toast": MessageLookupByLibrary.simpleMessage("导入完成"),
        "import_title": MessageLookupByLibrary.simpleMessage("导入课程表"),
        "importing_toast": MessageLookupByLibrary.simpleMessage("导入中 请稍后"),
        "introduction": MessageLookupByLibrary.simpleMessage(
            "博客：https://idealclover.top\nEmail：idealclover@163.com"),
        "lecture_add": m4,
        "lecture_add_expired_toast":
            MessageLookupByLibrary.simpleMessage("讲座已经结束了喵～"),
        "lecture_add_fail_toast":
            MessageLookupByLibrary.simpleMessage("讲座添加失败，可能是学期不对"),
        "lecture_add_success_toast":
            MessageLookupByLibrary.simpleMessage("讲座已添加至当前课表～"),
        "lecture_added": m5,
        "lecture_added_toast":
            MessageLookupByLibrary.simpleMessage("这个讲座已经添加过啦～"),
        "lecture_bottom":
            MessageLookupByLibrary.simpleMessage("讲座列表由南哪助手团队提供与维护"),
        "lecture_cast_dialog_content": MessageLookupByLibrary.simpleMessage(
            "该讲座时间不完全对应课表节数，已为您匹配最近课程时间，请在课程详情中关注该讲座具体时间\n\n确认添加该讲座至当前课表？"),
        "lecture_cast_dialog_title":
            MessageLookupByLibrary.simpleMessage("讲座时间不完全对应"),
        "lecture_expired": m6,
        "lecture_no_classroom": MessageLookupByLibrary.simpleMessage("暂无地点"),
        "lecture_no_info": MessageLookupByLibrary.simpleMessage("暂无信息"),
        "lecture_no_name": MessageLookupByLibrary.simpleMessage("暂无名称"),
        "lecture_no_teacher": MessageLookupByLibrary.simpleMessage("暂无老师"),
        "lecture_no_time": MessageLookupByLibrary.simpleMessage("暂无时间"),
        "lecture_refresh_fail_toast":
            MessageLookupByLibrary.simpleMessage("刷新失败了喵，检查下网络吧"),
        "lecture_refresh_success_toast":
            MessageLookupByLibrary.simpleMessage("讲座列表刷新成功"),
        "lecture_search": MessageLookupByLibrary.simpleMessage("搜索讲座"),
        "lecture_teacher_title": MessageLookupByLibrary.simpleMessage("主讲人："),
        "lecture_title": MessageLookupByLibrary.simpleMessage("讲座列表"),
        "love_and_donate": MessageLookupByLibrary.simpleMessage("完美导入！投喂傻翠w"),
        "love_but_no_money": MessageLookupByLibrary.simpleMessage("感谢制作，但我没钱"),
        "manage_table_subtitle":
            MessageLookupByLibrary.simpleMessage("添加或删除课表数据"),
        "manage_table_title": MessageLookupByLibrary.simpleMessage("课表管理"),
        "month": MessageLookupByLibrary.simpleMessage("月"),
        "more_settings_subtitle":
            MessageLookupByLibrary.simpleMessage("课表样式设置，高级设置与试验功能"),
        "more_settings_title": MessageLookupByLibrary.simpleMessage("自定义选项"),
        "network_error_toast": MessageLookupByLibrary.simpleMessage("网络错误，请重试"),
        "not_open": MessageLookupByLibrary.simpleMessage("[未开学]"),
        "not_this_week": MessageLookupByLibrary.simpleMessage("[非本周]"),
        "nowweek_edited_success_toast":
            MessageLookupByLibrary.simpleMessage("修改当前周成功 >v<"),
        "nowweek_not_edited_success_toast":
            MessageLookupByLibrary.simpleMessage("当前周未修改 >v<"),
        "ok": MessageLookupByLibrary.simpleMessage("确认"),
        "online_parse_error_toast":
            MessageLookupByLibrary.simpleMessage("导入课表失败，可能是 bug"),
        "open_source_library_content": MessageLookupByLibrary.simpleMessage(
            "shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0"),
        "open_source_library_title":
            MessageLookupByLibrary.simpleMessage("所使用到的开源库"),
        "parse_error_dialog_add_group":
            MessageLookupByLibrary.simpleMessage("加入用户群报告问题"),
        "parse_error_dialog_content": m7,
        "parse_error_dialog_other_ways":
            MessageLookupByLibrary.simpleMessage("试试其他导入方式"),
        "parse_error_dialog_title":
            MessageLookupByLibrary.simpleMessage("Oops，导入失败惹 TvT"),
        "password": MessageLookupByLibrary.simpleMessage("密码"),
        "password_error_toast":
            MessageLookupByLibrary.simpleMessage("密码错误 = =||"),
        "pay_open_fail_toast": MessageLookupByLibrary.simpleMessage("打开失败"),
        "qrcode_name_error_toast":
            MessageLookupByLibrary.simpleMessage("读取课表名称失败，可能为链接错误"),
        "qrcode_read_error_toast":
            MessageLookupByLibrary.simpleMessage("读取课程表，可能是 bug"),
        "qrcode_url_error_toast":
            MessageLookupByLibrary.simpleMessage("二维码无效，可能为链接过期"),
        "remember_password": MessageLookupByLibrary.simpleMessage("记住密码"),
        "report_subtitle": MessageLookupByLibrary.simpleMessage(
            "加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号"),
        "report_title": MessageLookupByLibrary.simpleMessage("反馈"),
        "settings_title": MessageLookupByLibrary.simpleMessage("设置"),
        "share_content": MessageLookupByLibrary.simpleMessage(
            "南哪课表-南大同学的专属课表APP，导课表、蹭好课、找讲座，快来试试吧！ https://nju.app"),
        "share_subtitle":
            MessageLookupByLibrary.simpleMessage("把南哪课表分享给更多小伙伴吧！"),
        "share_title": MessageLookupByLibrary.simpleMessage("分享此应用"),
        "show_date_subtitle": MessageLookupByLibrary.simpleMessage("显示当前周的日期"),
        "show_date_title": MessageLookupByLibrary.simpleMessage("显示日期"),
        "show_month_subtitle":
            MessageLookupByLibrary.simpleMessage("在课表的左上角显示当前月份"),
        "show_month_title": MessageLookupByLibrary.simpleMessage("显示月份"),
        "shuffle_color_pool_subtitle":
            MessageLookupByLibrary.simpleMessage("重置课程颜色池"),
        "shuffle_color_pool_success_toast":
            MessageLookupByLibrary.simpleMessage("重置颜色池成功 >v<"),
        "shuffle_color_pool_title":
            MessageLookupByLibrary.simpleMessage("重置课程颜色"),
        "single_week": MessageLookupByLibrary.simpleMessage("单周"),
        "tap_to_refresh": MessageLookupByLibrary.simpleMessage("点击刷新"),
        "to": MessageLookupByLibrary.simpleMessage("-"),
        "unknown_info": MessageLookupByLibrary.simpleMessage("暂无备注"),
        "unknown_place": MessageLookupByLibrary.simpleMessage("未知地点"),
        "username": MessageLookupByLibrary.simpleMessage("用户名"),
        "username_error_toast":
            MessageLookupByLibrary.simpleMessage("用户名错误 TvT"),
        "view_lecture_subtitle":
            MessageLookupByLibrary.simpleMessage("查看南哪最新讲座信息，可一键导入至课表"),
        "view_lecture_title": MessageLookupByLibrary.simpleMessage("查看/添加讲座"),
        "week": m8,
        "week_duration": m9,
        "week_num_invalid_dialog_content":
            MessageLookupByLibrary.simpleMessage("课程结束周数应大于起始周数"),
        "week_num_invalid_dialog_title":
            MessageLookupByLibrary.simpleMessage("课程周数不合法"),
        "welcome_content": MessageLookupByLibrary.simpleMessage(
            "2021.08\n又是新的学期啦\n21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh\n\n2021.2\n不知不觉小作文更新这么长了～\n\n又是新的一年，新的一学期了。\n\n过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。\n\n所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～\n\n过去的时光，我们都辛苦了，未来，一起加油。\n\n“敬自己一杯，因为值得。”\n\n2020.9\n这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。\n\n离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。\n\n大概，衷心希望学弟学妹们珍惜大学生活w\n\n2020.5\n在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！\n\n2020.2\n2020年2月全部投喂收入将捐赠以支援湖北疫情\n(2020.3补充：已捐赠)\n\n2019.9\nHi！我是项目作者傻翠～\n\n看起来你已经导入我南教务处成功啦！撒花撒花！\n\n建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～\n\n坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。\n\n写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。\n\n放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。\n\n希望南哪课表可以陪伴学弟学妹们走过每一学期ww\n\n傻翠"),
        "welcome_content_html": MessageLookupByLibrary.simpleMessage(
            "<p><b>2021.08</b></p><p>又是新的学期啦</p><p>21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh</p><p><b>2021.2</b></p><p>不知不觉小作文更新这么长了～</p><p>又是新的一年，新的一学期了。</p><p>过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。</p><p>所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～</p><p>过去的时光，我们都辛苦了，未来，一起加油。</p><p>“敬自己一杯，因为值得。”</p><p><b>2020.9</b></p><p>这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。</p><p>离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。</p><p>大概，衷心希望学弟学妹们珍惜大学生活w</p><p><b>2020.5</b></p><p>在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！</p><p><b>2020.2</b></p><p>2020年2月全部投喂收入将捐赠以支援湖北疫情</p><p>(2020.3补充：已捐赠)</p><p><b>2019.9</b></p><p>Hi！我是项目作者傻翠～</p><p>看起来你已经导入我南教务处成功啦！撒花撒花！</p><p>建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～</p><p>坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。</p><p>写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。</p><p>放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。</p><p>希望南哪课表可以陪伴学弟学妹们走过每一学期ww</p><p>傻翠</p>"),
        "welcome_title": MessageLookupByLibrary.simpleMessage("欢迎使用南哪课表！"),
        "white_title_mode_subtitle":
            MessageLookupByLibrary.simpleMessage("如果背景图片是暗色的话"),
        "white_title_mode_title": MessageLookupByLibrary.simpleMessage("白色标题模式")
      };
}
