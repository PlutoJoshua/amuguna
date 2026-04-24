import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/user_preferences_service.dart';
import 'core/utils/app_logger.dart';
import 'features/chat/presentation/providers/chat_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stack: details.stack,
      );
    };

    // 사용자 설정 사전 로드 (API 키, 클라이언트 ID).
    // ProviderScope의 override로 동기 접근 가능하게 만든다.
    final prefs = UserPreferencesService();
    final clientId = await prefs.getOrCreateClientId();
    final userKey = await prefs.getUserApiKey();

    runApp(
      ProviderScope(
        overrides: [
          userPreferencesServiceProvider.overrideWithValue(prefs),
          clientIdProvider.overrideWith((ref) => clientId),
          userApiKeyProvider.overrideWith((ref) => userKey),
        ],
        child: const AmugunaApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error('Uncaught error', error: error, stack: stack);
  });
}
