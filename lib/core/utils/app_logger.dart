import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// 앱 전역 로거. Release 모드에서는 자동으로 비활성화.
class AppLogger {
  AppLogger._();

  static void info(String message, {String? tag}) {
    if (kReleaseMode) return;
    dev.log(message, name: tag ?? 'APP');
  }

  static void warning(String message, {String? tag}) {
    if (kReleaseMode) return;
    dev.log('⚠️ $message', name: tag ?? 'APP');
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    String? tag,
  }) {
    // 에러는 release에서도 기록 (추후 Sentry 등 연결용)
    dev.log(
      '❌ $message',
      name: tag ?? 'APP',
      error: error,
      stackTrace: stack,
    );
  }
}
