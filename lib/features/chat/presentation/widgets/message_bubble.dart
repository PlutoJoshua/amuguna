import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/chat_message.dart';
import 'emotion_gauge.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onPlayAudio;

  const MessageBubble({
    super.key,
    required this.message,
    this.onPlayAudio,
  });

  bool get isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(child: _buildContent()),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('🍜', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? AppColors.userBubble : AppColors.aiBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text.isEmpty ? '...' : message.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (message.audioBase64 != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onPlayAudio,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 4),
                        Text(
                          '음성 재생',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (message.emotion != null) ...[
          const SizedBox(height: 8),
          EmotionGauge(emotion: message.emotion!),
        ],
      ],
    );
  }
}
