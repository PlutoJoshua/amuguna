import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class QuotaExhaustedOverlay extends StatelessWidget {
  final VoidCallback onGoHome;

  const QuotaExhaustedOverlay({super.key, required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 빈 접시 이모지
              const Text('🍽️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),

              // 메인 타이틀
              const Text(
                '오늘의 선착순 메뉴 고르기가\n마감됐어요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // 설명
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎫', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          '오늘의 맛보기 쿠폰 20장 소진',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '내일 자정에 새 쿠폰이 충전돼요!',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 정식 출시 안내
              Text(
                '정식 오픈하면 무제한으로 골라드릴게요!',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Text(
                '기대해주세요 ✨',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // 홈으로 돌아가기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGoHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '홈으로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
