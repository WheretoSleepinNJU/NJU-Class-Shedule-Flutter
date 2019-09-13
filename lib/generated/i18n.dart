import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: camel_case_types
// ignore_for_file: prefer_single_quotes

// This file is automatically generated. DO NOT EDIT, all your changes would be lost.
class S implements WidgetsLocalizations {
  const S();

  static S current;

  static const GeneratedLocalizationsDelegate delegate =
    GeneratedLocalizationsDelegate();

  static S of(BuildContext context) => Localizations.of<S>(context, S);

  @override
  TextDirection get textDirection => TextDirection.ltr;

  String get about_title => "关于";
  String get add_class => "添加课程";
  String get add_class_table_dialog_title => "请输入课程表名称";
  String get add_manually_success_toast => "添加成功！>v<";
  String get add_manually_title => "添加课程";
  String get app_name => "南哪课表";
  String get at => "@";
  String get cancel => "取消";
  String get captcha => "验证码";
  String get captcha_error_toast => "验证码错误 > <";
  String get change_theme_title => "修改主题";
  String get change_week_subtitle => "当前周数：";
  String get change_week_title => "修改当前周";
  String get choose_class_time_dialog_title => "选择上课时间";
  String get class_name => "课程名称";
  String get class_name_empty => "请输入课程名称";
  String get class_num_invalid_dialog_content => "课程结束节数应大于起始节数";
  String get class_num_invalid_dialog_title => "课程节数不合法";
  String get class_parse_error_toast => "课程解析失败 = =|| 可将课表反馈至翠翠";
  String get class_parse_toast_fail => "出现异常，建议提交反馈";
  String get class_parse_toast_success => "数据存储成功 >v<";
  String get class_room => "上课地点";
  String get class_table_manage_title => "课表管理";
  String get class_teacher => "上课老师";
  String get delete_class_dialog_title => "删除课程";
  String get donate_subtitle => "给傻翠买支棒棒糖吧！";
  String get donate_title => "投喂";
  String get import => "导入";
  String get import_auto => "自动导入";
  String get import_from_NJU_subtitle => "登录南京大学教务系统导入课程表";
  String get import_from_NJU_title => "导入南京大学课表";
  String get import_manually => "手动导入";
  String get import_manually_subtitle => "手动添加课程表数据";
  String get import_manually_title => "手动添加";
  String get import_title => "导入课程表";
  String get manage_table_subtitle => "添加或删除课表数据";
  String get manage_table_title => "课表管理";
  String get not_this_week => "[非本周]";
  String get ok => "确认";
  String get password => "密码";
  String get password_error_toast => "密码错误 = =||";
  String get remember_password => "记住密码";
  String get report_subtitle => "加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号";
  String get report_title => "反馈";
  String get settings_title => "设置";
  String get shuffle_color_pool_subtitle => "重置课程颜色池";
  String get shuffle_color_pool_success_toast => "重置颜色池成功 >v<";
  String get shuffle_color_pool_title => "重置课程颜色";
  String get tap_to_refresh => "点击刷新";
  String get to => "-";
  String get unknown_place => "未知地点";
  String get username => "用户名";
  String get week_num_invalid_dialog_content => "课程结束周数应大于起始周数";
  String get week_num_invalid_dialog_title => "课程周数不合法";
  String class_duration(String start, String end) => "第 $start - $end 节";
  String class_single(String num) => "第 $num 节";
  String delete_class_dialog_content(String className) => "确定删除课程【 $className 】吗？";
  String week(String num) => "第 $num 周";
}

class $en extends S {
  const $en();
}

class $zh_CN extends S {
  const $zh_CN();

  @override
  TextDirection get textDirection => TextDirection.ltr;

