import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/debug_log/presentation/screens/debug_log_screen.dart';
import 'features/decision/presentation/screens/decision_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/menu_scan/presentation/screens/menu_scan_screen.dart';
import 'features/settings/presentation/providers/theme_mode_provider.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // 키 미설정이면 설정/디버그 외 화면 진입 차단 → 설정으로.
      // 사용자 입력 키 또는 dart-define 키 둘 중 하나만 있으면 통과.
      final hasKey = ref.watch(effectiveApiKeyProvider).isNotEmpty;
      final loc = state.matchedLocation;
      final keyRequired = loc != '/settings' && loc != '/debug-log';
      if (!hasKey && keyRequired) return '/settings';

      if (loc == '/decision') {
        final chatState = ref.read(chatNotifierProvider);
        if (chatState.decision == null) return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/menu-scan',
        builder: (context, state) => const MenuScanScreen(),
      ),
      GoRoute(
        path: '/decision',
        builder: (context, state) => const DecisionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/debug-log',
        builder: (context, state) => const DebugLogScreen(),
      ),
    ],
  );
});

class AmugunaApp extends ConsumerWidget {
  const AmugunaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '아무거나',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
