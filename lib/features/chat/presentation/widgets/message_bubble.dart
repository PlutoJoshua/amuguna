import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../data/models/chat_message.dart';
import 'emotion_gauge.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onPlayAudio,
    this.onRetry,
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
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(child: _buildContent(context)),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('🍜', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isError) return _buildErrorContent(context);

    final hasTranscript =
        isUser && message.transcript != null && message.transcript!.isNotEmpty;

    // 라이트 모드의 aiBubble은 밝은 회색-블루라 흰 텍스트는 안 보임 → 자동 분기
    final bubbleColor =
        isUser ? context.colors.userBubble : context.colors.aiBubble;
    final onBubble =
        bubbleColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final onBubbleSubtle = onBubble.withValues(alpha: 0.55);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
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
              if (hasTranscript) ...[
                // 음성 메시지 + 받아쓰기 결과
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎙️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'AI가 받아 적은 말',
                      style: TextStyle(
                        color: onBubbleSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"${message.transcript!}"',
                  style: TextStyle(
                    color: onBubble,
                    fontSize: 15,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else
                Text(
                  message.text.isEmpty ? '...' : message.text,
                  style: TextStyle(
                    color: onBubble,
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
                      color: onBubble.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            color: context.colors.primary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '음성 재생',
                          style: TextStyle(
                            color: context.colors.primary,
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

  Widget _buildErrorContent(BuildContext context) {
    final errColor = context.colors.recordingRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: errColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: errColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: errColor.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: errColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh,
                        color: context.colors.textPrimary
                            .withValues(alpha: 0.7),
                        size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '다시 시도',
                      style: TextStyle(
                        color: context.colors.textPrimary
                            .withValues(alpha: 0.7),
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
    );
  }
}