  @override
  String get cancel => "取消";
  @override
  String get report_subtitle => "加入用户群一起愉快地玩耍吧！\n轻触直接加群，长按复制群号";
  @override
  String get settings_title => "设置";
  @override
  String get delete_class_dialog_title => "删除课程";
  @override
  String get import_auto => "自动导入";
  @override
  String get donate_title => "投喂";
  @override
  String get password => "密码";
  @override
  String get change_week_subtitle => "当前周数：";
  @override
  String get captcha => "验证码";
  @override
  String get import_manually => "手动导入";
  @override
  String get class_num_invalid_dialog_content => "课程结束节数应大于起始节数";
  @override
  String get manage_table_title => "课表管理";
  @override
  String get class_parse_error_toast => "课程解析失败 = =|| 可将课表反馈至翠翠";
  @override
  String get shuffle_color_pool_subtitle => "重置课程颜色池";
  @override
  String get add_class_table_dialog_title => "请输入课程表名称";
  @override
  String get at => "@";
  @override
  String get captcha_error_toast => "验证码错误 > <";
  @override
  String get import_from_NJU_title => "导入南京大学课表";
  @override
  String get class_parse_toast_success => "数据存储成功 >v<";
  @override
  String get choose_class_time_dialog_title => "选择上课时间";
  @override
  String get tap_to_refresh => "点击刷新";
  @override
  String get donate_subtitle => "给傻翠买支棒棒糖吧！";
  @override
  String get import => "导入";
  @override
  String get password_error_toast => "密码错误 = =||";
  @override
  String get not_this_week => "[非本周]";
  @override
  String get change_week_title => "修改当前周";
  @override
  String get unknown_place => "未知地点";
  @override
  String get remember_password => "记住密码";
  @override
  String get class_table_manage_title => "课表管理";
  @override
  String get week_num_invalid_dialog_content => "课程结束周数应大于起始周数";
  @override
  String get add_class => "添加课程";
  @override
  String get shuffle_color_pool_title => "重置课程颜色";
  @override
  String get week_num_invalid_dialog_title => "课程周数不合法";
  @override
  String get class_teacher => "上课老师";
  @override
  String get class_name_empty => "请输入课程名称";
  @override
  String get ok => "确认";
  @override
  String get class_name => "课程名称";
  @override
  String get import_from_NJU_subtitle => "登录南京大学教务系统导入课程表";
  @override
  String get report_title => "反馈";
  @override
  String get shuffle_color_pool_success_toast => "重置颜色池成功 >v<";
  @override
  String get add_manually_title => "添加课程";
  @override
  String get change_theme_title => "修改主题";
  @override
  String get add_manually_success_toast => "添加成功！>v<";
  @override
  String get import_title => "导入课程表";
  @override
  String get class_parse_toast_fail => "出现异常，建议提交反馈";
  @override
  String get class_num_invalid_dialog_title => "课程节数不合法";
  @override
  String get app_name => "南哪课表";
  @override
  String get import_manually_subtitle => "手动添加课程表数据";
  @override
  String get manage_table_subtitle => "添加或删除课表数据";
  @override
  String get class_room => "上课地点";
  @override
  String get about_title => "关于";
  @override
  String get to => "-";
  @override
  String get import_manually_title => "手动添加";
  @override
  String get username => "用户名";
  @override
  String delete_class_dialog_content(String className) => "确定删除课程【 $className 】吗？";
  @override
  String week(String num) => "第 $num 周";
  @override
  String class_duration(String start, String end) => "第 $start - $end 节";
  @override
  String class_single(String num) => "第 $num 节";
}

class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale("en", ""),
      Locale("zh", "CN"),
    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback, bool withCountry = true}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported, withCountry);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback, bool withCountry = true}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported, withCountry);
    };
  }

  @override
  Future<S> load(Locale locale) {
    final String lang = getLang(locale);
    if (lang != null) {
      switch (lang) {
        case "en":
          S.current = const $en();
          return SynchronousFuture<S>(S.current);
        case "zh_CN":
          S.current = const $zh_CN();
          return SynchronousFuture<S>(S.current);
        default:
          // NO-OP.
      }
    }
    S.current = const S();
    return SynchronousFuture<S>(S.current);
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale, true);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;

  ///
  /// Internal method to resolve a locale from a list of locales.
  ///
  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported, bool withCountry) {
    if (locale == null || !_isSupported(locale, withCountry)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  ///
  /// Returns true if the specified locale is supported, false otherwise.
  ///
  bool _isSupported(Locale locale, bool withCountry) {
    if (locale != null) {
      for (Locale supportedLocale in supportedLocales) {
        // Language must always match both locales.
        if (supportedLocale.languageCode != locale.languageCode) {
          continue;
        }

        // If country code matches, return this locale.
        if (supportedLocale.countryCode == locale.countryCode) {
          return true;
        }

        // If no country requirement is requested, check if this locale has no country.
        if (true != withCountry && (supportedLocale.countryCode == null || supportedLocale.countryCode.isEmpty)) {
          return true;
        }
      }
    }
    return false;
  }
}

String getLang(Locale l) => l == null
  ? null
  : l.countryCode != null && l.countryCode.isEmpty
    ? l.languageCode
    : l.toString();