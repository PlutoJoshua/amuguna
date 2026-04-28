class ApiConfig {
  ApiConfig._();

  /// Kanana-o 공식 엔드포인트.
  /// 브라우저는 CORS 미지원으로 직접 호출이 막혀 있어 네이티브 빌드에서만 동작.
  static const baseUrl =
      'https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1';

  static const model = 'kanana-o';
  static const voicePreset = 'preset_spk_1';

  /// 빌드 타임 dart-define 주입 (선택).
  /// 개발자 본인 빌드에서 매번 키 입력 없이 돌리고 싶을 때 사용:
  ///   `--dart-define=KANANA_API_KEY=...`
  ///
  /// 공개 사용자는 비워두는 것이 정상이며, 앱 내 설정 화면에서 직접 키를 입력한다.
  static const _dartDefineApiKey = String.fromEnvironment('KANANA_API_KEY');

  /// dart-define으로 주입된 키. 미주입 시 빈 문자열.
  static String get dartDefineApiKey => _dartDefineApiKey;
}
