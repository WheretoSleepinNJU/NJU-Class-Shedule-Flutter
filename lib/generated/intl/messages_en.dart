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

  static String m0(start, end) => "Period ${start}-${end}";

  static String m1(num) => "Period ${num}";

  static String m2(className) => "Delete class [${className}]?";

  static String m3(num) => "${num} more \"Free Time\" classes >>";

  static String m4(num) => "Add to current schedule (${num} added)";

  static String m5(num) => "Added (${num} added)";

  static String m6(num) => "Ended (${num} added)";

  static String m7(code) =>
      "It looks like import failed.\n\nError code: ${code}\n\nTap the button below to copy this code and join the user group to report the issue, or try another import method.";

  static String m8(received, total) => "Received ${received}/${total}";

  static String m9(num) => "Week ${num}";

  static String m10(start, end) => "Week ${start}-${end}";

  static String m11(hour) => "${hour}:00";

  static String m12(minutes) => "${minutes} min";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "QQ_copy_success_toast": MessageLookupByLibrary.simpleMessage(
            "Group number copied to clipboard"),
        "QQ_open_fail_toast": MessageLookupByLibrary.simpleMessage(
            "Open failed. TIM/QQ may not be installed."),
        "about_title": MessageLookupByLibrary.simpleMessage("About"),
        "add_backgound_picture_subtitle":
            MessageLookupByLibrary.simpleMessage("Upload background image"),
        "add_backgound_picture_success_toast":
            MessageLookupByLibrary.simpleMessage("Background updated"),
        "add_backgound_picture_title":
            MessageLookupByLibrary.simpleMessage("Upload Background"),
        "add_class": MessageLookupByLibrary.simpleMessage("Add Course"),
        "add_class_table_dialog_title":
            MessageLookupByLibrary.simpleMessage("Enter schedule name"),
        "add_class_table_success_toast":
            MessageLookupByLibrary.simpleMessage("Schedule added"),
        "add_manually_success_toast":
            MessageLookupByLibrary.simpleMessage("Added successfully"),
        "add_manually_title":
            MessageLookupByLibrary.simpleMessage("Add Course"),
        "all_course_subtitle": MessageLookupByLibrary.simpleMessage(
            "Browse public courses and add classes"),
        "all_course_title":
            MessageLookupByLibrary.simpleMessage("Campus Schedule"),
        "already_newest_version_toast":
            MessageLookupByLibrary.simpleMessage("Already latest version"),
        "app_name": MessageLookupByLibrary.simpleMessage("NJU Schedule"),
        "at": MessageLookupByLibrary.simpleMessage("@"),
        "beian_info":
            MessageLookupByLibrary.simpleMessage("京ICP备2024045824号-2A"),
        "bug_and_report":
            MessageLookupByLibrary.simpleMessage("Found a bug, report it"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "captcha": MessageLookupByLibrary.simpleMessage("Captcha"),
        "captcha_error_toast":
            MessageLookupByLibrary.simpleMessage("Wrong captcha"),
        "change_theme_mode_subtitle":
            MessageLookupByLibrary.simpleMessage("Follow system appearance"),
        "change_theme_mode_title":
            MessageLookupByLibrary.simpleMessage("Light/Dark Mode"),
        "change_theme_title": MessageLookupByLibrary.simpleMessage("Theme"),
        "change_week_subtitle":
            MessageLookupByLibrary.simpleMessage("Current week:"),
        "change_week_title":
            MessageLookupByLibrary.simpleMessage("Change Current Week"),
        "check_privacy_button":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "check_update_button":
            MessageLookupByLibrary.simpleMessage("Check Updates"),
        "choose_class_time_dialog_title":
            MessageLookupByLibrary.simpleMessage("Select Class Time"),
        "class_duration": m0,
        "class_height_subtitle": MessageLookupByLibrary.simpleMessage(
            "Only works when force zoom is off"),
        "class_height_title":
            MessageLookupByLibrary.simpleMessage("Custom Class Height"),
        "class_info": MessageLookupByLibrary.simpleMessage("Notes"),
        "class_name": MessageLookupByLibrary.simpleMessage("Course Name"),
        "class_name_empty":
            MessageLookupByLibrary.simpleMessage("Please enter course name"),
        "class_num_invalid_dialog_content":
            MessageLookupByLibrary.simpleMessage(
                "End period must be greater than start period"),
        "class_num_invalid_dialog_title":
            MessageLookupByLibrary.simpleMessage("Invalid period range"),
        "class_parse_error_toast":
            MessageLookupByLibrary.simpleMessage("Failed to parse schedule"),
        "class_parse_toast_fail": MessageLookupByLibrary.simpleMessage(
            "Unexpected error, please send feedback"),
        "class_parse_toast_importing": MessageLookupByLibrary.simpleMessage(
            "Parsing and importing data..."),
        "class_parse_toast_success":
            MessageLookupByLibrary.simpleMessage("Data saved"),
        "class_room": MessageLookupByLibrary.simpleMessage("Location"),
        "class_single": m1,
        "class_table_manage_title":
            MessageLookupByLibrary.simpleMessage("Schedule Management"),
        "class_teacher": MessageLookupByLibrary.simpleMessage("Teacher"),
        "del_class_table_dialog_content": MessageLookupByLibrary.simpleMessage(
            "This cannot be undone. All courses in this schedule will be deleted."),
        "del_class_table_dialog_title":
            MessageLookupByLibrary.simpleMessage("Confirm Delete"),
        "del_class_table_success_toast":
            MessageLookupByLibrary.simpleMessage("Schedule deleted"),
        "delete_backgound_picture_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Restore default white background"),
        "delete_backgound_picture_success_toast":
            MessageLookupByLibrary.simpleMessage("Background reset"),
        "delete_backgound_picture_title":
            MessageLookupByLibrary.simpleMessage("Clear Background"),
        "delete_class_dialog_content": m2,
        "delete_class_dialog_title":
            MessageLookupByLibrary.simpleMessage("Delete Class"),
        "developer":
            MessageLookupByLibrary.simpleMessage("Developer: idealclover"),
        "donate_subtitle": MessageLookupByLibrary.simpleMessage(
            "Buy the developer a lollipop"),
        "donate_title": MessageLookupByLibrary.simpleMessage("Donate"),
        "double_week": MessageLookupByLibrary.simpleMessage("Even weeks"),
        "easter_egg": MessageLookupByLibrary.simpleMessage(
            "Thanks to Lily Studio and all contributors."),
        "easter_egg_title":
            MessageLookupByLibrary.simpleMessage("Acknowledgements"),
        "export_classtable_subtitle": MessageLookupByLibrary.simpleMessage(
            "Export current schedule as QR code or share string"),
        "export_classtable_title":
            MessageLookupByLibrary.simpleMessage("Export current schedule"),
        "export_title": MessageLookupByLibrary.simpleMessage("Export Schedule"),
        "export_to_system_calendar_fail_toast":
            MessageLookupByLibrary.simpleMessage(
                "Calendar export failed; check permission"),
        "export_to_system_calendar_subtitle": MessageLookupByLibrary.simpleMessage(
            "Make sure current week is correct; adjust in system calendar if needed"),
        "export_to_system_calendar_success_toast":
            MessageLookupByLibrary.simpleMessage("Export succeeded"),
        "export_to_system_calendar_title":
            MessageLookupByLibrary.simpleMessage("Export to System Calendar"),
        "fix_week_dialog_content": MessageLookupByLibrary.simpleMessage(
            "Detected week mismatch. Correct now?"),
        "fix_week_dialog_title":
            MessageLookupByLibrary.simpleMessage("Week Correction"),
        "fix_week_toast_success":
            MessageLookupByLibrary.simpleMessage("Week corrected"),
        "flutter_lts": MessageLookupByLibrary.simpleMessage("(Flutter LTS)"),
        "force_zoom_subtitle": MessageLookupByLibrary.simpleMessage(
            "Force schedule into one page"),
        "force_zoom_title": MessageLookupByLibrary.simpleMessage("Force Zoom"),
        "free_class_banner": m3,
        "free_class_button": MessageLookupByLibrary.simpleMessage("View"),
        "free_time": MessageLookupByLibrary.simpleMessage("Free Time"),
        "github_open_source":
            MessageLookupByLibrary.simpleMessage("GitHub Open Source"),
        "go_to_settings_toast": MessageLookupByLibrary.simpleMessage(
            "Go to Settings to change current week"),
        "hide_add_button_subtitle": MessageLookupByLibrary.simpleMessage(
            "Hide bottom-right add button"),
        "hide_add_button_title":
            MessageLookupByLibrary.simpleMessage("Hide Add Button"),
        "hide_free_class_button": MessageLookupByLibrary.simpleMessage("Hide"),
        "hide_free_class_dialog_content": MessageLookupByLibrary.simpleMessage(
            "Hide free time classes?\nYou can re-enable them in Settings > More Settings > Show Free Time Classes."),
        "hide_free_class_dialog_title":
            MessageLookupByLibrary.simpleMessage("Hide Free Time Classes"),
        "if_show_classtime_subtitle":
            MessageLookupByLibrary.simpleMessage("Whether to show class time"),
        "if_show_classtime_title":
            MessageLookupByLibrary.simpleMessage("Show Class Time"),
        "if_show_freeclass_subtitle": MessageLookupByLibrary.simpleMessage(
            "Whether to show free time classes"),
        "if_show_freeclass_title":
            MessageLookupByLibrary.simpleMessage("Show Free Time Classes"),
        "if_show_weekend_subtitle": MessageLookupByLibrary.simpleMessage(
            "Whether to show Saturday and Sunday"),
        "if_show_weekend_title":
            MessageLookupByLibrary.simpleMessage("Show Weekend"),
        "import": MessageLookupByLibrary.simpleMessage("Import"),
        "import_auto": MessageLookupByLibrary.simpleMessage("Auto Import"),
        "import_banner": MessageLookupByLibrary.simpleMessage(
            "If loading fails, connect to NJU VPN.\nTry opening the academic site in browser first."),
        "import_banner_action":
            MessageLookupByLibrary.simpleMessage("Download NJU VPN"),
        "import_from_JW_title":
            MessageLookupByLibrary.simpleMessage("Import Schedule"),
        "import_from_NJU_cer_subtitle":
            MessageLookupByLibrary.simpleMessage("Recommended import method"),
        "import_from_NJU_cer_title":
            MessageLookupByLibrary.simpleMessage("NJU Unified Authentication"),
        "import_from_NJU_subtitle": MessageLookupByLibrary.simpleMessage(
            "For students before grade 2020"),
        "import_from_NJU_title": MessageLookupByLibrary.simpleMessage(
            "NJU Undergraduate Academic System"),
        "import_from_NJU_xk_subtitle":
            MessageLookupByLibrary.simpleMessage("New system, fallback option"),
        "import_from_NJU_xk_title":
            MessageLookupByLibrary.simpleMessage("NJU Course Selection System"),
        "import_from_lecture":
            MessageLookupByLibrary.simpleMessage("Lecture Import"),
        "import_from_qrcode_content": MessageLookupByLibrary.simpleMessage(
            "Scan a QR code or paste a share string to import this schedule\nWhereToSleepInNJU - Settings - Import/Export Schedule"),
        "import_from_qrcode_subtitle": MessageLookupByLibrary.simpleMessage(
            "Import offline from QR or share string (not the online importer)"),
        "import_from_qrcode_title":
            MessageLookupByLibrary.simpleMessage("Offline Schedule Import"),
        "import_inline": MessageLookupByLibrary.simpleMessage(
            "Built-in import: bundled in app"),
        "import_manually":
            MessageLookupByLibrary.simpleMessage("Manual Import"),
        "import_manually_subtitle":
            MessageLookupByLibrary.simpleMessage("Manually add schedule data"),
        "import_manually_title":
            MessageLookupByLibrary.simpleMessage("Manual Add"),
        "import_more_schools":
            MessageLookupByLibrary.simpleMessage("Support more schools"),
        "import_online": MessageLookupByLibrary.simpleMessage(
            "Online import: latest config from server"),
        "import_or_export_subtitle": MessageLookupByLibrary.simpleMessage(
            "Offline share: import/export via QR or share string (separate from online import)"),
        "import_or_export_title":
            MessageLookupByLibrary.simpleMessage("QR Import/Export"),
        "import_qr_title": MessageLookupByLibrary.simpleMessage("QR Import"),
        "import_settings_title":
            MessageLookupByLibrary.simpleMessage("Import Schedule"),
        "import_subtitle": MessageLookupByLibrary.simpleMessage(
            "Automatically import schedule data"),
        "import_success_toast":
            MessageLookupByLibrary.simpleMessage("Import completed"),
        "import_title": MessageLookupByLibrary.simpleMessage("Import Schedule"),
        "importing_toast":
            MessageLookupByLibrary.simpleMessage("Importing, please wait"),
        "introduction": MessageLookupByLibrary.simpleMessage(
            "Blog: https://idealclover.top\nEmail: idealclover@163.com"),
        "lecture_add": m4,
        "lecture_add_expired_toast":
            MessageLookupByLibrary.simpleMessage("Lecture has ended"),
        "lecture_add_fail_toast": MessageLookupByLibrary.simpleMessage(
            "Failed to add lecture, maybe wrong semester"),
        "lecture_add_success_toast":
            MessageLookupByLibrary.simpleMessage("Lecture added"),
        "lecture_added": m5,
        "lecture_added_toast":
            MessageLookupByLibrary.simpleMessage("Lecture already added"),
        "lecture_bottom": MessageLookupByLibrary.simpleMessage(
            "Lecture list provided by NJU Assistant team"),
        "lecture_cast_dialog_content": MessageLookupByLibrary.simpleMessage(
            "Lecture time does not exactly match class periods. Closest period was chosen.\n\nAdd this lecture to current schedule?"),
        "lecture_cast_dialog_title":
            MessageLookupByLibrary.simpleMessage("Lecture time mismatch"),
        "lecture_expired": m6,
        "lecture_no_classroom":
            MessageLookupByLibrary.simpleMessage("No location"),
        "lecture_no_info": MessageLookupByLibrary.simpleMessage("No info"),
        "lecture_no_name": MessageLookupByLibrary.simpleMessage("No name"),
        "lecture_no_teacher":
            MessageLookupByLibrary.simpleMessage("No speaker"),
        "lecture_no_time": MessageLookupByLibrary.simpleMessage("No time"),
        "lecture_refresh_fail_toast": MessageLookupByLibrary.simpleMessage(
            "Refresh failed, check network"),
        "lecture_refresh_success_toast":
            MessageLookupByLibrary.simpleMessage("Lecture list refreshed"),
        "lecture_search":
            MessageLookupByLibrary.simpleMessage("Search lectures"),
        "lecture_teacher_title":
            MessageLookupByLibrary.simpleMessage("Speaker:"),
        "lecture_title": MessageLookupByLibrary.simpleMessage("Lectures"),
        "love_and_donate": MessageLookupByLibrary.simpleMessage(
            "Import complete! Buy the developer a coffee"),
        "love_but_no_money":
            MessageLookupByLibrary.simpleMessage("Great app, but no budget"),
        "manage_table_subtitle":
            MessageLookupByLibrary.simpleMessage("Add or delete schedules"),
        "manage_table_title":
            MessageLookupByLibrary.simpleMessage("Schedule Management"),
        "month": MessageLookupByLibrary.simpleMessage("Month"),
        "more_settings_subtitle": MessageLookupByLibrary.simpleMessage(
            "Appearance, advanced and experimental settings"),
        "more_settings_title":
            MessageLookupByLibrary.simpleMessage("More Settings"),
        "network_error_toast":
            MessageLookupByLibrary.simpleMessage("Network error, please retry"),
        "not_open":
            MessageLookupByLibrary.simpleMessage("[Semester not started]"),
        "not_this_week":
            MessageLookupByLibrary.simpleMessage("[Not this week]"),
        "nowweek_edited_success_toast":
            MessageLookupByLibrary.simpleMessage("Current week updated >v<"),
        "nowweek_not_edited_success_toast":
            MessageLookupByLibrary.simpleMessage("Current week unchanged >v<"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "online_parse_error_toast": MessageLookupByLibrary.simpleMessage(
            "Import failed. This may be a bug."),
        "open_source_library_content": MessageLookupByLibrary.simpleMessage(
            "shared_preferences: ^2.0.7\nflutter_swiper_null_safety: ^1.0.2\nscoped_model: ^2.0.0-nullsafety.0\nazlistview: ^2.0.0-nullsafety.0\nwebview_flutter: ^2.0.13\nflutter_linkify: ^5.0.2\nimage_picker: ^0.8.4\npackage_info: ^2.0.2\npath_provider: ^2.0.3\nurl_launcher: ^6.0.10\nflutter_html: ^2.1.3\nfluttertoast: ^8.0.1\nsqflite: ^2.0.0+4\nhtml: ^0.15.0\ndio: ^4.0.0\ndevice_calendar: ^4.2.0\nflutter_native_timezone: ^2.0.0"),
        "open_source_library_title":
            MessageLookupByLibrary.simpleMessage("Open Source Libraries"),
        "parse_error_dialog_add_group":
            MessageLookupByLibrary.simpleMessage("Join Group to Report"),
        "parse_error_dialog_content": m7,
        "parse_error_dialog_other_ways":
            MessageLookupByLibrary.simpleMessage("Try Other Methods"),
        "parse_error_dialog_title":
            MessageLookupByLibrary.simpleMessage("Oops, import failed TvT"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "password_error_toast":
            MessageLookupByLibrary.simpleMessage("Wrong password"),
        "pay_open_fail_toast":
            MessageLookupByLibrary.simpleMessage("Failed to open"),
        "qr_error_checksum_mismatch":
            MessageLookupByLibrary.simpleMessage("QR checksum mismatch"),
        "qr_error_payload_corrupted":
            MessageLookupByLibrary.simpleMessage("QR data is corrupted"),
        "qr_error_unsupported_protocol": MessageLookupByLibrary.simpleMessage(
            "Unsupported QR protocol version"),
        "qr_scan_from_clipboard_button":
            MessageLookupByLibrary.simpleMessage("Import from Clipboard"),
        "qr_scan_from_gallery_button":
            MessageLookupByLibrary.simpleMessage("Import from Gallery"),
        "qr_scan_parts_received_toast": m8,
        "qr_share_copy_button":
            MessageLookupByLibrary.simpleMessage("Copy Full Share String"),
        "qr_share_copy_success_toast":
            MessageLookupByLibrary.simpleMessage("Copied full share string"),
        "qrcode_name_error_toast": MessageLookupByLibrary.simpleMessage(
            "Failed to read schedule name"),
        "qrcode_read_error_toast": MessageLookupByLibrary.simpleMessage(
            "Failed to read schedule data"),
        "qrcode_url_error_toast": MessageLookupByLibrary.simpleMessage(
            "Invalid share string or QR code"),
        "remember_password":
            MessageLookupByLibrary.simpleMessage("Remember password"),
        "report_subtitle": MessageLookupByLibrary.simpleMessage(
            "Join user group for support.\nTap to join, long press to copy group number"),
        "report_title": MessageLookupByLibrary.simpleMessage("Feedback"),
        "settings_title": MessageLookupByLibrary.simpleMessage("Settings"),
        "share_content": MessageLookupByLibrary.simpleMessage(
            "NJU Schedule for NJU students. Import schedule, find courses and lectures: https://nju.app"),
        "share_subtitle": MessageLookupByLibrary.simpleMessage(
            "Share NJU Schedule with friends"),
        "share_title": MessageLookupByLibrary.simpleMessage("Share App"),
        "show_date_subtitle":
            MessageLookupByLibrary.simpleMessage("Show dates for current week"),
        "show_date_title": MessageLookupByLibrary.simpleMessage("Show Date"),
        "show_month_subtitle": MessageLookupByLibrary.simpleMessage(
            "Show current month in top-left corner"),
        "show_month_title": MessageLookupByLibrary.simpleMessage("Show Month"),
        "shuffle_color_pool_subtitle":
            MessageLookupByLibrary.simpleMessage("Reset color pool"),
        "shuffle_color_pool_success_toast":
            MessageLookupByLibrary.simpleMessage(
                "Color pool reset successfully >v<"),
        "shuffle_color_pool_title":
            MessageLookupByLibrary.simpleMessage("Reset Course Colors"),
        "single_week": MessageLookupByLibrary.simpleMessage("Odd weeks"),
        "tap_to_refresh":
            MessageLookupByLibrary.simpleMessage("Tap to refresh"),
        "to": MessageLookupByLibrary.simpleMessage("-"),
        "unknown_info": MessageLookupByLibrary.simpleMessage("No notes"),
        "unknown_place":
            MessageLookupByLibrary.simpleMessage("Unknown location"),
        "use_material3_scheme_dark_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Use Material 3 palette in dark mode"),
        "use_material3_scheme_dark_title":
            MessageLookupByLibrary.simpleMessage("Softer Accent (Dark)"),
        "use_material3_scheme_light_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Use Material 3 palette in light mode"),
        "use_material3_scheme_light_title":
            MessageLookupByLibrary.simpleMessage("Softer Accent (Light)"),
        "username": MessageLookupByLibrary.simpleMessage("Username"),
        "username_error_toast":
            MessageLookupByLibrary.simpleMessage("Wrong username"),
        "view_lecture_subtitle": MessageLookupByLibrary.simpleMessage(
            "Browse latest lectures and import with one tap"),
        "view_lecture_title": MessageLookupByLibrary.simpleMessage("Lectures"),
        "week": m9,
        "week_duration": m10,
        "week_num_invalid_dialog_content": MessageLookupByLibrary.simpleMessage(
            "End week must be greater than start week"),
        "week_num_invalid_dialog_title":
            MessageLookupByLibrary.simpleMessage("Invalid week range"),
        "welcome_content":
            MessageLookupByLibrary.simpleMessage("Welcome to NJU Schedule."),
        "welcome_content_html": MessageLookupByLibrary.simpleMessage(
            "<p>Welcome to NJU Schedule.</p>"),
        "welcome_title":
            MessageLookupByLibrary.simpleMessage("Welcome to NJU Schedule!"),
        "white_title_mode_subtitle":
            MessageLookupByLibrary.simpleMessage("Useful for dark backgrounds"),
        "white_title_mode_title":
            MessageLookupByLibrary.simpleMessage("White Title Mode"),
        "widget_and_live_activity_settings_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Customize widget and live activity display options"),
        "widget_and_live_activity_settings_title":
            MessageLookupByLibrary.simpleMessage(
                "Widget & Live Activity Settings"),
        "widget_approaching_minutes_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "How many minutes before class to show \"approaching\" state"),
        "widget_approaching_minutes_title":
            MessageLookupByLibrary.simpleMessage(
                "Approaching Class Alert Time"),
        "widget_hour_unit": m11,
        "widget_minutes_unit": m12,
        "widget_settings_saved":
            MessageLookupByLibrary.simpleMessage("Widget settings saved"),
        "widget_tomorrow_preview_hour_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "At what time in evening to show tomorrow\'s classes"),
        "widget_tomorrow_preview_hour_title":
            MessageLookupByLibrary.simpleMessage("Tomorrow Preview Start Time"),
        "if_show_non_current_week_courses_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Whether to show courses that are not scheduled for the current week"),
        "if_show_non_current_week_courses_title":
            MessageLookupByLibrary.simpleMessage("Show Non-Current Week Courses")
      };
}
