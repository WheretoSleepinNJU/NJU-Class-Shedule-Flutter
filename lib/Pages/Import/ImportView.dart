import '../../AdaptiveUI/adaptive_ui.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:azlistview/azlistview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../Resources/Url.dart';
import 'ImportFromBEView.dart';
import 'ImportTestView.dart';

class School extends ISuspensionBean {
  String name;
  String? tagIndex;
  String? namePinyin;
  Map? config;
  bool? isGrey;

  School({
    required this.name,
    this.tagIndex,
    this.namePinyin,
    this.config,
    this.isGrey,
  });

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
  const ImportView({super.key, this.loadSchools});
  final Future<List> Function()? loadSchools;
  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  late Future<List> _onlineConfig;
  int _titleTaps = 0;
  bool get _testEnabled => _titleTaps >= 5;

  @override
  void initState() {
    super.initState();
    _onlineConfig = _load();
  }

  Future<List> _load() async {
    if (widget.loadSchools != null) return widget.loadSchools!();
    final response = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    ).get('${Url.UPDATE_ROOT}/schoolList.json');
    final data = response.data;
    if (data is! Map || data['data'] is! List) {
      throw const FormatException('Invalid school list');
    }
    return data['data'] as List;
  }

  void _unlockTest() {
    if (_testEnabled) return;
    setState(() => _titleTaps++);
    if (_testEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).import_test_enabled)),
      );
    }
  }

  Future<void> _open(Widget page) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (result == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    appBar: AdaptiveTopAppBar(
      title: GestureDetector(
        key: const ValueKey('import-title'),
        behavior: HitTestBehavior.opaque,
        onTap: _unlockTest,
        child: Text(S.of(context).import_settings_title),
      ),
      actions: [
        if (_testEnabled)
          AdaptiveButton.text(
            key: const ValueKey('import-test-button'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _open(const ImportTestView()),
            child: Text(S.of(context).import_test),
          ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<List>(
        future: _onlineConfig,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _emptyState(failed: true);
          final configs = snapshot.data ?? [];
          if (configs.isEmpty) return _emptyState(failed: false);
          final schools = configs.whereType<Map>().map((data) {
            final pinyin = (data['pinyin'] ?? '').toString();
            return School(
              name: (data['title'] ?? '').toString(),
              namePinyin: pinyin,
              tagIndex: pinyin.isEmpty ? '#' : pinyin[0].toUpperCase(),
              config: data,
              isGrey: data['isGrey3.1.0'] == true,
            );
          }).toList();
          if (schools.isEmpty) return _emptyState(failed: true);
          schools.add(
            School(name: S.of(context).import_more_schools, tagIndex: '#'),
          );
          SuspensionUtil.sortListBySuspensionTag(schools);
          SuspensionUtil.setShowSuspensionStatus(schools);
          return AdaptivePageFrame(
            child: AzListView(
              padding: AdaptiveContentInsets.scrollPaddingOf(
                context,
                const EdgeInsets.symmetric(vertical: 8),
              ),
              data: schools,
              itemCount: schools.length,
              indexBarData: SuspensionUtil.getTagIndexList(schools),
              itemBuilder: (context, index) {
                final school = schools[index];
                if (school.config == null) return _moreSchools();
                return AdaptiveListTile(
                  title: Text(school.name),
                  subtitle: Text(
                    (school.config!['description'] ?? '').toString(),
                  ),
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 36, 6),
                  enabled: !(school.isGrey ?? false),
                  onTap: () {
                    UmengCommonSdk.onEvent('class_import', {
                      'type': 'be',
                      'action': 'show',
                    });
                    _open(ImportFromBEView(config: school.config!));
                  },
                );
              },
            ),
          );
        },
      ),
    ),
  );

  Widget _emptyState({required bool failed}) {
    final s = S.of(context);
    return Center(
      child: AdaptiveScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.cloud_off_outlined : Icons.school_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              failed ? s.import_load_failed : s.import_list_empty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              failed ? s.import_load_failed_hint : s.import_list_empty_hint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AdaptiveButton.icon(
              variant: AdaptiveButtonVariant.filled,
              key: const ValueKey('retry-schools'),
              onPressed: () => setState(() {
                _onlineConfig = _load();
              }),
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
            const SizedBox(height: 12),
            _moreSchools(),
          ],
        ),
      ),
    );
  }

  Widget _moreSchools() => AdaptiveButton.text(
    style: TextButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Theme.of(context).colorScheme.primary,
    ),
    onPressed: () => launchUrl(Uri.parse(Url.OPEN_SOURCE_URL)),
    child: Text(S.of(context).import_more_schools, textAlign: TextAlign.center),
  );
}
