import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stack: details.stack,
      );
    };

    runApp(
      const ProviderScope(
        child: AmugunaApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error('Uncaught error', error: error, stack: stack);
  });
}
