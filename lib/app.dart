import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/decision/presentation/screens/decision_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/menu_scan/presentation/screens/menu_scan_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (state.matchedLocation == '/decision') {
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
    ],
  );
});

class AmugunaApp extends ConsumerWidget {
  const AmugunaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '아무거나',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
