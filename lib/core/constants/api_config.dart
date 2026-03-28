import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  ApiConfig._();

  static const baseUrl =
      'https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1';
  static const model = 'kanana-o';
  static const voicePreset = 'preset_spk_1';

  static String get apiKey {
    final key = dotenv.env['KANANA_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw StateError('KANANA_API_KEY not set in .env file');
    }
    return key;
  }
}
