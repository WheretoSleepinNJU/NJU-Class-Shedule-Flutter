import 'package:shared_preferences/shared_preferences.dart';

/// 记住账号密码，登录表单打开时自动填充，不用每次都重新输入。
///
/// 跟这个 App 里其它本地数据（登录标记、检查更新时间等）一样存在普通
/// SharedPreferences 里，不是加密存储——如果之后觉得"密码明文存在本地"
/// 不够安全，可以换成 flutter_secure_storage，但那个包目前没有鸿蒙
/// 实现，换的话需要另外按平台判断，这里先跟现有存储方式保持一致。
class NjuCredentialStore {
  static const _usernameKey = 'nju_saved_username';
  static const _passwordKey = 'nju_saved_password';

  static Future<void> save(String username, String password) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_usernameKey, username);
    await sp.setString(_passwordKey, password);
  }

  static Future<(String, String)> read() async {
    final sp = await SharedPreferences.getInstance();
    final username = sp.getString(_usernameKey) ?? '';
    final password = sp.getString(_passwordKey) ?? '';
    return (username, password);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_usernameKey);
    await sp.remove(_passwordKey);
  }
}
