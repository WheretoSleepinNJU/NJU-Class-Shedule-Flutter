import 'PlatformSettings.dart';
import '../../../AdaptiveUI/adaptive_ui.dart';
import 'package:flutter/material.dart';

/// A group of related settings on a single, flat rounded surface.
class SettingsCard extends StatelessWidget {
  const SettingsCard({Key? key, required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSection(children: children);
  }
}

class SettingsEntry extends StatelessWidget {
  const SettingsEntry({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  }) : super(key: key);

  final IconData icon;
  final Color iconColor;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      enabled: enabled,
      title: title,
      subtitle: subtitle,
      leading: ExcludeSemantics(
        child: Container(
          width: 38,
          height: 38,
          decoration: ShapeDecoration(
            color: enabled ? iconColor : Theme.of(context).disabledColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 23),
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
