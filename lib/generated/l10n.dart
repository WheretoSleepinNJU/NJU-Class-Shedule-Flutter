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

  /// `NJU Schedule`
  String get app_name {
    return Intl.message(
      'NJU Schedule',
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

  /// `Month`
  String get month {
    return Intl.message(
      'Month',
      name: 'month',
      desc: '',
      args: [],
    );
  }

  /// `Week {num}`
  String week(Object num) {
    return Intl.message(
      'Week $num',
      name: 'week',
      desc: '',
      args: [num],
    );
  }

  /// `Week {start}-{end}`
  String week_duration(Object start, Object end) {
    return Intl.message(
      'Week $start-$end',
      name: 'week_duration',
      desc: '',
      args: [start, end],
    );
  }

  /// `Period {num}`
  String class_single(Object num) {
    return Intl.message(
      'Period $num',
      name: 'class_single',
      desc: '',
      args: [num],
    );
  }

  /// `Period {start}-{end}`
  String class_duration(Object start, Object end) {
    return Intl.message(
      'Period $start-$end',
      name: 'class_duration',
      desc: '',
      args: [start, end],
    );
  }

  /// `[Not this week]`
  String get not_this_week {
    return Intl.message(
      '[Not this week]',
      name: 'not_this_week',
      desc: '',
      args: [],
    );
  }

  /// `Odd weeks`
  String get single_week {
    return Intl.message(
      'Odd weeks',
      name: 'single_week',
      desc: '',
      args: [],
    );
  }

  /// `Even weeks`
  String get double_week {
    return Intl.message(
      'Even weeks',
      name: 'double_week',
      desc: '',
      args: [],
    );
  }

  /// `[Semester not started]`
  String get not_open {
    return Intl.message(
      '[Semester not started]',
      name: 'not_open',
      desc: '',
      args: [],
    );
  }

  /// `Free Time`
  String get free_time {
    return Intl.message(
      'Free Time',
      name: 'free_time',
      desc: '',
      args: [],
    );
  }

  /// `Unknown location`
  String get unknown_place {
    return Intl.message(
      'Unknown location',
      name: 'unknown_place',
      desc: '',
      args: [],
    );
  }

  /// `No notes`
  String get unknown_info {
    return Intl.message(
      'No notes',
      name: 'unknown_info',
      desc: '',
      args: [],
    );
  }

  /// `Auto Import`
  String get import_auto {
    return Intl.message(
      'Auto Import',
      name: 'import_auto',
      desc: '',
      args: [],
    );
  }

  /// `Manual Import`
  String get import_manually {
    return Intl.message(
      'Manual Import',
      name: 'import_manually',
      desc: '',
      args: [],
    );
  }

  /// `Lecture Import`
  String get import_from_lecture {
    return Intl.message(
      'Lecture Import',
      name: 'import_from_lecture',
      desc: '',
      args: [],
    );
  }

  /// `{num} more "Free Time" classes >>`
  String free_class_banner(Object num) {
    return Intl.message(
      '$num more "Free Time" classes >>',
      name: 'free_class_banner',
      desc: '',
      args: [num],
    );
  }

  /// `View`
  String get free_class_button {
    return Intl.message(
      'View',
      name: 'free_class_button',
      desc: '',
      args: [],
    );
  }

  /// `Hide`
  String get hide_free_class_button {
    return Intl.message(
      'Hide',
      name: 'hide_free_class_button',
      desc: '',
      args: [],
    );
  }

  /// `Hide Free Time Classes`
  String get hide_free_class_dialog_title {
    return Intl.message(
      'Hide Free Time Classes',
      name: 'hide_free_class_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Hide free time classes?\nYou can re-enable them in Settings > More Settings > Show Free Time Classes.`
  String get hide_free_class_dialog_content {
    return Intl.message(
      'Hide free time classes?\nYou can re-enable them in Settings > More Settings > Show Free Time Classes.',
      name: 'hide_free_class_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Delete Class`
  String get delete_class_dialog_title {
    return Intl.message(
      'Delete Class',
      name: 'delete_class_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Delete class [{className}]?`
  String delete_class_dialog_content(Object className) {
    return Intl.message(
      'Delete class [$className]?',
      name: 'delete_class_dialog_content',
      desc: '',
      args: [className],
    );
  }

  /// `Settings`
  String get settings_title {
    return Intl.message(
      'Settings',
      name: 'settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Manual Add`
  String get import_manually_title {
    return Intl.message(
      'Manual Add',
      name: 'import_manually_title',
      desc: '',
      args: [],
    );
  }

  /// `Manually add schedule data`
  String get import_manually_subtitle {
    return Intl.message(
      'Manually add schedule data',
      name: 'import_manually_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Import Schedule`
  String get import_from_JW_title {
    return Intl.message(
      'Import Schedule',
      name: 'import_from_JW_title',
      desc: '',
      args: [],
    );
  }

  /// `Automatically import schedule data`
  String get import_subtitle {
    return Intl.message(
      'Automatically import schedule data',
      name: 'import_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `NJU Undergraduate Academic System`
  String get import_from_NJU_title {
    return Intl.message(
      'NJU Undergraduate Academic System',
      name: 'import_from_NJU_title',
      desc: '',
      args: [],
    );
  }

  /// `For students before grade 2020`
  String get import_from_NJU_subtitle {
    return Intl.message(
      'For students before grade 2020',
      name: 'import_from_NJU_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `NJU Unified Authentication`
  String get import_from_NJU_cer_title {
    return Intl.message(
      'NJU Unified Authentication',
      name: 'import_from_NJU_cer_title',
      desc: '',
      args: [],
    );
  }

  /// `Recommended import method`
  String get import_from_NJU_cer_subtitle {
    return Intl.message(
      'Recommended import method',
      name: 'import_from_NJU_cer_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `NJU Course Selection System`
  String get import_from_NJU_xk_title {
    return Intl.message(
      'NJU Course Selection System',
      name: 'import_from_NJU_xk_title',
      desc: '',
      args: [],
    );
  }

  /// `New system, fallback option`
  String get import_from_NJU_xk_subtitle {
    return Intl.message(
      'New system, fallback option',
      name: 'import_from_NJU_xk_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Campus Schedule`
  String get all_course_title {
    return Intl.message(
      'Campus Schedule',
      name: 'all_course_title',
      desc: '',
      args: [],
    );
  }

  /// `Browse public courses and add classes`
  String get all_course_subtitle {
    return Intl.message(
      'Browse public courses and add classes',
      name: 'all_course_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Lectures`
  String get view_lecture_title {
    return Intl.message(
      'Lectures',
      name: 'view_lecture_title',
      desc: '',
      args: [],
    );
  }

  /// `Browse latest lectures and import with one tap`
  String get view_lecture_subtitle {
    return Intl.message(
      'Browse latest lectures and import with one tap',
      name: 'view_lecture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `QR Import/Export`
  String get import_or_export_title {
    return Intl.message(
      'QR Import/Export',
      name: 'import_or_export_title',
      desc: '',
      args: [],
    );
  }

  /// `Offline share: import/export via QR or share string (separate from online import)`
  String get import_or_export_subtitle {
    return Intl.message(
      'Offline share: import/export via QR or share string (separate from online import)',
      name: 'import_or_export_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Schedule Management`
  String get manage_table_title {
    return Intl.message(
      'Schedule Management',
      name: 'manage_table_title',
      desc: '',
      args: [],
    );
  }

  /// `Add or delete schedules`
  String get manage_table_subtitle {
    return Intl.message(
      'Add or delete schedules',
      name: 'manage_table_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get change_theme_title {
    return Intl.message(
      'Theme',
      name: 'change_theme_title',
      desc: '',
      args: [],
    );
  }

  /// `Light/Dark Mode`
  String get change_theme_mode_title {
    return Intl.message(
      'Light/Dark Mode',
      name: 'change_theme_mode_title',
      desc: '',
      args: [],
    );
  }

  /// `Follow system appearance`
  String get change_theme_mode_subtitle {
    return Intl.message(
      'Follow system appearance',
      name: 'change_theme_mode_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Reset Course Colors`
  String get shuffle_color_pool_title {
    return Intl.message(
      'Reset Course Colors',
      name: 'shuffle_color_pool_title',
      desc: '',
      args: [],
    );
  }

  /// `Reset color pool`
  String get shuffle_color_pool_subtitle {
    return Intl.message(
      'Reset color pool',
      name: 'shuffle_color_pool_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Change Current Week`
  String get change_week_title {
    return Intl.message(
      'Change Current Week',
      name: 'change_week_title',
      desc: '',
      args: [],
    );
  }

  /// `Current week:`
  String get change_week_subtitle {
    return Intl.message(
      'Current week:',
      name: 'change_week_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get report_title {
    return Intl.message(
      'Feedback',
      name: 'report_title',
      desc: '',
      args: [],
    );
  }

  /// `Join user group for support.\nTap to join, long press to copy group number`
  String get report_subtitle {
    return Intl.message(
      'Join user group for support.\nTap to join, long press to copy group number',
      name: 'report_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Donate`
  String get donate_title {
    return Intl.message(
      'Donate',
      name: 'donate_title',
      desc: '',
      args: [],
    );
  }

  /// `Buy the developer a lollipop`
  String get donate_subtitle {
    return Intl.message(
      'Buy the developer a lollipop',
      name: 'donate_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Share App`
  String get share_title {
    return Intl.message(
      'Share App',
      name: 'share_title',
      desc: '',
      args: [],
    );
  }

  /// `Share NJU Schedule with friends`
  String get share_subtitle {
    return Intl.message(
      'Share NJU Schedule with friends',
      name: 'share_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `NJU Schedule for NJU students. Import schedule, find courses and lectures: https://nju.app`
  String get share_content {
    return Intl.message(
      'NJU Schedule for NJU students. Import schedule, find courses and lectures: https://nju.app',
      name: 'share_content',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about_title {
    return Intl.message(
      'About',
      name: 'about_title',
      desc: '',
      args: [],
    );
  }

  /// `More Settings`
  String get more_settings_title {
    return Intl.message(
      'More Settings',
      name: 'more_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Appearance, advanced and experimental settings`
  String get more_settings_subtitle {
    return Intl.message(
      'Appearance, advanced and experimental settings',
      name: 'more_settings_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `White Title Mode`
  String get white_title_mode_title {
    return Intl.message(
      'White Title Mode',
      name: 'white_title_mode_title',
      desc: '',
      args: [],
    );
  }

  /// `Useful for dark backgrounds`
  String get white_title_mode_subtitle {
    return Intl.message(
      'Useful for dark backgrounds',
      name: 'white_title_mode_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Hide Add Button`
  String get hide_add_button_title {
    return Intl.message(
      'Hide Add Button',
      name: 'hide_add_button_title',
      desc: '',
      args: [],
    );
  }

  /// `Hide bottom-right add button`
  String get hide_add_button_subtitle {
    return Intl.message(
      'Hide bottom-right add button',
      name: 'hide_add_button_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show Month`
  String get show_month_title {
    return Intl.message(
      'Show Month',
      name: 'show_month_title',
      desc: '',
      args: [],
    );
  }

  /// `Show current month in top-left corner`
  String get show_month_subtitle {
    return Intl.message(
      'Show current month in top-left corner',
      name: 'show_month_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show Date`
  String get show_date_title {
    return Intl.message(
      'Show Date',
      name: 'show_date_title',
      desc: '',
      args: [],
    );
  }

  /// `Show dates for current week`
  String get show_date_subtitle {
    return Intl.message(
      'Show dates for current week',
      name: 'show_date_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show Weekend`
  String get if_show_weekend_title {
    return Intl.message(
      'Show Weekend',
      name: 'if_show_weekend_title',
      desc: '',
      args: [],
    );
  }

  /// `Whether to show Saturday and Sunday`
  String get if_show_weekend_subtitle {
    return Intl.message(
      'Whether to show Saturday and Sunday',
      name: 'if_show_weekend_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show Class Time`
  String get if_show_classtime_title {
    return Intl.message(
      'Show Class Time',
      name: 'if_show_classtime_title',
      desc: '',
      args: [],
    );
  }

  /// `Whether to show class time`
  String get if_show_classtime_subtitle {
    return Intl.message(
      'Whether to show class time',
      name: 'if_show_classtime_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show Free Time Classes`
  String get if_show_freeclass_title {
    return Intl.message(
      'Show Free Time Classes',
      name: 'if_show_freeclass_title',
      desc: '',
      args: [],
    );
  }

  /// `Whether to show free time classes`
  String get if_show_freeclass_subtitle {
    return Intl.message(
      'Whether to show free time classes',
      name: 'if_show_freeclass_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Force Zoom`
  String get force_zoom_title {
    return Intl.message(
      'Force Zoom',
      name: 'force_zoom_title',
      desc: '',
      args: [],
    );
  }

  /// `Force schedule into one page`
  String get force_zoom_subtitle {
    return Intl.message(
      'Force schedule into one page',
      name: 'force_zoom_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Softer Accent (Light)`
  String get use_material3_scheme_light_title {
    return Intl.message(
      'Softer Accent (Light)',
      name: 'use_material3_scheme_light_title',
      desc: '',
      args: [],
    );
  }

  /// `Use Material 3 palette in light mode`
  String get use_material3_scheme_light_subtitle {
    return Intl.message(
      'Use Material 3 palette in light mode',
      name: 'use_material3_scheme_light_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Softer Accent (Dark)`
  String get use_material3_scheme_dark_title {
    return Intl.message(
      'Softer Accent (Dark)',
      name: 'use_material3_scheme_dark_title',
      desc: '',
      args: [],
    );
  }

  /// `Use Material 3 palette in dark mode`
  String get use_material3_scheme_dark_subtitle {
    return Intl.message(
      'Use Material 3 palette in dark mode',
      name: 'use_material3_scheme_dark_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Upload Background`
  String get add_backgound_picture_title {
    return Intl.message(
      'Upload Background',
      name: 'add_backgound_picture_title',
      desc: '',
      args: [],
    );
  }

  /// `Upload background image`
  String get add_backgound_picture_subtitle {
    return Intl.message(
      'Upload background image',
      name: 'add_backgound_picture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Clear Background`
  String get delete_backgound_picture_title {
    return Intl.message(
      'Clear Background',
      name: 'delete_backgound_picture_title',
      desc: '',
      args: [],
    );
  }

  /// `Restore default white background`
  String get delete_backgound_picture_subtitle {
    return Intl.message(
      'Restore default white background',
      name: 'delete_backgound_picture_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Background reset`
  String get delete_backgound_picture_success_toast {
    return Intl.message(
      'Background reset',
      name: 'delete_backgound_picture_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Background updated`
  String get add_backgound_picture_success_toast {
    return Intl.message(
      'Background updated',
      name: 'add_backgound_picture_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Export to System Calendar`
  String get export_to_system_calendar_title {
    return Intl.message(
      'Export to System Calendar',
      name: 'export_to_system_calendar_title',
      desc: '',
      args: [],
    );
  }

  /// `Make sure current week is correct; adjust in system calendar if needed`
  String get export_to_system_calendar_subtitle {
    return Intl.message(
      'Make sure current week is correct; adjust in system calendar if needed',
      name: 'export_to_system_calendar_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Export succeeded`
  String get export_to_system_calendar_success_toast {
    return Intl.message(
      'Export succeeded',
      name: 'export_to_system_calendar_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Calendar export failed; check permission`
  String get export_to_system_calendar_fail_toast {
    return Intl.message(
      'Calendar export failed; check permission',
      name: 'export_to_system_calendar_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `Custom Class Height`
  String get class_height_title {
    return Intl.message(
      'Custom Class Height',
      name: 'class_height_title',
      desc: '',
      args: [],
    );
  }

  /// `Only works when force zoom is off`
  String get class_height_subtitle {
    return Intl.message(
      'Only works when force zoom is off',
      name: 'class_height_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Lectures`
  String get lecture_title {
    return Intl.message(
      'Lectures',
      name: 'lecture_title',
      desc: '',
      args: [],
    );
  }

  /// `No name`
  String get lecture_no_name {
    return Intl.message(
      'No name',
      name: 'lecture_no_name',
      desc: '',
      args: [],
    );
  }

  /// `No time`
  String get lecture_no_time {
    return Intl.message(
      'No time',
      name: 'lecture_no_time',
      desc: '',
      args: [],
    );
  }

  /// `No speaker`
  String get lecture_no_teacher {
    return Intl.message(
      'No speaker',
      name: 'lecture_no_teacher',
      desc: '',
      args: [],
    );
  }

  /// `No location`
  String get lecture_no_classroom {
    return Intl.message(
      'No location',
      name: 'lecture_no_classroom',
      desc: '',
      args: [],
    );
  }

  /// `No info`
  String get lecture_no_info {
    return Intl.message(
      'No info',
      name: 'lecture_no_info',
      desc: '',
      args: [],
    );
  }

  /// `Search lectures`
  String get lecture_search {
    return Intl.message(
      'Search lectures',
      name: 'lecture_search',
      desc: '',
      args: [],
    );
  }

  /// `Speaker:`
  String get lecture_teacher_title {
    return Intl.message(
      'Speaker:',
      name: 'lecture_teacher_title',
      desc: '',
      args: [],
    );
  }

  /// `Add to current schedule ({num} added)`
  String lecture_add(Object num) {
    return Intl.message(
      'Add to current schedule ($num added)',
      name: 'lecture_add',
      desc: '',
      args: [num],
    );
  }

  /// `Added ({num} added)`
  String lecture_added(Object num) {
    return Intl.message(
      'Added ($num added)',
      name: 'lecture_added',
      desc: '',
      args: [num],
    );
  }

  /// `Ended ({num} added)`
  String lecture_expired(Object num) {
    return Intl.message(
      'Ended ($num added)',
      name: 'lecture_expired',
      desc: '',
      args: [num],
    );
  }

  /// `Lecture list refreshed`
  String get lecture_refresh_success_toast {
    return Intl.message(
      'Lecture list refreshed',
      name: 'lecture_refresh_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Refresh failed, check network`
  String get lecture_refresh_fail_toast {
    return Intl.message(
      'Refresh failed, check network',
      name: 'lecture_refresh_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `Lecture time mismatch`
  String get lecture_cast_dialog_title {
    return Intl.message(
      'Lecture time mismatch',
      name: 'lecture_cast_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Lecture time does not exactly match class periods. Closest period was chosen.\n\nAdd this lecture to current schedule?`
  String get lecture_cast_dialog_content {
    return Intl.message(
      'Lecture time does not exactly match class periods. Closest period was chosen.\n\nAdd this lecture to current schedule?',
      name: 'lecture_cast_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Lecture added`
  String get lecture_add_success_toast {
    return Intl.message(
      'Lecture added',
      name: 'lecture_add_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Failed to add lecture, maybe wrong semester`
  String get lecture_add_fail_toast {
    return Intl.message(
      'Failed to add lecture, maybe wrong semester',
      name: 'lecture_add_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `Lecture has ended`
  String get lecture_add_expired_toast {
    return Intl.message(
      'Lecture has ended',
      name: 'lecture_add_expired_toast',
      desc: '',
      args: [],
    );
  }

  /// `Lecture already added`
  String get lecture_added_toast {
    return Intl.message(
      'Lecture already added',
      name: 'lecture_added_toast',
      desc: '',
      args: [],
    );
  }

  /// `Lecture list provided by NJU Assistant team`
  String get lecture_bottom {
    return Intl.message(
      'Lecture list provided by NJU Assistant team',
      name: 'lecture_bottom',
      desc: '',
      args: [],
    );
  }

  /// `Export current schedule`
  String get export_classtable_title {
    return Intl.message(
      'Export current schedule',
      name: 'export_classtable_title',
      desc: '',
      args: [],
    );
  }

  /// `Export current schedule as QR code or share string`
  String get export_classtable_subtitle {
    return Intl.message(
      'Export current schedule as QR code or share string',
      name: 'export_classtable_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Offline Schedule Import`
  String get import_from_qrcode_title {
    return Intl.message(
      'Offline Schedule Import',
      name: 'import_from_qrcode_title',
      desc: '',
      args: [],
    );
  }

  /// `Import offline from QR or share string (not the online importer)`
  String get import_from_qrcode_subtitle {
    return Intl.message(
      'Import offline from QR or share string (not the online importer)',
      name: 'import_from_qrcode_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Scan a QR code or paste a share string to import this schedule\nWhereToSleepInNJU - Settings - Import/Export Schedule`
  String get import_from_qrcode_content {
    return Intl.message(
      'Scan a QR code or paste a share string to import this schedule\nWhereToSleepInNJU - Settings - Import/Export Schedule',
      name: 'import_from_qrcode_content',
      desc: '',
      args: [],
    );
  }

  /// `Network error, please retry`
  String get network_error_toast {
    return Intl.message(
      'Network error, please retry',
      name: 'network_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Importing, please wait`
  String get importing_toast {
    return Intl.message(
      'Importing, please wait',
      name: 'importing_toast',
      desc: '',
      args: [],
    );
  }

  /// `Invalid share string or QR code`
  String get qrcode_url_error_toast {
    return Intl.message(
      'Invalid share string or QR code',
      name: 'qrcode_url_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Failed to read schedule name`
  String get qrcode_name_error_toast {
    return Intl.message(
      'Failed to read schedule name',
      name: 'qrcode_name_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Failed to read schedule data`
  String get qrcode_read_error_toast {
    return Intl.message(
      'Failed to read schedule data',
      name: 'qrcode_read_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Import failed. This may be a bug.`
  String get online_parse_error_toast {
    return Intl.message(
      'Import failed. This may be a bug.',
      name: 'online_parse_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Oops, import failed TvT`
  String get parse_error_dialog_title {
    return Intl.message(
      'Oops, import failed TvT',
      name: 'parse_error_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `It looks like import failed.\n\nError code: {code}\n\nTap the button below to copy this code and join the user group to report the issue, or try another import method.`
  String parse_error_dialog_content(Object code) {
    return Intl.message(
      'It looks like import failed.\n\nError code: $code\n\nTap the button below to copy this code and join the user group to report the issue, or try another import method.',
      name: 'parse_error_dialog_content',
      desc: '',
      args: [code],
    );
  }

  /// `Join Group to Report`
  String get parse_error_dialog_add_group {
    return Intl.message(
      'Join Group to Report',
      name: 'parse_error_dialog_add_group',
      desc: '',
      args: [],
    );
  }

  /// `Try Other Methods`
  String get parse_error_dialog_other_ways {
    return Intl.message(
      'Try Other Methods',
      name: 'parse_error_dialog_other_ways',
      desc: '',
      args: [],
    );
  }

  /// `Import completed`
  String get import_success_toast {
    return Intl.message(
      'Import completed',
      name: 'import_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Export Schedule`
  String get export_title {
    return Intl.message(
      'Export Schedule',
      name: 'export_title',
      desc: '',
      args: [],
    );
  }

  /// `QR Import`
  String get import_qr_title {
    return Intl.message(
      'QR Import',
      name: 'import_qr_title',
      desc: '',
      args: [],
    );
  }

  /// `Color pool reset successfully >v<`
  String get shuffle_color_pool_success_toast {
    return Intl.message(
      'Color pool reset successfully >v<',
      name: 'shuffle_color_pool_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Current week unchanged >v<`
  String get nowweek_not_edited_success_toast {
    return Intl.message(
      'Current week unchanged >v<',
      name: 'nowweek_not_edited_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Current week updated >v<`
  String get nowweek_edited_success_toast {
    return Intl.message(
      'Current week updated >v<',
      name: 'nowweek_edited_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Open failed. TIM/QQ may not be installed.`
  String get QQ_open_fail_toast {
    return Intl.message(
      'Open failed. TIM/QQ may not be installed.',
      name: 'QQ_open_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `Group number copied to clipboard`
  String get QQ_copy_success_toast {
    return Intl.message(
      'Group number copied to clipboard',
      name: 'QQ_copy_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open`
  String get pay_open_fail_toast {
    return Intl.message(
      'Failed to open',
      name: 'pay_open_fail_toast',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message(
      'OK',
      name: 'ok',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Import from Gallery`
  String get qr_scan_from_gallery_button {
    return Intl.message(
      'Import from Gallery',
      name: 'qr_scan_from_gallery_button',
      desc: '',
      args: [],
    );
  }

  /// `Import from Clipboard`
  String get qr_scan_from_clipboard_button {
    return Intl.message(
      'Import from Clipboard',
      name: 'qr_scan_from_clipboard_button',
      desc: '',
      args: [],
    );
  }

  /// `Received {received}/{total}`
  String qr_scan_parts_received_toast(Object received, Object total) {
    return Intl.message(
      'Received $received/$total',
      name: 'qr_scan_parts_received_toast',
      desc: '',
      args: [received, total],
    );
  }

  /// `Unsupported QR protocol version`
  String get qr_error_unsupported_protocol {
    return Intl.message(
      'Unsupported QR protocol version',
      name: 'qr_error_unsupported_protocol',
      desc: '',
      args: [],
    );
  }

  /// `QR checksum mismatch`
  String get qr_error_checksum_mismatch {
    return Intl.message(
      'QR checksum mismatch',
      name: 'qr_error_checksum_mismatch',
      desc: '',
      args: [],
    );
  }

  /// `QR data is corrupted`
  String get qr_error_payload_corrupted {
    return Intl.message(
      'QR data is corrupted',
      name: 'qr_error_payload_corrupted',
      desc: '',
      args: [],
    );
  }

  /// `Copy Full Share String`
  String get qr_share_copy_button {
    return Intl.message(
      'Copy Full Share String',
      name: 'qr_share_copy_button',
      desc: '',
      args: [],
    );
  }

  /// `Copied full share string`
  String get qr_share_copy_success_toast {
    return Intl.message(
      'Copied full share string',
      name: 'qr_share_copy_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Add Course`
  String get add_manually_title {
    return Intl.message(
      'Add Course',
      name: 'add_manually_title',
      desc: '',
      args: [],
    );
  }

  /// `Course Name`
  String get class_name {
    return Intl.message(
      'Course Name',
      name: 'class_name',
      desc: '',
      args: [],
    );
  }

  /// `Please enter course name`
  String get class_name_empty {
    return Intl.message(
      'Please enter course name',
      name: 'class_name_empty',
      desc: '',
      args: [],
    );
  }

  /// `Teacher`
  String get class_teacher {
    return Intl.message(
      'Teacher',
      name: 'class_teacher',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get class_info {
    return Intl.message(
      'Notes',
      name: 'class_info',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get class_room {
    return Intl.message(
      'Location',
      name: 'class_room',
      desc: '',
      args: [],
    );
  }

  /// `Select Class Time`
  String get choose_class_time_dialog_title {
    return Intl.message(
      'Select Class Time',
      name: 'choose_class_time_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Invalid period range`
  String get class_num_invalid_dialog_title {
    return Intl.message(
      'Invalid period range',
      name: 'class_num_invalid_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `End period must be greater than start period`
  String get class_num_invalid_dialog_content {
    return Intl.message(
      'End period must be greater than start period',
      name: 'class_num_invalid_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Invalid week range`
  String get week_num_invalid_dialog_title {
    return Intl.message(
      'Invalid week range',
      name: 'week_num_invalid_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `End week must be greater than start week`
  String get week_num_invalid_dialog_content {
    return Intl.message(
      'End week must be greater than start week',
      name: 'week_num_invalid_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Add Course`
  String get add_class {
    return Intl.message(
      'Add Course',
      name: 'add_class',
      desc: '',
      args: [],
    );
  }

  /// `Added successfully`
  String get add_manually_success_toast {
    return Intl.message(
      'Added successfully',
      name: 'add_manually_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Import Schedule`
  String get import_settings_title {
    return Intl.message(
      'Import Schedule',
      name: 'import_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Support more schools`
  String get import_more_schools {
    return Intl.message(
      'Support more schools',
      name: 'import_more_schools',
      desc: '',
      args: [],
    );
  }

  /// `Built-in import: bundled in app`
  String get import_inline {
    return Intl.message(
      'Built-in import: bundled in app',
      name: 'import_inline',
      desc: '',
      args: [],
    );
  }

  /// `Online import: latest config from server`
  String get import_online {
    return Intl.message(
      'Online import: latest config from server',
      name: 'import_online',
      desc: '',
      args: [],
    );
  }

  /// `Import Schedule`
  String get import_title {
    return Intl.message(
      'Import Schedule',
      name: 'import_title',
      desc: '',
      args: [],
    );
  }

  /// `If loading fails, connect to NJU VPN.\nTry opening the academic site in browser first.`
  String get import_banner {
    return Intl.message(
      'If loading fails, connect to NJU VPN.\nTry opening the academic site in browser first.',
      name: 'import_banner',
      desc: '',
      args: [],
    );
  }

  /// `Download NJU VPN`
  String get import_banner_action {
    return Intl.message(
      'Download NJU VPN',
      name: 'import_banner_action',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message(
      'Username',
      name: 'username',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message(
      'Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Captcha`
  String get captcha {
    return Intl.message(
      'Captcha',
      name: 'captcha',
      desc: '',
      args: [],
    );
  }

  /// `Tap to refresh`
  String get tap_to_refresh {
    return Intl.message(
      'Tap to refresh',
      name: 'tap_to_refresh',
      desc: '',
      args: [],
    );
  }

  /// `Remember password`
  String get remember_password {
    return Intl.message(
      'Remember password',
      name: 'remember_password',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `Wrong password`
  String get password_error_toast {
    return Intl.message(
      'Wrong password',
      name: 'password_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Wrong captcha`
  String get captcha_error_toast {
    return Intl.message(
      'Wrong captcha',
      name: 'captcha_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Wrong username`
  String get username_error_toast {
    return Intl.message(
      'Wrong username',
      name: 'username_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Parsing and importing data...`
  String get class_parse_toast_importing {
    return Intl.message(
      'Parsing and importing data...',
      name: 'class_parse_toast_importing',
      desc: '',
      args: [],
    );
  }

  /// `Failed to parse schedule`
  String get class_parse_error_toast {
    return Intl.message(
      'Failed to parse schedule',
      name: 'class_parse_error_toast',
      desc: '',
      args: [],
    );
  }

  /// `Data saved`
  String get class_parse_toast_success {
    return Intl.message(
      'Data saved',
      name: 'class_parse_toast_success',
      desc: '',
      args: [],
    );
  }

  /// `Unexpected error, please send feedback`
  String get class_parse_toast_fail {
    return Intl.message(
      'Unexpected error, please send feedback',
      name: 'class_parse_toast_fail',
      desc: '',
      args: [],
    );
  }

  /// `Week Correction`
  String get fix_week_dialog_title {
    return Intl.message(
      'Week Correction',
      name: 'fix_week_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Detected week mismatch. Correct now?`
  String get fix_week_dialog_content {
    return Intl.message(
      'Detected week mismatch. Correct now?',
      name: 'fix_week_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Week corrected`
  String get fix_week_toast_success {
    return Intl.message(
      'Week corrected',
      name: 'fix_week_toast_success',
      desc: '',
      args: [],
    );
  }

  /// `Schedule Management`
  String get class_table_manage_title {
    return Intl.message(
      'Schedule Management',
      name: 'class_table_manage_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter schedule name`
  String get add_class_table_dialog_title {
    return Intl.message(
      'Enter schedule name',
      name: 'add_class_table_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Schedule added`
  String get add_class_table_success_toast {
    return Intl.message(
      'Schedule added',
      name: 'add_class_table_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Delete`
  String get del_class_table_dialog_title {
    return Intl.message(
      'Confirm Delete',
      name: 'del_class_table_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `This cannot be undone. All courses in this schedule will be deleted.`
  String get del_class_table_dialog_content {
    return Intl.message(
      'This cannot be undone. All courses in this schedule will be deleted.',
      name: 'del_class_table_dialog_content',
      desc: '',
      args: [],
    );
  }

  /// `Schedule deleted`
  String get del_class_table_success_toast {
    return Intl.message(
      'Schedule deleted',
      name: 'del_class_table_success_toast',
      desc: '',
      args: [],
    );
  }

  /// `Check Updates`
  String get check_update_button {
    return Intl.message(
      'Check Updates',
      name: 'check_update_button',
      desc: '',
      args: [],
    );
  }

  /// `Already latest version`
  String get already_newest_version_toast {
    return Intl.message(
      'Already latest version',
      name: 'already_newest_version_toast',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get check_privacy_button {
    return Intl.message(
      'Privacy Policy',
      name: 'check_privacy_button',
      desc: '',
      args: [],
    );
  }

  /// `GitHub Open Source`
  String get github_open_source {
    return Intl.message(
      'GitHub Open Source',
      name: 'github_open_source',
      desc: '',
      args: [],
    );
  }

  /// `Developer: idealclover`
  String get developer {
    return Intl.message(
      'Developer: idealclover',
      name: 'developer',
      desc: '',
      args: [],
    );
  }

  /// `Blog: https://idealclover.top\nEmail: idealclover@163.com`
  String get introduction {
    return Intl.message(
      'Blog: https://idealclover.top\nEmail: idealclover@163.com',
      name: 'introduction',
      desc: '',
      args: [],
    );
  }

  /// `Open Source Libraries`
  String get open_source_library_title {
    return Intl.message(
      'Open Source Libraries',
      name: 'open_source_library_title',
      desc: '',
      args: [],
    );
  }

  /// `shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0\ndevice_calendar: ^4.2.0\nflutter_native_timezone: ^2.0.0`
  String get open_source_library_content {
    return Intl.message(
      'shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0\ndevice_calendar: ^4.2.0\nflutter_native_timezone: ^2.0.0',
      name: 'open_source_library_content',
      desc: '',
      args: [],
    );
  }

  /// `Acknowledgements`
  String get easter_egg_title {
    return Intl.message(
      'Acknowledgements',
      name: 'easter_egg_title',
      desc: '',
      args: [],
    );
  }

  /// `Thanks to Lily Studio and all contributors.`
  String get easter_egg {
    return Intl.message(
      'Thanks to Lily Studio and all contributors.',
      name: 'easter_egg',
      desc: '',
      args: [],
    );
  }

  /// `Import complete! Buy the developer a coffee`
  String get love_and_donate {
    return Intl.message(
      'Import complete! Buy the developer a coffee',
      name: 'love_and_donate',
      desc: '',
      args: [],
    );
  }

  /// `Found a bug, report it`
  String get bug_and_report {
    return Intl.message(
      'Found a bug, report it',
      name: 'bug_and_report',
      desc: '',
      args: [],
    );
  }

  /// `Great app, but no budget`
  String get love_but_no_money {
    return Intl.message(
      'Great app, but no budget',
      name: 'love_but_no_money',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to NJU Schedule.`
  String get welcome_content {
    return Intl.message(
      'Welcome to NJU Schedule.',
      name: 'welcome_content',
      desc: '',
      args: [],
    );
  }

  /// `<p>Welcome to NJU Schedule.</p>`
  String get welcome_content_html {
    return Intl.message(
      '<p>Welcome to NJU Schedule.</p>',
      name: 'welcome_content_html',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to NJU Schedule!`
  String get welcome_title {
    return Intl.message(
      'Welcome to NJU Schedule!',
      name: 'welcome_title',
      desc: '',
      args: [],
    );
  }

  /// `Go to Settings to change current week`
  String get go_to_settings_toast {
    return Intl.message(
      'Go to Settings to change current week',
      name: 'go_to_settings_toast',
      desc: '',
      args: [],
    );
  }

  /// `Widget & Live Activity Settings`
  String get widget_and_live_activity_settings_title {
    return Intl.message(
      'Widget & Live Activity Settings',
      name: 'widget_and_live_activity_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Customize widget and live activity display options`
  String get widget_and_live_activity_settings_subtitle {
    return Intl.message(
      'Customize widget and live activity display options',
      name: 'widget_and_live_activity_settings_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Approaching Class Alert Time`
  String get widget_approaching_minutes_title {
    return Intl.message(
      'Approaching Class Alert Time',
      name: 'widget_approaching_minutes_title',
      desc: '',
      args: [],
    );
  }

  /// `How many minutes before class to show "approaching" state`
  String get widget_approaching_minutes_subtitle {
    return Intl.message(
      'How many minutes before class to show "approaching" state',
      name: 'widget_approaching_minutes_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Tomorrow Preview Start Time`
  String get widget_tomorrow_preview_hour_title {
    return Intl.message(
      'Tomorrow Preview Start Time',
      name: 'widget_tomorrow_preview_hour_title',
      desc: '',
      args: [],
    );
  }

  /// `At what time in evening to show tomorrow's classes`
  String get widget_tomorrow_preview_hour_subtitle {
    return Intl.message(
      'At what time in evening to show tomorrow\'s classes',
      name: 'widget_tomorrow_preview_hour_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String widget_minutes_unit(Object minutes) {
    return Intl.message(
      '$minutes min',
      name: 'widget_minutes_unit',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hour}:00`
  String widget_hour_unit(Object hour) {
    return Intl.message(
      '$hour:00',
      name: 'widget_hour_unit',
      desc: '',
      args: [hour],
    );
  }

  /// `Widget settings saved`
  String get widget_settings_saved {
    return Intl.message(
      'Widget settings saved',
      name: 'widget_settings_saved',
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
