import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../data/models/decision_type.dart';

class TypeCard extends StatelessWidget {
  final DecisionType type;
  final String decision;
  final int elapsedSeconds;

  const TypeCard({
    super.key,
    required this.type,
    required this.decision,
    required this.elapsedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // 카드 색상 위 텍스트 색을 luminance로 자동 분기.
    // vibe(amber)처럼 밝은 카드에선 검정, intuit/analyst/zen에선 흰색.
    final fg = context.colors.onDecision(type.color);
    final fgSubtle = fg.withValues(alpha: 0.7);
    final fgFaint = fg.withValues(alpha: 0.4);
    final fgFainter = fg.withValues(alpha: 0.2);

    // 다크 모드는 그림자를 더 진하게, 라이트는 부드럽게
    final shadowAlpha = context.isDark ? 0.55 : 0.3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            type.color,
            type.color.withValues(alpha: 0.85),
            type.color.withValues(alpha: 0.65),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: type.color.withValues(alpha: shadowAlpha),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유형 이름
          Text(
            type.name,
            style: TextStyle(
              color: fg,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // 유형 코드
          Text(
            type.code,
            style: TextStyle(
              color: fgSubtle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          // 설명
          Text(
            '"${type.description}"',
            style: TextStyle(
              color: fg.withValues(alpha: 0.9),
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          // 스탯 바 3개
          ...type.stats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildStatBar(stat.label, stat.value, fg, fgFainter),
              )),
          const SizedBox(height: 16),
          // 궁합
          Text(
            type.compatibility,
            style: TextStyle(
              color: fgSubtle,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // 구분선
          Container(
            height: 1,
            color: fgFainter,
          ),
          const SizedBox(height: 16),
          // 결정 내용 — 메뉴명이 길어도 잘리지 않도록 2줄 레이아웃
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 결정',
                style: TextStyle(
                  color: fgSubtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$elapsedSeconds초',
                style: TextStyle(
                  color: fgSubtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            decision,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // 워터마크
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '아무거나 amuguna',
              style: TextStyle(
                color: fgFaint,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color fg, Color trackColor) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
