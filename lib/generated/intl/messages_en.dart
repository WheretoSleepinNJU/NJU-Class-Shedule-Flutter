// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static m0(start, end) => "第 ${start} - ${end} 节";

  static m1(num) => "第 ${num} 节";

  static m2(className) => "确定删除课程【 ${className} 】吗？";

  static m3(num) => "第 ${num} 周";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "QQ_copy_success_toast" : MessageLookupByLibrary.simpleMessage("已复制群号到剪贴板"),
    "QQ_open_fail_toast" : MessageLookupByLibrary.simpleMessage("打开失败，可能是未安装 TIM/QQ"),
    "about_title" : MessageLookupByLibrary.simpleMessage("关于"),
    "add_backgound_picture_subtitle" : MessageLookupByLibrary.simpleMessage("上传背景图片"),
    "add_backgound_picture_success_toast" : MessageLookupByLibrary.simpleMessage("更换背景图片成功ww"),
    "add_backgound_picture_title" : MessageLookupByLibrary.simpleMessage("上传背景图片"),
    "add_class" : MessageLookupByLibrary.simpleMessage("添加课程"),
    "add_class_table_dialog_title" : MessageLookupByLibrary.simpleMessage("请输入课程表名称"),
    "add_class_table_success_toast" : MessageLookupByLibrary.simpleMessage("添加课程表成功"),
    "add_manually_success_toast" : MessageLookupByLibrary.simpleMessage("添加成功！>v<"),
    "add_manually_title" : MessageLookupByLibrary.simpleMessage("添加课程"),
    "already_newest_version_toast" : MessageLookupByLibrary.simpleMessage("已经是最新版本了呦～"),
    "app_name" : MessageLookupByLibrary.simpleMessage("南哪课表"),
    "at" : MessageLookupByLibrary.simpleMessage("@"),
    "bug_and_report" : MessageLookupByLibrary.simpleMessage("似乎有bug，我要反馈"),
    "cancel" : MessageLookupByLibrary.simpleMessage("取消"),
    "captcha" : MessageLookupByLibrary.simpleMessage("验证码"),
    "captcha_error_toast" : MessageLookupByLibrary.simpleMessage("验证码错误 > <"),
    "change_theme_title" : MessageLookupByLibrary.simpleMessage("修改主题"),
    "change_week_subtitle" : MessageLookupByLibrary.simpleMessage("当前周数："),
    "change_week_title" : MessageLookupByLibrary.simpleMessage("修改当前周"),
    "check_update_button" : MessageLookupByLibrary.simpleMessage("检查更新"),
    "choose_class_time_dialog_title" : MessageLookupByLibrary.simpleMessage("选择上课时间"),
    "class_duration" : m0,
    "class_name" : MessageLookupByLibrary.simpleMessage("课程名称"),
    "class_name_empty" : MessageLookupByLibrary.simpleMessage("请输入课程名称"),
    "class_num_invalid_dialog_content" : MessageLookupByLibrary.simpleMessage("课程结束节数应大于起始节数"),
    "class_num_invalid_dialog_title" : MessageLookupByLibrary.simpleMessage("课程节数不合法"),
    "class_parse_error_toast" : MessageLookupByLibrary.simpleMessage("课程解析失败 = =|| 可将课表反馈至翠翠"),
    "class_parse_toast_fail" : MessageLookupByLibrary.simpleMessage("出现异常，建议提交反馈"),
    "class_parse_toast_success" : MessageLookupByLibrary.simpleMessage("数据存储成功 >v<"),
    "class_room" : MessageLookupByLibrary.simpleMessage("上课地点"),
    "class_single" : m1,
    "class_table_manage_title" : MessageLookupByLibrary.simpleMessage("课表管理"),
    "class_teacher" : MessageLookupByLibrary.simpleMessage("上课老师"),
    "del_class_table_dialog_content" : MessageLookupByLibrary.simpleMessage("此操作无法恢复，这将删除该课程表下的所有课程。"),
    "del_class_table_dialog_title" : MessageLookupByLibrary.simpleMessage("确认删除"),
    "del_class_table_success_toast" : MessageLookupByLibrary.simpleMessage("删除课程表成功"),
    "delete_backgound_picture_subtitle" : MessageLookupByLibrary.simpleMessage("恢复默认白色背景"),
    "delete_backgound_picture_success_toast" : MessageLookupByLibrary.simpleMessage("已恢复默认背景ww"),
    "delete_backgound_picture_title" : MessageLookupByLibrary.simpleMessage("清除背景图片"),
    "delete_class_dialog_content" : m2,
    "delete_class_dialog_title" : MessageLookupByLibrary.simpleMessage("删除课程"),
    "developer" : MessageLookupByLibrary.simpleMessage("开发者 idealclover"),
    "donate_subtitle" : MessageLookupByLibrary.simpleMessage("给傻翠买支棒棒糖吧！"),
    "donate_title" : MessageLookupByLibrary.simpleMessage("投喂"),
    "easter_egg" : MessageLookupByLibrary.simpleMessage("感谢小百合工作室\n感谢 @ns @lgt 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n特别感谢 1A335 三位室友的支持\n感谢各位提供反馈的 NJUers\n谨以此 APP 敬我的大学时光\n啊对了 谢谢 祝幸福"),
    "export_classtable_subtitle" : MessageLookupByLibrary.simpleMessage("导出当前课表为二维码/链接\n使用公共服务 file.io"),
    "export_classtable_title" : MessageLookupByLibrary.simpleMessage("导出当前课表"),
    "export_title" : MessageLookupByLibrary.simpleMessage("导出"),
    "fix_week_dialog_content" : MessageLookupByLibrary.simpleMessage("检测到学期周数与当前不一致，是否立即矫正？"),
    "fix_week_dialog_title" : MessageLookupByLibrary.simpleMessage("周数矫正"),
    "fix_week_toast_success" : MessageLookupByLibrary.simpleMessage("矫正周数成功！OvO"),
    "flutter_lts" : MessageLookupByLibrary.simpleMessage("(Flutter LTS)"),
    "force_zoom_subtitle" : MessageLookupByLibrary.simpleMessage("强制缩放课程表为一页"),
    "force_zoom_title" : MessageLookupByLibrary.simpleMessage("强制缩放"),
    "github_open_source" : MessageLookupByLibrary.simpleMessage("GitHub 开源"),
    "go_to_settings_toast" : MessageLookupByLibrary.simpleMessage("修改当前周数请前往设置ww"),
    "hide_add_button_subtitle" : MessageLookupByLibrary.simpleMessage("隐藏主界面右下角添加按钮"),
    "hide_add_button_title" : MessageLookupByLibrary.simpleMessage("隐藏添加按钮"),
    "if_show_classtime_subtitle" : MessageLookupByLibrary.simpleMessage("设置是否显示课程时间"),
    "if_show_classtime_title" : MessageLookupByLibrary.simpleMessage("显示课程时间"),
    "if_show_weekend_subtitle" : MessageLookupByLibrary.simpleMessage("设置是否显示周六周日"),
    "if_show_weekend_title" : MessageLookupByLibrary.simpleMessage("显示周末"),
    "import" : MessageLookupByLibrary.simpleMessage("导入"),
    "import_auto" : MessageLookupByLibrary.simpleMessage("自动导入"),
    "import_from_NJU_cer_subtitle" : MessageLookupByLibrary.simpleMessage("教务处哇教务处，不愧是你"),
    "import_from_NJU_cer_title" : MessageLookupByLibrary.simpleMessage("从南京大学统一认证导入课表"),
    "import_from_NJU_subtitle" : MessageLookupByLibrary.simpleMessage("登录南京大学教务系统导入课程表"),
    "import_from_NJU_title" : MessageLookupByLibrary.simpleMessage("从南京大学教务处导入课表"),
    "import_from_qrcode_subtitle" : MessageLookupByLibrary.simpleMessage("从他人分享的二维码导入课表"),
    "import_from_qrcode_title" : MessageLookupByLibrary.simpleMessage("二维码导入课表"),
    "import_manually" : MessageLookupByLibrary.simpleMessage("手动导入"),
    "import_manually_subtitle" : MessageLookupByLibrary.simpleMessage("手动添加课程表数据"),
    "import_manually_title" : MessageLookupByLibrary.simpleMessage("手动添加"),
    "import_or_export_subtitle" : MessageLookupByLibrary.simpleMessage("使用南哪课表内置的导入/导出功能"),
    "import_or_export_title" : MessageLookupByLibrary.simpleMessage("导入/导出课表"),
    "import_success_toast" : MessageLookupByLibrary.simpleMessage("导入完成"),
    "import_title" : MessageLookupByLibrary.simpleMessage("导入课程表"),
    "importing_toast" : MessageLookupByLibrary.simpleMessage("导入中 请稍后"),
    "introduction" : MessageLookupByLibrary.simpleMessage("博客：https://idealclover.top\nEmail：idealclover@163.com"),
    "love_and_donate" : MessageLookupByLibrary.simpleMessage("完美导入！投喂傻翠w"),
    "love_but_no_money" : MessageLookupByLibrary.simpleMessage("感谢制作，但我没钱"),
    "manage_table_subtitle" : MessageLookupByLibrary.simpleMessage("添加或删除课表数据"),
    "manage_table_title" : MessageLookupByLibrary.simpleMessage("课表管理"),
    "month" : MessageLookupByLibrary.simpleMessage("月"),
    "more_settings_subtitle" : MessageLookupByLibrary.simpleMessage("课表样式设置，高级设置与试验功能"),
    "more_settings_title" : MessageLookupByLibrary.simpleMessage("自定义选项"),
    "not_open" : MessageLookupByLibrary.simpleMessage("[未开学]"),
    "not_this_week" : MessageLookupByLibrary.simpleMessage("[非本周]"),
    "nowweek_edited_success_toast" : MessageLookupByLibrary.simpleMessage("修改当前周成功 >v<"),
    "nowweek_not_edited_success_toast" : MessageLookupByLibrary.simpleMessage("当前周未修改 >v<"),
    "ok" : MessageLookupByLibrary.simpleMessage("确认"),
    "open_source_library_content" : MessageLookupByLibrary.simpleMessage("shared_preferences: ^0.5.3+4\npackage_info: ^0.4.0+6\nflutter_bugly: ^0.2.6\nurl_launcher: ^5.1.2\nscoped_model: ^1.0.1\nfluttertoast: ^3.1.3\nsqflite: ^1.1.6\nintl: ^0.16.0"),
    "open_source_library_title" : MessageLookupByLibrary.simpleMessage("所使用到的开源库"),
    "password" : MessageLookupByLibrary.simpleMessage("密码"),
    "password_error_toast" : MessageLookupByLibrary.simpleMessage("密码错误 = =||"),
    "pay_open_fail_toast" : MessageLookupByLibrary.simpleMessage("打开失败"),
    "qrcode_name_error_toast" : MessageLookupByLibrary.simpleMessage("读取课表名称失败，可能为链接错误"),
    "qrcode_read_error_toast" : MessageLookupByLibrary.simpleMessage("读取课程表，可能是 bug"),
    "qrcode_url_error_toast" : MessageLookupByLibrary.simpleMessage("二维码无效，可能为链接过期"),
    "remember_password" : MessageLookupByLibrary.simpleMessage("记住密码"),
    "report_subtitle" : MessageLookupByLibrary.simpleMessage("加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号"),
    "report_title" : MessageLookupByLibrary.simpleMessage("反馈"),
    "settings_title" : MessageLookupByLibrary.simpleMessage("设置"),
    "show_date_subtitle" : MessageLookupByLibrary.simpleMessage("显示当前周的日期"),
    "show_date_title" : MessageLookupByLibrary.simpleMessage("显示日期"),
    "show_month_subtitle" : MessageLookupByLibrary.simpleMessage("在课表的左上角显示当前月份"),
    "show_month_title" : MessageLookupByLibrary.simpleMessage("显示月份"),
    "shuffle_color_pool_subtitle" : MessageLookupByLibrary.simpleMessage("重置课程颜色池"),
    "shuffle_color_pool_success_toast" : MessageLookupByLibrary.simpleMessage("重置颜色池成功 >v<"),
    "shuffle_color_pool_title" : MessageLookupByLibrary.simpleMessage("重置课程颜色"),
    "tap_to_refresh" : MessageLookupByLibrary.simpleMessage("点击刷新"),
    "to" : MessageLookupByLibrary.simpleMessage("-"),
    "unknown_place" : MessageLookupByLibrary.simpleMessage("未知地点"),
    "username" : MessageLookupByLibrary.simpleMessage("用户名"),
    "username_error_toast" : MessageLookupByLibrary.simpleMessage("用户名错误 TvT"),
    "week" : m3,
    "week_num_invalid_dialog_content" : MessageLookupByLibrary.simpleMessage("课程结束周数应大于起始周数"),
    "week_num_invalid_dialog_title" : MessageLookupByLibrary.simpleMessage("课程周数不合法"),
    "welcome_content" : MessageLookupByLibrary.simpleMessage("2020.5\n在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！\n\n2020.2\n年2月全部投喂收入将捐赠以支援湖北疫情\n\n2019.9\nHi！我是项目作者傻翠～\n\n看起来你已经导入我南教务处成功啦！撒花撒花！\n\n建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～\n\n坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug。这都是我所会预料到的，如果你不巧遇到了bug，也欢迎向我反馈。\n\n写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的macbook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。\n\n其实我大四已经没课了，也早不需要课表这种东西了，可能你们的支持是我继续下去的唯一动力吧ww\n\n放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。\n\n希望南哪课表可以陪伴学弟学妹们走过每一学期ww\n\n傻翠"),
    "welcome_title" : MessageLookupByLibrary.simpleMessage("欢迎使用南哪课表！"),
    "white_title_mode_subtitle" : MessageLookupByLibrary.simpleMessage("如果背景图片是暗色的话"),
    "white_title_mode_title" : MessageLookupByLibrary.simpleMessage("白色标题模式")
  };
}