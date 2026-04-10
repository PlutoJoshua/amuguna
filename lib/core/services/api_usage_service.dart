import 'package:shared_preferences/shared_preferences.dart';

/// 하루 API 호출 횟수 제한 관리
class ApiUsageService {
  static const _keyDate = 'api_usage_date';
  static const _keyCount = 'api_usage_count';
  static const int dailyLimit = 20;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 날짜가 바뀌었으면 카운트 리셋
  Future<void> _resetIfNewDay() async {
    final prefs = await _getPrefs();
    final savedDate = prefs.getString(_keyDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
    }
  }

  /// 남은 호출 횟수
  Future<int> getRemainingCalls() async {
    await _resetIfNewDay();
    final prefs = await _getPrefs();
    final used = prefs.getInt(_keyCount) ?? 0;
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// 호출 가능 여부
  Future<bool> canMakeCall() async {
    return (await getRemainingCalls()) > 0;
  }

  /// 호출 1회 기록
  Future<int> recordCall() async {
    await _resetIfNewDay();
    final prefs = await _getPrefs();
    final used = (prefs.getInt(_keyCount) ?? 0) + 1;
    await prefs.setInt(_keyCount, used);
    return (dailyLimit - used).clamp(0, dailyLimit);
  }
}
