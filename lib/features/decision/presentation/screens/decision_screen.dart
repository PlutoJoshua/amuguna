import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/models/decision_type.dart';
import '../../data/services/type_classifier.dart';
import '../widgets/type_card.dart';

class DecisionScreen extends ConsumerStatefulWidget {
  const DecisionScreen({super.key});

  @override
  ConsumerState<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends ConsumerState<DecisionScreen> {
  bool _showTypeCard = false;
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final decision = chatState.decision ?? '미정';
    final seconds = chatState.elapsedSeconds;

    final decisionType = TypeClassifier.classify(
      turnCount: chatState.turnCount,
      elapsedSeconds: seconds,
      emotionHistory: chatState.emotionHistory,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showTypeCard
                ? _buildTypeCardPhase(decisionType, decision, seconds)
                : _buildDecisionPhase(decision, seconds),
          ),
        ),
      ),
    );
  }

  /// Phase 1: 결정 완료
  Widget _buildDecisionPhase(String decision, int seconds) {
    return Column(
      key: const ValueKey('decision'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text('🍜', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        const Text(
          '오늘의 결정',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          decision,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '결정까지 걸린 시간: ${seconds}초',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const Spacer(),
        // 결정 유형 보기 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _showTypeCard = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '나의 결정 유형 보기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 처음으로
        TextButton(
          onPressed: () {
            ref.read(chatNotifierProvider.notifier).resetSession();
            context.go('/');
          },
          child: const Text(
            '처음으로 돌아가기',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  /// Phase 2: 유형 카드
  Widget _buildTypeCardPhase(
      DecisionType type, String decision, int seconds) {
    return Column(
      key: const ValueKey('typecard'),
      children: [
        // 뒤로
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textSecondary),
            onPressed: () => setState(() => _showTypeCard = false),
          ),
        ),
        const Spacer(),
        // TypeCard
        RepaintBoundary(
          key: _cardKey,
          child: TypeCard(
            type: type,
            decision: decision,
            elapsedSeconds: seconds,
          ),
        ),
        const Spacer(),
        // 카카오톡 공유
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: 카카오톡 공유
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카카오톡 공유 기능 준비 중')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('카카오톡으로 공유하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 처음으로
        TextButton(
          onPressed: () {
            ref.read(chatNotifierProvider.notifier).resetSession();
            context.go('/');
          },
          child: const Text(
            '처음으로 돌아가기',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
