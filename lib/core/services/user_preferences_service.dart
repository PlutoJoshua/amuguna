import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 키 + 테마 모드 같은 단말 보존 설정 저장소.
class UserPreferencesService {
  static const _keyUserApiKey = 'user_kanana_api_key';
  static const _keyThemeMode = 'theme_mode';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 사용자가 입력한 Kanana-o API 키 (없으면 null)
  Future<String?> getUserApiKey() async {
    final prefs = await _getPrefs();
    final key = prefs.getString(_keyUserApiKey)?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  Future<void> setUserApiKey(String key) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyUserApiKey, key.trim());
  }

  Future<void> clearUserApiKey() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyUserApiKey);
  }

  Future<bool> hasUserApiKey() async => (await getUserApiKey()) != null;

  /// 저장된 ThemeMode. 기본값은 시스템 follow.
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _getPrefs();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_keyThemeMode, raw);
  }
}
