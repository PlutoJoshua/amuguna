class ApiConfig {
  ApiConfig._();

  static const baseUrl =
      'https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1';
  static const model = 'kanana-o';
  static const voicePreset = 'preset_spk_1';

  static const _apiKey = String.fromEnvironment('KANANA_API_KEY');

  static String get apiKey {
    if (_apiKey.isEmpty) {
      throw StateError(
        'KANANA_API_KEY not provided. '
        'Run with: flutter run --dart-define=KANANA_API_KEY=your_key',
      );
    }
    return _apiKey;
  }
}
