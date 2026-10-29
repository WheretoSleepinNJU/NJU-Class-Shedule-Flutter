import '../../AdaptiveUI/adaptive_ui.dart';
import 'dart:io';
import '../../generated/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/UpdateUtil.dart';
import '../../Utils/PrivacyUtil.dart';
import '../../Resources/Url.dart';
import 'Widgets/RainDropWidget.dart';

class AboutView extends StatefulWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  _AboutViewState createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  Future<String>? _version, _easter;
  Future<bool>? _developer;
  Locale? _locale;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (locale != _locale) {
      _locale = locale;
      _version = _getVersion();
      _easter = _getEasterEggContent(S.of(context).easter_egg);
      _developer = Platform.operatingSystem == 'ohos'
          ? _showDeveloperOhos()
          : Future.value(false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cardColor = Theme.of(
      context,
    ).colorScheme.surfaceContainer.withValues(alpha: .92);
    return AdaptiveScaffold(
      appBar: AdaptiveTopAppBar(title: Text(s.about_title)),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, constraints) => RainDropWidget(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            ),
          ),
          SafeArea(
            child: AdaptivePageList(
              children: [
                AdaptiveSection(
                  color: cardColor,
                  padding: const EdgeInsets.all(20),
                  separated: false,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: Image.asset('res/icon.png'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.app_name,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _version,
                      builder: (_, snapshot) => Text(
                        snapshot.data ?? '',
                        textAlign: TextAlign.center,
                        style: AdaptiveTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                AdaptiveSection(
                  color: cardColor,
                  children: [
                    AdaptiveListTile(
                      leading: const Icon(Icons.system_update_alt_rounded),
                      title: Text(s.check_update_button),
                      onTap: () => UpdateUtil().checkUpdate(context, true),
                    ),
                    AdaptiveListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(s.check_privacy_button),
                      onTap: () => PrivacyUtil().checkPrivacy(context, true),
                    ),
                    AdaptiveListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(s.beian_info),
                      onTap: () => launchUrl(Uri.parse(Url.BEIAN_URL)),
                    ),
                  ],
                ),
                AdaptiveSection(
                  color: cardColor,
                  title: Text(s.github_open_source),
                  children: [
                    AdaptiveListTile(
                      title: const Text(
                        Url.OPEN_SOURCE_URL,
                        style: AdaptiveTypography.body,
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                      onTap: () => launchUrl(Uri.parse(Url.OPEN_SOURCE_URL)),
                    ),
                  ],
                ),
                if (Platform.operatingSystem == 'ohos')
                  FutureBuilder<bool>(
                    future: _developer,
                    builder: (_, snapshot) => snapshot.data == true
                        ? _generateTitle(s.developer)
                        : const SizedBox(),
                  )
                else
                  _generateTitle(s.developer),
                _generateContent(
                  s.introduction,
                  onTap: () => launchUrl(Uri.parse(Url.BLOG_URL)),
                ),
                _generateTitle(s.open_source_library_title),
                _generateContent(s.open_source_library_content),
                _generateTitle(s.easter_egg_title),
                FutureBuilder<String>(
                  future: _easter,
                  builder: (_, snapshot) =>
                      _generateContent(snapshot.data ?? s.easter_egg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version + S.of(context).flutter_lts;
  }

  Widget _generateTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _generateContent(String text, {VoidCallback? onTap}) =>
      AdaptiveSection(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainer.withValues(alpha: .92),
        children: [
          AdaptiveListTile(
            title: Text(text, style: AdaptiveTypography.body),
            onTap: onTap,
          ),
        ],
      );

  static Future<bool> _showDeveloperOhos() async {
    String url = Url.UPDATE_ROOT + '/easterEgg.json';
    try {
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        bool showDeveloper = response.data['showDeveloperOhos'] ?? false;
        return showDeveloper;
      }
    } catch (e) {
      // 忽略网络错误，使用兜底文案
    }
    return false;
  }

  static Future<String> _getEasterEggContent(fallbackContent) async {
    String url = Url.UPDATE_ROOT + '/easterEgg.json';
    try {
      Dio dio = Dio();
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        String content = response.data['content'] ?? fallbackContent;
        if (content.trim().isNotEmpty) {
          return content;
        }
      }
    } catch (e) {
      // 忽略网络错误，使用兜底文案
    }
    return fallbackContent;
  }
}
