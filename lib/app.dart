import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/decision/presentation/screens/decision_screen.dart';
import 'features/menu_scan/presentation/screens/menu_scan_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
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
  ],
);

class AmugunaApp extends StatelessWidget {
  const AmugunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '아무거나',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
