import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUserKey =
        (ref.watch(userApiKeyProvider)?.isNotEmpty ?? false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 툴바 — 로그 / 설정
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: '로그',
                      icon: Icon(
                        Icons.folder_outlined,
                        color: context.colors.textSecondary,
                      ),
                      onPressed: () => context.push('/debug-log'),
                    ),
                    IconButton(
                      tooltip: hasUserKey ? '내 키 사용 중' : '설정',
                      icon: Icon(
                        hasUserKey ? Icons.vpn_key : Icons.settings_outlined,
                        color: hasUserKey
                            ? context.colors.primary
                            : context.colors.textSecondary,
                      ),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // 로고
              const Text(
                '🍜',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // 메인 버튼
              _buildMainButton(
                context,
                icon: Icons.mic,
                title: AppStrings.modeATitle,
                subtitle: '음성으로 "아무거나" 번역하기',
                color: context.colors.primary,
                onTap: () => context.go('/chat'),
              ),

              const SizedBox(height: 16),

              // 보조 버튼
              _buildMainButton(
                context,
                icon: Icons.camera_alt,
                title: AppStrings.modeBTitle,
                subtitle: '메뉴판 찍고 골라주기',
                color: context.colors.surfaceLight,
                onTap: () => context.go('/menu-scan'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isPrimary = color == context.colors.primary;
    final fg = isPrimary ? Colors.black : context.colors.textPrimary;
    final fgSubtle =
        isPrimary ? Colors.black.withValues(alpha: 0.55) : context.colors.textSecondary;
    final fgFaint =
        isPrimary ? Colors.black.withValues(alpha: 0.4) : context.colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? context.colors.primary : context.colors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: !isPrimary
              ? Border.all(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                )
              : null,
          boxShadow: isPrimary
              ? [
                  // 컬러 글로우 (primary 색상 발광)
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                  // 깊이 그림자 (떠 있는 느낌)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isPrimary ? Colors.black : context.colors.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: fgFaint,
            ),
          ],
        ),
      ),
    );
  }
}
