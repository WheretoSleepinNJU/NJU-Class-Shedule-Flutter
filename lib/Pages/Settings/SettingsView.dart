import 'Widgets/MiuixSettings.dart';
import 'dart:io';
import '../../generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:share_extend/share_extend.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import '../ManageTable/ManageTableView.dart';
import '../Import/ImportView.dart';

import '../Lecture/LecturesView.dart';
import '../About/AboutView.dart';
import '../AddCourse/AddCourseView.dart';
import 'MoreSettingsView.dart';
import 'BackgroundSettingsView.dart';
import 'WidgetSettingsView.dart';
import 'LiveActivitySettingsView.dart';
import '../Share/ShareView.dart';
import '../../Components/Toast.dart';
import '../../Resources/Config.dart';
import '../../Resources/Url.dart';

import 'Widgets/WeekChanger.dart';
import 'Widgets/SettingsCard.dart';
import '../../core/widget_data/utils/widget_refresh_helper.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: S.of(context).settings_title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SettingsCard(
            children: [
              SettingsEntry(
                icon: Icons.add_rounded,
                iconColor: const Color(0xFF3478F6),
                title: Text(S.of(context).import_manually_title),
                subtitle: Text(S.of(context).import_manually_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("class_import", {
                    "type": "manual",
                    "action": "show",
                  });
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const AddView(),
                    ),
                  );
                },
              ),
              SettingsEntry(
                icon: Icons.download_rounded,
                iconColor: const Color(0xFF3478F6),
                title: Text(S.of(context).import_title),
                subtitle: Text(S.of(context).import_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent("class_import", {
                    "type": "auto",
                    "action": "show",
                  });
                  bool? status = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const ImportView(),
                    ),
                  );
                  if (status == true) {
                    Navigator.of(context).pop(status);
                  }
                },
              ),
              SettingsEntry(
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFFEF9B27),
                title: Text(S.of(context).view_lecture_title),
                subtitle: Text(S.of(context).view_lecture_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent("class_import", {
                    "type": "lecture",
                    "action": "show",
                  });
                  bool? status = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const LectureView(),
                    ),
                  );
                  if (status == true) {
                    Navigator.of(context).pop(status);
                  }
                },
              ),
              SettingsEntry(
                icon: Icons.qr_code_rounded,
                iconColor: const Color(0xFF4EAAF0),
                title: Text(S.of(context).import_or_export_title),
                subtitle: Text(S.of(context).import_or_export_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("qr_import", {"action": "show"});
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const ShareView(),
                    ),
                  );
                },
              ),
              SettingsEntry(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF37AF77),
                title: Text(S.of(context).manage_table_title),
                subtitle: Text(S.of(context).manage_table_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("schedule_manage", {"action": "show"});
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const ManageTableView(),
                    ),
                  );
                },
              ),
              const WeekChanger(),
            ],
          ),
          SettingsCard(
            children: [
              SettingsEntry(
                key: const ValueKey('background-settings'),
                icon: Icons.wallpaper_rounded,
                iconColor: const Color(0xFF8E6BE8),
                title: Text(S.of(context).background_settings_title),
                subtitle: Text(S.of(context).background_settings_subtitle),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BackgroundSettingsView(),
                  ),
                ),
              ),
              SettingsEntry(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF6C81A6),
                title: Text(S.of(context).more_settings_title),
                subtitle: Text(S.of(context).more_settings_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("more_setting", {"action": "show"});
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          const MoreSettingsView(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (WidgetRefreshHelper.isSupportedPlatform ||
              Platform.operatingSystem == 'ohos')
            SettingsCard(
              children: [
                if (WidgetRefreshHelper.isSupportedPlatform)
                  SettingsEntry(
                    icon: Icons.widgets_rounded,
                    iconColor: const Color(0xFF3478F6),
                    title: Text(
                      S.of(context).widget_and_live_activity_settings_title,
                    ),
                    subtitle: Text(
                      S.of(context).widget_and_live_activity_settings_subtitle,
                    ),
                    onTap: () {
                      UmengCommonSdk.onEvent("widget_setting", {
                        "action": "show",
                      });
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const WidgetSettingsView(),
                        ),
                      );
                    },
                  ),
                if (WidgetRefreshHelper.isSupportedPlatform)
                  SettingsEntry(
                    key: const ValueKey('live-activity-settings'),
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFF37AF77),
                    title: Text(LiveActivitySettingsView.settingsTitle),
                    subtitle: Text(
                      Platform.isIOS ? '暂未完成接入' : '课前提醒、展示模式与运行状态',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LiveActivitySettingsView(),
                      ),
                    ),
                  ),
                if (Platform.operatingSystem == 'ohos')
                  const SettingsEntry(
                    key: ValueKey('live-view-settings'),
                    icon: Icons.notifications_active_rounded,
                    iconColor: Color(0xFF37AF77),
                    title: Text('实况窗'),
                    subtitle: Text('暂未接入'),
                    enabled: false,
                  ),
              ],
            ),
          SettingsCard(
            children: [
              SettingsEntry(
                icon: Icons.ios_share_rounded,
                iconColor: const Color(0xFF3478F6),
                title: Text(S.of(context).share_title),
                subtitle: Text(S.of(context).share_subtitle),
                onTap: () {
                  UmengCommonSdk.onEvent("app_share", {"action": "show"});
                  ShareExtend.share(S.of(context).share_content, "text");
                },
              ),
              SettingsEntry(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF37AF77),
                title: Text(S.of(context).report_title),
                subtitle: Text(S.of(context).report_subtitle),
                onTap: () async {
                  UmengCommonSdk.onEvent("group_add", {"action": "show"});
                  bool status = false;
                  if (Platform.isIOS) {
                    status = await _launchURL(Url.QQ_GROUP_APPLE_URL);
                  } else if (Platform.isAndroid) {
                    status = await _launchURL(Url.QQ_GROUP_ANDROID_URL);
                  } else if (Platform.operatingSystem == 'ohos') {
                    status = await _launchURL(Url.QQ_GROUP_OHOS_URL);
                  }
                  if (!status) {
                    Toast.showToast(S.of(context).QQ_open_fail_toast, context);
                  }
                },
                onLongPress: () async {
                  UmengCommonSdk.onEvent("group_add", {"action": "copy"});
                  if (Platform.isIOS) {
                    await Clipboard.setData(
                      const ClipboardData(text: Config.IOS_GROUP),
                    );
                  } else if (Platform.isAndroid) {
                    await Clipboard.setData(
                      const ClipboardData(text: Config.ANDROID_GROUP),
                    );
                  } else if (Platform.operatingSystem == 'ohos') {
                    await Clipboard.setData(
                      const ClipboardData(text: Config.OHOS_GROUP),
                    );
                  }
                  Toast.showToast(S.of(context).QQ_copy_success_toast, context);
                },
              ),
              FutureBuilder<bool>(
                future: _shouldShowDonate(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  if (snapshot.hasData && snapshot.data == false) {
                    return const SizedBox.shrink();
                  }
                  return SettingsEntry(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF789B),
                    title: Text(S.of(context).donate_title),
                    subtitle: Text(S.of(context).donate_subtitle),
                    onTap: () async {
                      UmengCommonSdk.onEvent("donate_click", {
                        "action": "show",
                      });
                      bool status = false;
                      if (Platform.isIOS) {
                        status = await _launchURL(Url.URL_APPLE);
                      } else if (Platform.isAndroid) {
                        status = await _launchURL(Url.URL_ANDROID);
                      } else if (Platform.operatingSystem == 'ohos') {
                        status = await _launchURL(Url.URL_OHOS);
                      }
                      if (!status) {
                        Toast.showToast(
                          S.of(context).pay_open_fail_toast,
                          context,
                        );
                      }
                    },
                  );
                },
              ),
              SettingsEntry(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF8796A8),
                title: Text(S.of(context).about_title),
                subtitle: FutureBuilder<String>(
                  future: _getVersion(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                        if (!snapshot.hasData) {
                          return Container();
                        } else {
                          return Text(
                            snapshot.data! + S.of(context).flutter_lts,
                          );
                        }
                      },
                ),
                onTap: () {
                  UmengCommonSdk.onEvent("about_click", {"action": "show"});
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const AboutView(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _shouldShowDonate() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      String currentVersion = await _getVersion();
      final dio = Dio();
      final response = await dio.get('${Url.UPDATE_ROOT}/showDonate.json');
      return response.data[currentVersion] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<bool> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
