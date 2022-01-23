// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `南哪课表`
  String get app_name {
    return Intl.message(
      '南哪课表',
      name: 'app_name',
      desc: '',
      args: [],
    );
  }

  /// `(Flutter LTS)`
  String get flutter_lts {
    return Intl.message(
      '(Flutter LTS)',
      name: 'flutter_lts',
      desc: '',
      args: [],
    );
  }

  /// `@`
  String get at {
    return Intl.message(
      '@',
      name: 'at',
      desc: '',
      args: [],
    );
  }

  /// `-`
  String get to {
    return Intl.message(
      '-',
      name: 'to',
      desc: '',
      args: [],
    );
  }

  /// `月`
  String get month {
    return Intl.message(
      '月',
      name: 'month',
      desc: '',
      args: [],
    );
  }

  /// `第 {num} 周`
  String week(Object num) {
    return Intl.message(
      '第 $num 周',
      name: 'week',
      desc: '',
      args: [num],
    );
  }

  /// `{start}-{end} 周`
  String week_duration(Object start, Object end) {
    return Intl.message(
      '$start-$end 周',
      name: 'week_duration',
      desc: '',
      args: [start, end],
    );
  }

  /// `第 {num} 节`
  String class_single(Object num) {
    return Intl.message(
      '第 $num 节',
      name: 'class_single',
      desc: '',
      args: [num],
    );
  }

  /// `第 {start}-{end} 节`
  String class_duration(Object start, Object end) {
    return Intl.message(
      '第 $start-$end 节',
      name: 'class_duration',
      desc: '',
      args: [start, end],
    );
  }

  /// `[非本周]`
  String get not_this_week {
    return Intl.message(
      '[非本周]',
      name: 'not_this_week',
      desc: '',
      args: [],
    );
  }

  /// `单周`
  String get single_week {
    return Intl.message(
      '单周',
      name: 'single_week',
      desc: '',
      args: [],
    );
  }

  /// `双周`
  String get double_week {
    return Intl.message(
      '双周',
      name: 'double_week',
      desc: '',
      args: [],
    );
  }

  /// `[未开学]`
  String get not_open {
    return Intl.message(
      '[未开学]',
      name: 'not_open',
      desc: '',
      args: [],
    );
  }

  /// `自由时间`
  String get free_time {
    return Intl.message(
      '自由时间',
      name: 'free_time',
      desc: '',
      args: [],
    );
  }

  /// `未知地点`
  String get unknown_place {
    return Intl.message(
      '未知地点',
      name: 'unknown_place',
      desc: '',
      args: [],
    );
  }

  /// `暂无备注`
  String get unknown_info {
    return Intl.message(
      '暂无备注',
      name: 'unknown_info',
      desc: '',
      args: [],
    );
  }

  /// `自动导入`
  String get import_auto {
    return Intl.message(
      '自动导入',
      name: 'import_auto',
      desc: '',
      args: [],
    );
  }

  /// `手动导入`
  String get import_manually {
    return Intl.message(
      '手动导入',
      name: 'import_manually',
      desc: '',
      args: [],
    );
  }

  /// `讲座导入`
  String get import_from_lecture {
    return Intl.message(
      '讲座导入',
      name: 'import_from_lecture',
      desc: '',
      args: [],
    );
  }

  /// `另有 {num} 节「自由时间」课程 >>`
  String free_class_banner(Object num) {
    return Intl.message(
      '另有 $num 节「自由时间」课程 >>',
      name: 'free_class_banner',
      desc: '',
      args: [num],
    );
  }

  /// `查看`
  String get free_class_button {
    return Intl.message(
      '查看',
      name: 'free_class_button',
      desc: '',
      args: [],
    );
  }

  /// `隐藏`
  String get hide_free_class_button {
    return Intl.message(
      '隐藏',
      name: 'hide_free_class_button',
      desc: '',
      args: [],
    );
  }

  /// `隐藏自由时间课程`
  String get hide_free_class_dialog_title {
    return Intl.message(
      '隐藏自由时间课程',
      name: 'hide_free_class_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `确认隐藏自由时间课程？\n您可在[设置]-[自定义选项]-[显示自由时间课程]选项中再次启用显示该模块～`
  String get hide_free_class_dialog_content {
    return Intl.message(
      '确认隐藏自由时间课程？\n您可在[设置]-[自定义选项]-[显示自由时间课程]选项中再次启用显示该模块～',
      name: 'hide_free_class_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `删除课程`
  String get delete_class_dialog_title {
    return Intl.message(
      '删除课程',
      name: 'delete_class_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `确定删除课程【 {className} 】吗？`
  String delete_class_dialog_content(Object className) {
    return Intl.message(
      '确定删除课程【 $className 】吗？',
      name: 'delete_class_dialog_content',
      desc: '',
      args: [className],
    );
  }

  /// `设置`
  String get settings_title {
    return Intl.message(
      '设置',
      name: 'settings_title',
      desc: '',
      args: [],
    );
  }

  /// `手动添加`
  String get import_manually_title {
    return Intl.message(
      '手动添加',
      name: 'import_manually_title',
      desc: '',
      args: [],
    );
  }

  /// `手动添加课程表数据`
  String get import_manually_subtitle {
    return Intl.message(
      '手动添加课程表数据',
      name: 'import_manually_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `导入课程表`
  String get import_from_JW_title {
    return Intl.message(
      '导入课程表',
      name: 'import_from_JW_title',
      desc: '',
      args: [],
    );
  }

  /// `自动导入课程表数据`
  String get import_subtitle {
    return Intl.message(
      '自动导入课程表数据',
      name: 'import_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `从南京大学教务系统导入课表`
  String get import_from_NJU_title {
    return Intl.message(
      '从南京大学教务系统导入课表',
      name: 'import_from_NJU_title',
      desc: '',
      args: [],
    );
  }

  /// `20级前同学可使用此方法登录导入`
  String get import_from_NJU_subtitle {
    return Intl.message(
      '20级前同学可使用此方法登录导入',
      name: 'import_from_NJU_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `从南京大学统一认证导入课表`
  String get import_from_NJU_cer_title {
    return Intl.message(
      '从南京大学统一认证导入课表',
      name: 'import_from_NJU_cer_title',
      desc: '',
      args: [],
    );
  }

  /// `推荐通过统一认证进行登录导入`
  String get import_from_NJU_cer_subtitle {
    return Intl.message(
      '推荐通过统一认证进行登录导入',
      name: 'import_from_NJU_cer_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `从南京大学选课系统导入课表`
  String get import_from_NJU_xk_title {
    return Intl.message(
      '从南京大学选课系统导入课表',
      name: 'import_from_NJU_xk_title',
      desc: '',
      args: [],
    );
  }

  /// `新选课系统，尚不稳定的备选导入方式`
  String get import_from_NJU_xk_subtitle {
    return Intl.message(
      '新选课系统，尚不稳定的备选导入方式',
      name: 'import_from_NJU_xk_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `查看/添加全校课表`
  String get all_course_title {
    return Intl.message(
      '查看/添加全校课表',
      name: 'all_course_title',
      desc: '',
      args: [],
    );
  }

  /// `查看南哪全校课表，可一键导入至课表`
  String get all_course_subtitle {
    return Intl.message(
      '查看南哪全校课表，可一键导入至课表',
      name: 'all_course_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `查看/添加讲座`
  String get view_lecture_title {
    return Intl.message(
      '查看/添加讲座',
      name: 'view_lecture_title',
      desc: '',
      args: [],
    );
  }

  /// `查看南哪最新讲座信息，可一键导入至课表`
  String get view_lecture_subtitle {
    return Intl.message(
      '查看南哪最新讲座信息，可一键导入至课表',
      name: 'view_lecture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `导入/导出课表`
  String get import_or_export_title {
    return Intl.message(
      '导入/导出课表',
      name: 'import_or_export_title',
      desc: '',
      args: [],
    );
  }

  /// `使用南哪课表内置的导入/导出功能`
  String get import_or_export_subtitle {
    return Intl.message(
      '使用南哪课表内置的导入/导出功能',
      name: 'import_or_export_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `课表管理`
  String get manage_table_title {
    return Intl.message(
      '课表管理',
      name: 'manage_table_title',
      desc: '',
      args: [],
    );
  }

  /// `添加或删除课表数据`
  String get manage_table_subtitle {
    return Intl.message(
      '添加或删除课表数据',
      name: 'manage_table_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `修改主题`
  String get change_theme_title {
    return Intl.message(
      '修改主题',
      name: 'change_theme_title',
      desc: '',
      args: [],
    );
  }

  /// `重置课程颜色`
  String get shuffle_color_pool_title {
    return Intl.message(
      '重置课程颜色',
      name: 'shuffle_color_pool_title',
      desc: '',
      args: [],
    );
  }

  /// `重置课程颜色池`
  String get shuffle_color_pool_subtitle {
    return Intl.message(
      '重置课程颜色池',
      name: 'shuffle_color_pool_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `修改当前周`
  String get change_week_title {
    return Intl.message(
      '修改当前周',
      name: 'change_week_title',
      desc: '',
      args: [],
    );
  }

  /// `当前周数：`
  String get change_week_subtitle {
    return Intl.message(
      '当前周数：',
      name: 'change_week_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `反馈`
  String get report_title {
    return Intl.message(
      '反馈',
      name: 'report_title',
      desc: '',
      args: [],
    );
  }

  /// `加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号`
  String get report_subtitle {
    return Intl.message(
      '加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号',
      name: 'report_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `投喂`
  String get donate_title {
    return Intl.message(
      '投喂',
      name: 'donate_title',
      desc: '',
      args: [],
    );
  }

  /// `给傻翠买支棒棒糖吧！`
  String get donate_subtitle {
    return Intl.message(
      '给傻翠买支棒棒糖吧！',
      name: 'donate_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `分享此应用`
  String get share_title {
    return Intl.message(
      '分享此应用',
      name: 'share_title',
      desc: '',
      args: [],
    );
  }

  /// `把南哪课表分享给更多小伙伴吧！`
  String get share_subtitle {
    return Intl.message(
      '把南哪课表分享给更多小伙伴吧！',
      name: 'share_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `南哪课表-南大同学的专属课表APP，导课表、蹭好课、找讲座，快来试试吧！ https://app.nju.today`
  String get share_content {
    return Intl.message(
      '南哪课表-南大同学的专属课表APP，导课表、蹭好课、找讲座，快来试试吧！ https://app.nju.today',
      name: 'share_content',
      desc: '',
      args: [],
    );
  }

  /// `关于`
  String get about_title {
    return Intl.message(
      '关于',
      name: 'about_title',
      desc: '',
      args: [],
    );
  }

  /// `自定义选项`
  String get more_settings_title {
    return Intl.message(
      '自定义选项',
      name: 'more_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `课表样式设置，高级设置与试验功能`
  String get more_settings_subtitle {
    return Intl.message(
      '课表样式设置，高级设置与试验功能',
      name: 'more_settings_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `白色标题模式`
  String get white_title_mode_title {
    return Intl.message(
      '白色标题模式',
      name: 'white_title_mode_title',
      desc: '',
      args: [],
    );
  }

  /// `如果背景图片是暗色的话`
  String get white_title_mode_subtitle {
    return Intl.message(
      '如果背景图片是暗色的话',
      name: 'white_title_mode_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `隐藏添加按钮`
  String get hide_add_button_title {
    return Intl.message(
      '隐藏添加按钮',
      name: 'hide_add_button_title',
      desc: '',
      args: [],
    );
  }

  /// `隐藏主界面右下角添加按钮`
  String get hide_add_button_subtitle {
    return Intl.message(
      '隐藏主界面右下角添加按钮',
      name: 'hide_add_button_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `显示月份`
  String get show_month_title {
    return Intl.message(
      '显示月份',
      name: 'show_month_title',
      desc: '',
      args: [],
    );
  }

  /// `在课表的左上角显示当前月份`
  String get show_month_subtitle {
    return Intl.message(
      '在课表的左上角显示当前月份',
      name: 'show_month_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `显示日期`
  String get show_date_title {
    return Intl.message(
      '显示日期',
      name: 'show_date_title',
      desc: '',
      args: [],
    );
  }

  /// `显示当前周的日期`
  String get show_date_subtitle {
    return Intl.message(
      '显示当前周的日期',
      name: 'show_date_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `显示周末`
  String get if_show_weekend_title {
    return Intl.message(
      '显示周末',
      name: 'if_show_weekend_title',
      desc: '',
      args: [],
    );
  }

  /// `设置是否显示周六周日`
  String get if_show_weekend_subtitle {
    return Intl.message(
      '设置是否显示周六周日',
      name: 'if_show_weekend_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `显示课程时间`
  String get if_show_classtime_title {
    return Intl.message(
      '显示课程时间',
      name: 'if_show_classtime_title',
      desc: '',
      args: [],
    );
  }

  /// `设置是否显示课程时间`
  String get if_show_classtime_subtitle {
    return Intl.message(
      '设置是否显示课程时间',
      name: 'if_show_classtime_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `显示自由时间课程`
  String get if_show_freeclass_title {
    return Intl.message(
      '显示自由时间课程',
      name: 'if_show_freeclass_title',
      desc: '',
      args: [],
    );
  }

  /// `设置是否显示自由时间课程`
  String get if_show_freeclass_subtitle {
    return Intl.message(
      '设置是否显示自由时间课程',
      name: 'if_show_freeclass_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `强制缩放`
  String get force_zoom_title {
    return Intl.message(
      '强制缩放',
      name: 'force_zoom_title',
      desc: '',
      args: [],
    );
  }

  /// `强制缩放课程表为一页`
  String get force_zoom_subtitle {
    return Intl.message(
      '强制缩放课程表为一页',
      name: 'force_zoom_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `上传背景图片`
  String get add_backgound_picture_title {
    return Intl.message(
      '上传背景图片',
      name: 'add_backgound_picture_title',
      desc: '',
      args: [],
    );
  }

  /// `上传背景图片`
  String get add_backgound_picture_subtitle {
    return Intl.message(
      '上传背景图片',
      name: 'add_backgound_picture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `清除背景图片`
  String get delete_backgound_picture_title {
    return Intl.message(
      '清除背景图片',
      name: 'delete_backgound_picture_title',
      desc: '',
      args: [],
    );
  }

  /// `恢复默认白色背景`
  String get delete_backgound_picture_subtitle {
    return Intl.message(
      '恢复默认白色背景',
      name: 'delete_backgound_picture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `已恢复默认背景ww`
  String get delete_backgound_picture_success_toast {
    return Intl.message(
      '已恢复默认背景ww',
      name: 'delete_backgound_picture_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `更换背景图片成功ww`
  String get add_backgound_picture_success_toast {
    return Intl.message(
      '更换背景图片成功ww',
      name: 'add_backgound_picture_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `自定义课程显示长度`
  String get class_height_title {
    return Intl.message(
      '自定义课程显示长度',
      name: 'class_height_title',
      desc: '',
      args: [],
    );
  }

  /// `仅当强制缩放关闭时生效`
  String get class_height_subtitle {
    return Intl.message(
      '仅当强制缩放关闭时生效',
      name: 'class_height_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `讲座列表`
  String get lecture_title {
    return Intl.message(
      '讲座列表',
      name: 'lecture_title',
      desc: '',
      args: [],
    );
  }

  /// `暂无名称`
  String get lecture_no_name {
    return Intl.message(
      '暂无名称',
      name: 'lecture_no_name',
      desc: '',
      args: [],
    );
  }

  /// `暂无时间`
  String get lecture_no_time {
    return Intl.message(
      '暂无时间',
      name: 'lecture_no_time',
      desc: '',
      args: [],
    );
  }

  /// `暂无老师`
  String get lecture_no_teacher {
    return Intl.message(
      '暂无老师',
      name: 'lecture_no_teacher',
      desc: '',
      args: [],
    );
  }

  /// `暂无地点`
  String get lecture_no_classroom {
    return Intl.message(
      '暂无地点',
      name: 'lecture_no_classroom',
      desc: '',
      args: [],
    );
  }

  /// `暂无信息`
  String get lecture_no_info {
    return Intl.message(
      '暂无信息',
      name: 'lecture_no_info',
      desc: '',
      args: [],
    );
  }

  /// `搜索讲座`
  String get lecture_search {
    return Intl.message(
      '搜索讲座',
      name: 'lecture_search',
      desc: '',
      args: [],
    );
  }

  /// `主讲人：`
  String get lecture_teacher_title {
    return Intl.message(
      '主讲人：',
      name: 'lecture_teacher_title',
      desc: '',
      args: [],
    );
  }

  /// `加入当前课表({num}人已添加)`
  String lecture_add(Object num) {
    return Intl.message(
      '加入当前课表($num人已添加)',
      name: 'lecture_add',
      desc: '',
      args: [num],
    );
  }

  /// `已添加({num}人已添加)`
  String lecture_added(Object num) {
    return Intl.message(
      '已添加($num人已添加)',
      name: 'lecture_added',
      desc: '',
      args: [num],
    );
  }

  /// `已结束({num}人已添加)`
  String lecture_expired(Object num) {
    return Intl.message(
      '已结束($num人已添加)',
      name: 'lecture_expired',
      desc: '',
      args: [num],
    );
  }

  /// `讲座列表刷新成功`
  String get lecture_refresh_success_toast {
    return Intl.message(
      '讲座列表刷新成功',
      name: 'lecture_refresh_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `刷新失败了喵，检查下网络吧`
  String get lecture_refresh_fail_toast {
    return Intl.message(
      '刷新失败了喵，检查下网络吧',
      name: 'lecture_refresh_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `讲座时间不完全对应`
  String get lecture_cast_dialog_title {
    return Intl.message(
      '讲座时间不完全对应',
      name: 'lecture_cast_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `该讲座时间不完全对应课表节数，已为您匹配最近课程时间，请在课程详情中关注该讲座具体时间\n\n确认添加该讲座至当前课表？`
  String get lecture_cast_dialog_content {
    return Intl.message(
      '该讲座时间不完全对应课表节数，已为您匹配最近课程时间，请在课程详情中关注该讲座具体时间\n\n确认添加该讲座至当前课表？',
      name: 'lecture_cast_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `讲座已添加至当前课表～`
  String get lecture_add_success_toast {
    return Intl.message(
      '讲座已添加至当前课表～',
      name: 'lecture_add_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `讲座添加失败，可能是学期不对`
  String get lecture_add_fail_toast {
    return Intl.message(
      '讲座添加失败，可能是学期不对',
      name: 'lecture_add_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `讲座已经结束了喵～`
  String get lecture_add_expired_toast {
    return Intl.message(
      '讲座已经结束了喵～',
      name: 'lecture_add_expired_toast',
      desc: '',
      args: [],
    );
  }

  /// `这个讲座已经添加过啦～`
  String get lecture_added_toast {
    return Intl.message(
      '这个讲座已经添加过啦～',
      name: 'lecture_added_toast',
      desc: '',
      args: [],
    );
  }

  /// `讲座列表由南哪助手团队提供与维护`
  String get lecture_bottom {
    return Intl.message(
      '讲座列表由南哪助手团队提供与维护',
      name: 'lecture_bottom',
      desc: '',
      args: [],
    );
  }

  /// `导出当前课表`
  String get export_classtable_title {
    return Intl.message(
      '导出当前课表',
      name: 'export_classtable_title',
      desc: '',
      args: [],
    );
  }

  /// `导出当前课表为二维码/链接\n使用公共服务 file.io`
  String get export_classtable_subtitle {
    return Intl.message(
      '导出当前课表为二维码/链接\n使用公共服务 file.io',
      name: 'export_classtable_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `二维码导入课表`
  String get import_from_qrcode_title {
    return Intl.message(
      '二维码导入课表',
      name: 'import_from_qrcode_title',
      desc: '',
      args: [],
    );
  }

  /// `从他人分享的二维码导入课表`
  String get import_from_qrcode_subtitle {
    return Intl.message(
      '从他人分享的二维码导入课表',
      name: 'import_from_qrcode_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `扫描二维码导入此课表\n南哪课表-设置-导入/导出课表-二维码导入课表\n有效期一周，扫描一次后过期`
  String get import_from_qrcode_content {
    return Intl.message(
      '扫描二维码导入此课表\n南哪课表-设置-导入/导出课表-二维码导入课表\n有效期一周，扫描一次后过期',
      name: 'import_from_qrcode_content',
      desc: '',
      args: [],
    );
  }

  /// `网络错误，请重试`
  String get network_error_toast {
    return Intl.message(
      '网络错误，请重试',
      name: 'network_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `导入中 请稍后`
  String get importing_toast {
    return Intl.message(
      '导入中 请稍后',
      name: 'importing_toast',
      desc: '',
      args: [],
    );
  }

  /// `二维码无效，可能为链接过期`
  String get qrcode_url_error_toast {
    return Intl.message(
      '二维码无效，可能为链接过期',
      name: 'qrcode_url_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `读取课表名称失败，可能为链接错误`
  String get qrcode_name_error_toast {
    return Intl.message(
      '读取课表名称失败，可能为链接错误',
      name: 'qrcode_name_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `读取课程表，可能是 bug`
  String get qrcode_read_error_toast {
    return Intl.message(
      '读取课程表，可能是 bug',
      name: 'qrcode_read_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `导入课表失败，可能是 bug`
  String get online_parse_error_toast {
    return Intl.message(
      '导入课表失败，可能是 bug',
      name: 'online_parse_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `导入完成`
  String get import_success_toast {
    return Intl.message(
      '导入完成',
      name: 'import_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `导出课程表`
  String get export_title {
    return Intl.message(
      '导出课程表',
      name: 'export_title',
      desc: '',
      args: [],
    );
  }

  /// `二维码导入`
  String get import_qr_title {
    return Intl.message(
      '二维码导入',
      name: 'import_qr_title',
      desc: '',
      args: [],
    );
  }

  /// `重置颜色池成功 >v<`
  String get shuffle_color_pool_success_toast {
    return Intl.message(
      '重置颜色池成功 >v<',
      name: 'shuffle_color_pool_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `当前周未修改 >v<`
  String get nowweek_not_edited_success_toast {
    return Intl.message(
      '当前周未修改 >v<',
      name: 'nowweek_not_edited_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `修改当前周成功 >v<`
  String get nowweek_edited_success_toast {
    return Intl.message(
      '修改当前周成功 >v<',
      name: 'nowweek_edited_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `打开失败，可能是未安装 TIM/QQ`
  String get QQ_open_fail_toast {
    return Intl.message(
      '打开失败，可能是未安装 TIM/QQ',
      name: 'QQ_open_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `已复制群号到剪贴板`
  String get QQ_copy_success_toast {
    return Intl.message(
      '已复制群号到剪贴板',
      name: 'QQ_copy_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `打开失败`
  String get pay_open_fail_toast {
    return Intl.message(
      '打开失败',
      name: 'pay_open_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `确认`
  String get ok {
    return Intl.message(
      '确认',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `取消`
  String get cancel {
    return Intl.message(
      '取消',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `添加课程`
  String get add_manually_title {
    return Intl.message(
      '添加课程',
      name: 'add_manually_title',
      desc: '',
      args: [],
    );
  }

  /// `课程名称`
  String get class_name {
    return Intl.message(
      '课程名称',
      name: 'class_name',
      desc: '',
      args: [],
    );
  }

  /// `请输入课程名称`
  String get class_name_empty {
    return Intl.message(
      '请输入课程名称',
      name: 'class_name_empty',
      desc: '',
      args: [],
    );
  }

  /// `上课老师`
  String get class_teacher {
    return Intl.message(
      '上课老师',
      name: 'class_teacher',
      desc: '',
      args: [],
    );
  }

  /// `上课地点`
  String get class_room {
    return Intl.message(
      '上课地点',
      name: 'class_room',
      desc: '',
      args: [],
    );
  }

  /// `选择上课时间`
  String get choose_class_time_dialog_title {
    return Intl.message(
      '选择上课时间',
      name: 'choose_class_time_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `课程节数不合法`
  String get class_num_invalid_dialog_title {
    return Intl.message(
      '课程节数不合法',
      name: 'class_num_invalid_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `课程结束节数应大于起始节数`
  String get class_num_invalid_dialog_content {
    return Intl.message(
      '课程结束节数应大于起始节数',
      name: 'class_num_invalid_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `课程周数不合法`
  String get week_num_invalid_dialog_title {
    return Intl.message(
      '课程周数不合法',
      name: 'week_num_invalid_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `课程结束周数应大于起始周数`
  String get week_num_invalid_dialog_content {
    return Intl.message(
      '课程结束周数应大于起始周数',
      name: 'week_num_invalid_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `添加课程`
  String get add_class {
    return Intl.message(
      '添加课程',
      name: 'add_class',
      desc: '',
      args: [],
    );
  }

  /// `添加成功！>v<`
  String get add_manually_success_toast {
    return Intl.message(
      '添加成功！>v<',
      name: 'add_manually_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `导入课程表`
  String get import_settings_title {
    return Intl.message(
      '导入课程表',
      name: 'import_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `适配更多学校`
  String get import_more_schools {
    return Intl.message(
      '适配更多学校',
      name: 'import_more_schools',
      desc: '',
      args: [],
    );
  }

  /// `内置导入：应用内自带的导入方式`
  String get import_inline {
    return Intl.message(
      '内置导入：应用内自带的导入方式',
      name: 'import_inline',
      desc: '',
      args: [],
    );
  }

  /// `在线导入：从服务器获取的最新配置`
  String get import_online {
    return Intl.message(
      '在线导入：从服务器获取的最新配置',
      name: 'import_online',
      desc: '',
      args: [],
    );
  }

  /// `导入课程表`
  String get import_title {
    return Intl.message(
      '导入课程表',
      name: 'import_title',
      desc: '',
      args: [],
    );
  }

  /// `注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常`
  String get import_banner {
    return Intl.message(
      '注意：如加载失败，请连接南京大学VPN\n试试浏览器访问教务网，没准系统又抽风了\n听起来有点离谱，不过在南京大学，倒也正常',
      name: 'import_banner',
      desc: '',
      args: [],
    );
  }

  /// `下载南京大学VPN`
  String get import_banner_action {
    return Intl.message(
      '下载南京大学VPN',
      name: 'import_banner_action',
      desc: '',
      args: [],
    );
  }

  /// `用户名`
  String get username {
    return Intl.message(
      '用户名',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `密码`
  String get password {
    return Intl.message(
      '密码',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `验证码`
  String get captcha {
    return Intl.message(
      '验证码',
      name: 'captcha',
      desc: '',
      args: [],
    );
  }

  /// `点击刷新`
  String get tap_to_refresh {
    return Intl.message(
      '点击刷新',
      name: 'tap_to_refresh',
      desc: '',
      args: [],
    );
  }

  /// `记住密码`
  String get remember_password {
    return Intl.message(
      '记住密码',
      name: 'remember_password',
      desc: '',
      args: [],
    );
  }

  /// `导入`
  String get import {
    return Intl.message(
      '导入',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `密码错误 = =||`
  String get password_error_toast {
    return Intl.message(
      '密码错误 = =||',
      name: 'password_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `验证码错误 > <`
  String get captcha_error_toast {
    return Intl.message(
      '验证码错误 > <',
      name: 'captcha_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `用户名错误 TvT`
  String get username_error_toast {
    return Intl.message(
      '用户名错误 TvT',
      name: 'username_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `数据识别与导入中~`
  String get class_parse_toast_importing {
    return Intl.message(
      '数据识别与导入中~',
      name: 'class_parse_toast_importing',
      desc: '',
      args: [],
    );
  }

  /// `课程解析失败 = =|| 可将课表反馈至翠翠`
  String get class_parse_error_toast {
    return Intl.message(
      '课程解析失败 = =|| 可将课表反馈至翠翠',
      name: 'class_parse_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `数据存储成功 >v<`
  String get class_parse_toast_success {
    return Intl.message(
      '数据存储成功 >v<',
      name: 'class_parse_toast_success',
      desc: '',
      args: [],
    );
  }

  /// `出现异常，建议提交反馈`
  String get class_parse_toast_fail {
    return Intl.message(
      '出现异常，建议提交反馈',
      name: 'class_parse_toast_fail',
      desc: '',
      args: [],
    );
  }

  /// `周数矫正`
  String get fix_week_dialog_title {
    return Intl.message(
      '周数矫正',
      name: 'fix_week_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `检测到学期周数与当前不一致，是否立即矫正？`
  String get fix_week_dialog_content {
    return Intl.message(
      '检测到学期周数与当前不一致，是否立即矫正？',
      name: 'fix_week_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `矫正周数成功！OvO`
  String get fix_week_toast_success {
    return Intl.message(
      '矫正周数成功！OvO',
      name: 'fix_week_toast_success',
      desc: '',
      args: [],
    );
  }

  /// `课表管理`
  String get class_table_manage_title {
    return Intl.message(
      '课表管理',
      name: 'class_table_manage_title',
      desc: '',
      args: [],
    );
  }

  /// `请输入课程表名称`
  String get add_class_table_dialog_title {
    return Intl.message(
      '请输入课程表名称',
      name: 'add_class_table_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `添加课程表成功`
  String get add_class_table_success_toast {
    return Intl.message(
      '添加课程表成功',
      name: 'add_class_table_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `确认删除`
  String get del_class_table_dialog_title {
    return Intl.message(
      '确认删除',
      name: 'del_class_table_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `此操作无法恢复，这将删除该课程表下的所有课程。`
  String get del_class_table_dialog_content {
    return Intl.message(
      '此操作无法恢复，这将删除该课程表下的所有课程。',
      name: 'del_class_table_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `删除课程表成功`
  String get del_class_table_success_toast {
    return Intl.message(
      '删除课程表成功',
      name: 'del_class_table_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `检查更新`
  String get check_update_button {
    return Intl.message(
      '检查更新',
      name: 'check_update_button',
      desc: '',
      args: [],
    );
  }

  /// `已经是最新版本了呦～`
  String get already_newest_version_toast {
    return Intl.message(
      '已经是最新版本了呦～',
      name: 'already_newest_version_toast',
      desc: '',
      args: [],
    );
  }

  /// `隐私政策`
  String get check_privacy_button {
    return Intl.message(
      '隐私政策',
      name: 'check_privacy_button',
      desc: '',
      args: [],
    );
  }

  /// `GitHub 开源`
  String get github_open_source {
    return Intl.message(
      'GitHub 开源',
      name: 'github_open_source',
      desc: '',
      args: [],
    );
  }

  /// `开发者 idealclover`
  String get developer {
    return Intl.message(
      '开发者 idealclover',
      name: 'developer',
      desc: '',
      args: [],
    );
  }

  /// `博客：https://idealclover.top\nEmail：idealclover@163.com`
  String get introduction {
    return Intl.message(
      '博客：https://idealclover.top\nEmail：idealclover@163.com',
      name: 'introduction',
      desc: '',
      args: [],
    );
  }

  /// `所使用到的开源库`
  String get open_source_library_title {
    return Intl.message(
      '所使用到的开源库',
      name: 'open_source_library_title',
      desc: '',
      args: [],
    );
  }

  /// `shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0`
  String get open_source_library_content {
    return Intl.message(
      'shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0',
      name: 'open_source_library_content',
      desc: '',
      args: [],
    );
  }

  /// `感谢小百合工作室\n感谢 @ns @lgt @FengChendian 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n特别感谢 1A335 三位室友的支持\n感谢各位提供反馈的 NJUers\n谨以此 APP 敬我的大学时光`
  String get easter_egg {
    return Intl.message(
      '感谢小百合工作室\n感谢 @ns @lgt @FengChendian 协助开发\n感谢 @ovoclover 制作图标\n感谢 @无忌 @子枨 提供配色方案\n特别感谢 1A335 三位室友的支持\n感谢各位提供反馈的 NJUers\n谨以此 APP 敬我的大学时光',
      name: 'easter_egg',
      desc: '',
      args: [],
    );
  }

  /// `完美导入！投喂傻翠w`
  String get love_and_donate {
    return Intl.message(
      '完美导入！投喂傻翠w',
      name: 'love_and_donate',
      desc: '',
      args: [],
    );
  }

  /// `似乎有bug，我要反馈`
  String get bug_and_report {
    return Intl.message(
      '似乎有bug，我要反馈',
      name: 'bug_and_report',
      desc: '',
      args: [],
    );
  }

  /// `感谢制作，但我没钱`
  String get love_but_no_money {
    return Intl.message(
      '感谢制作，但我没钱',
      name: 'love_but_no_money',
      desc: '',
      args: [],
    );
  }

  /// `2021.08\n又是新的学期啦\n21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh\n\n2021.2\n不知不觉小作文更新这么长了～\n\n又是新的一年，新的一学期了。\n\n过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。\n\n所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～\n\n过去的时光，我们都辛苦了，未来，一起加油。\n\n“敬自己一杯，因为值得。”\n\n2020.9\n这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。\n\n离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。\n\n大概，衷心希望学弟学妹们珍惜大学生活w\n\n2020.5\n在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！\n\n2020.2\n2020年2月全部投喂收入将捐赠以支援湖北疫情\n(2020.3补充：已捐赠)\n\n2019.9\nHi！我是项目作者傻翠～\n\n看起来你已经导入我南教务处成功啦！撒花撒花！\n\n建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～\n\n坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。\n\n写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。\n\n放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。\n\n希望南哪课表可以陪伴学弟学妹们走过每一学期ww\n\n傻翠`
  String get welcome_content {
    return Intl.message(
      '2021.08\n又是新的学期啦\n21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh\n\n2021.2\n不知不觉小作文更新这么长了～\n\n又是新的一年，新的一学期了。\n\n过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。\n\n所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～\n\n过去的时光，我们都辛苦了，未来，一起加油。\n\n“敬自己一杯，因为值得。”\n\n2020.9\n这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。\n\n离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。\n\n大概，衷心希望学弟学妹们珍惜大学生活w\n\n2020.5\n在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！\n\n2020.2\n2020年2月全部投喂收入将捐赠以支援湖北疫情\n(2020.3补充：已捐赠)\n\n2019.9\nHi！我是项目作者傻翠～\n\n看起来你已经导入我南教务处成功啦！撒花撒花！\n\n建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～\n\n坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。\n\n写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。\n\n放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。\n\n希望南哪课表可以陪伴学弟学妹们走过每一学期ww\n\n傻翠',
      name: 'welcome_content',
      desc: '',
      args: [],
    );
  }

  /// `<p><b>2021.08</b></p><p>又是新的学期啦</p><p>21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh</p><p><b>2021.2</b></p><p>不知不觉小作文更新这么长了～</p><p>又是新的一年，新的一学期了。</p><p>过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。</p><p>所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～</p><p>过去的时光，我们都辛苦了，未来，一起加油。</p><p>“敬自己一杯，因为值得。”</p><p><b>2020.9</b></p><p>这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。</p><p>离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。</p><p>大概，衷心希望学弟学妹们珍惜大学生活w</p><p><b>2020.5</b></p><p>在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！</p><p><b>2020.2</b></p><p>2020年2月全部投喂收入将捐赠以支援湖北疫情</p><p>(2020.3补充：已捐赠)</p><p><b>2019.9</b></p><p>Hi！我是项目作者傻翠～</p><p>看起来你已经导入我南教务处成功啦！撒花撒花！</p><p>建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～</p><p>坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。</p><p>写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。</p><p>放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。</p><p>希望南哪课表可以陪伴学弟学妹们走过每一学期ww</p><p>傻翠</p>`
  String get welcome_content_html {
    return Intl.message(
      '<p><b>2021.08</b></p><p>又是新的学期啦</p><p>21届的新同学都要来了，瞬间有种自己太老了的感觉hhhhhh</p><p><b>2021.2</b></p><p>不知不觉小作文更新这么长了～</p><p>又是新的一年，新的一学期了。</p><p>过去的这一年或许大家都经历了很多，疫情来了，翠翠毕业了，紫荆站关闭了。或许，哪次教务系统更新之后，南哪课表就再也用不起来了。</p><p>所以，如果南哪课表还不错，可以在它还在的时候，一起安利给周围的小伙伴吗～</p><p>过去的时光，我们都辛苦了，未来，一起加油。</p><p>“敬自己一杯，因为值得。”</p><p><b>2020.9</b></p><p>这是翠翠离开南大的第一个秋天。不过放心，南哪课表还在维护。</p><p>离开校园，其实想说的话有很多，但却又不知道从哪里说起，说些什么，却总会在被社会毒打的时候怀念起在南大的快乐时光。</p><p>大概，衷心希望学弟学妹们珍惜大学生活w</p><p><b>2020.5</b></p><p>在付出了另一个¥688后，南哪课表终于上线 APP Store 啦！感谢大家一直以来的支持！</p><p><b>2020.2</b></p><p>2020年2月全部投喂收入将捐赠以支援湖北疫情</p><p>(2020.3补充：已捐赠)</p><p><b>2019.9</b></p><p>Hi！我是项目作者傻翠～</p><p>看起来你已经导入我南教务处成功啦！撒花撒花！</p><p>建议大家还是和自己教务系统中的课表对一下～避免出现什么bug～如果有bug的话欢迎反馈给我！设置-反馈中有交流群的群号～</p><p>坦率地讲，从安卓移植到全平台是一个痛苦的过程。之前的APP多少是建立在开源项目的基础上，而这个重构项目算是自己从零开始搭起来的。其中也做了不少取舍与妥协，还有可能出现之前所没有过的bug，如果不巧遇到bug，欢迎向我反馈。</p><p>写这个项目是一个吃力不讨好的事。单是苹果的开发者账号就要688/年，更不用提为了开发iOS版而单独买的MacBook。所以如果小伙伴想让这个项目持续下去的话，欢迎投喂傻翠。</p><p>放心，这个弹框每次导入只会弹出一次，所以不会影响你的正常使用。</p><p>希望南哪课表可以陪伴学弟学妹们走过每一学期ww</p><p>傻翠</p>',
      name: 'welcome_content_html',
      desc: '',
      args: [],
    );
  }

  /// `欢迎使用南哪课表！`
  String get welcome_title {
    return Intl.message(
      '欢迎使用南哪课表！',
      name: 'welcome_title',
      desc: '',
      args: [],
    );
  }

  /// `修改当前周数请前往设置ww`
  String get go_to_settings_toast {
    return Intl.message(
      '修改当前周数请前往设置ww',
      name: 'go_to_settings_toast',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
