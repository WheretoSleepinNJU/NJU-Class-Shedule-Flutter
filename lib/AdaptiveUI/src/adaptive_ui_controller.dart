import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adaptive_controls.dart' as ui;
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as platform;

class AdaptiveUIController extends ChangeNotifier {
  AdaptiveUIController({bool useOriginalComponents = false})
    : _original = useOriginalComponents;
  static const preferenceKey = 'adaptive_ui.use_original_components';
  bool _original;
  bool _disposed = false;
  bool get useOriginalComponents => _original;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(preferenceKey) ?? false;
    if (!_disposed && saved != _original) {
      _original = saved;
      notifyListeners();
    }
  }

  Future<void> setUseOriginalComponents(bool value) async {
    if (_original == value) return;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(preferenceKey, value)) {
      throw StateError('Unable to save component preference');
    }
    if (!_disposed) {
      _original = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AdaptiveUIScope extends InheritedNotifier<AdaptiveUIController> {
  const AdaptiveUIScope({
    super.key,
    required AdaptiveUIController controller,
    this.nativeGlassSupported = false,
    @visibleForTesting this.debugMiuix = false,
    required super.child,
  }) : super(notifier: controller);
  final bool nativeGlassSupported;
  final bool debugMiuix;
  static bool usesMiuix(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdaptiveUIScope>();
    return scope != null &&
        !scope.notifier!.useOriginalComponents &&
        (scope.debugMiuix || platform.PlatformInfo.isAndroid);
  }

  static bool supportsNativeGlass(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveUIScope>()
          ?.nativeGlassSupported ??
      false;
  @override
  bool updateShouldNotify(AdaptiveUIScope oldWidget) =>
      nativeGlassSupported != oldWidget.nativeGlassSupported ||
      debugMiuix != oldWidget.debugMiuix ||
      super.updateShouldNotify(oldWidget);
  static AdaptiveUIController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdaptiveUIScope>()?.notifier;
}

/// The switch contains no platform or renderer choices in its caller's page.
class AdaptiveAppearanceSwitch extends StatelessWidget {
  const AdaptiveAppearanceSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = AdaptiveUIScope.maybeOf(context);
    return ui.AdaptiveCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: ui.AdaptiveListTile(
        title: const Text('使用原始组件'),
        subtitle: const Text('开启后使用平台默认组件，保留当前页面和数据'),
        trailing: ui.AdaptiveSwitch(
          value: controller?.useOriginalComponents ?? true,
          onChanged: controller == null
              ? null
              : (value) async {
                  try {
                    await controller.setUseOriginalComponents(value);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('组件设置未保存，请重试')),
                      );
                    }
                  }
                },
        ),
      ),
    );
  }
}
