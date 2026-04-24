import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 사용자가 직접 입력한 Kanana-o API 키와 익명 클라이언트 식별자를 관리한다.
///
/// - 사용자 키가 있으면 프록시를 경유하되 서버가 주입하는 공용 키 대신 이 키를 쓴다.
///   이 경로는 서버 쿼터를 소모하지 않는다.
/// - 클라이언트 ID는 서버 쿼터 카운터가 "같은 사람인지" 식별할 익명 쿠키 대체재.
class UserPreferencesService {
  static const _keyUserApiKey = 'user_kanana_api_key';
  static const _keyClientId = 'amuguna_client_id';
  static const _uuid = Uuid();

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

  /// 익명 클라이언트 ID (최초 호출 시 발급·저장).
  /// 서버 쿼터 카운터가 동일 사용자 여부를 식별할 때 사용.
  Future<String> getOrCreateClientId() async {
    final prefs = await _getPrefs();
    var id = prefs.getString(_keyClientId);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_keyClientId, id);
    }
    return id;
  }
}
