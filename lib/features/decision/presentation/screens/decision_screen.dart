import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/models/decision_type.dart';
import '../../data/services/type_classifier.dart';
import '../widgets/type_card.dart';

class DecisionScreen extends ConsumerStatefulWidget {
  const DecisionScreen({super.key});

  @override
  ConsumerState<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends ConsumerState<DecisionScreen>
    with TickerProviderStateMixin {
  bool _showTypeCard = false;

  late final ConfettiController _confettiController;
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // 진입 시 축하 연출
    _confettiController.play();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

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
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          SafeArea(
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
          // Confetti 오버레이
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              gravity: 0.1,
              emissionFrequency: 0.03,
              colors: [
                context.colors.primary,
                context.colors.intuit,
                context.colors.analyst,
                context.colors.vibe,
                context.colors.zen,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionPhase(String decision, int seconds) {
    return Column(
      key: const ValueKey('decision'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text('🍜', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          '오늘의 결정',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        // 스케일 애니메이션
        ScaleTransition(
          scale: _scaleAnimation,
          child: Text(
            decision,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '결정까지 걸린 시간: ${seconds}초',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _showTypeCard = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
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
        TextButton(
          onPressed: () {
            ref.read(chatNotifierProvider.notifier).resetSession();
            context.go('/');
          },
          child: Text(
            '처음으로 돌아가기',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCardPhase(
      DecisionType type, String decision, int seconds) {
    return Column(
      key: const ValueKey('typecard'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: context.colors.textSecondary),
            onPressed: () => setState(() => _showTypeCard = false),
          ),
        ),
        const Spacer(),
        TypeCard(
          type: type,
          decision: decision,
          elapsedSeconds: seconds,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).resetSession();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '처음으로 돌아가기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
