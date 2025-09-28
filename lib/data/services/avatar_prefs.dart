// lib/data/services/avatar_prefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class AvatarPrefs {
  static const _key = 'selected_avatar_path';

  Future<void> setSelectedAvatarPath(String path) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, path);
  }

  Future<String?> getSelectedAvatarPath() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key);
  }
}
