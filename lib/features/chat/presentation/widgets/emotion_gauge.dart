import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../data/models/chat_message.dart';

class EmotionGauge extends StatelessWidget {
  final EmotionData emotion;

  const EmotionGauge({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final emotions = _getActiveEmotions(context);
    if (emotions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: emotions
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildBar(context, e.label, e.value, e.color),
                ))
            .toList(),
      ),
    );
  }

  List<_EmotionEntry> _getActiveEmotions(BuildContext context) {
    final all = [
      _EmotionEntry('피곤함', emotion.tired, context.colors.emotionTired),
      _EmotionEntry('기대감', emotion.excited, context.colors.emotionExcited),
      _EmotionEntry('스트레스', emotion.stressed, context.colors.emotionStressed),
      _EmotionEntry('망설임', emotion.hesitant, context.colors.emotionHesitant),
    ];
    // 20% 이상인 감정만 표시
    return all.where((e) => e.value >= 20).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Widget _buildBar(BuildContext context, String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: LinearProgressIndicator(
                value: value / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmotionEntry {
  final String label;
  final int value;
  final Color color;

  const _EmotionEntry(this.label, this.value, this.color);
}
