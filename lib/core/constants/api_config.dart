class ApiConfig {
  ApiConfig._();

  /// Kanana-o 공식 엔드포인트 (네이티브 앱에서 직접 호출용).
  /// 웹은 CORS 때문에 프록시(`proxyBaseUrl`)를 경유해야 한다.
  static const kananaDirectBaseUrl =
      'https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1';

  static const model = 'kanana-o';
  static const voicePreset = 'preset_spk_1';

  /// 빌드 타임 dart-define 주입.
  /// - 로컬 개발/네이티브 테스트: `--dart-define=KANANA_API_KEY=xxx`로 직접 호출
  /// - 프록시 경유 모드: 비워두기 (프록시 서버가 서버 측 키를 주입)
  static const _dartDefineApiKey = String.fromEnvironment('KANANA_API_KEY');

  /// 프록시 서버 베이스 URL. 비어있으면 `kananaDirectBaseUrl`로 직접 호출.
  /// 예: `https://amuguna-xxx.web.app`
  /// 실제 엔드포인트는 `${proxyBaseUrl}/api/kanana-proxy/chat/completions` 형태.
  static const proxyBaseUrl = String.fromEnvironment('PROXY_BASE_URL');

  /// 프록시 경유 모드 여부
  static bool get useProxy => proxyBaseUrl.isNotEmpty;

  /// 직접 호출 시 사용할 dart-define 키 (없으면 빈 문자열)
  static String get directApiKey => _dartDefineApiKey;
}
