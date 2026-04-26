import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
                      icon: const Icon(
                        Icons.folder_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => context.push('/debug-log'),
                    ),
                    IconButton(
                      tooltip: hasUserKey ? '내 키 사용 중' : '설정',
                      icon: Icon(
                        hasUserKey ? Icons.vpn_key : Icons.settings_outlined,
                        color: hasUserKey
                            ? AppColors.primary
                            : AppColors.textSecondary,
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
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
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
                color: AppColors.primary,
                onTap: () => context.go('/chat'),
              ),

              const SizedBox(height: 16),

              // 보조 버튼
              _buildMainButton(
                context,
                icon: Icons.camera_alt,
                title: AppStrings.modeBTitle,
                subtitle: '메뉴판 찍고 골라주기',
                color: AppColors.surfaceLight,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color == AppColors.primary
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: color != AppColors.primary
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                )
              : null,
          boxShadow: color == AppColors.primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color:
                  color == AppColors.primary ? Colors.black : AppColors.primary,
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
                      color: color == AppColors.primary
                          ? Colors.black
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color == AppColors.primary
                          ? Colors.black54
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color == AppColors.primary
                  ? Colors.black45
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
