import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/quick_reply_chips.dart';
import '../widgets/record_button.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    // 메시지 변경 시 자동 스크롤
    ref.listen(chatNotifierProvider.select((s) => s.messages.length), (_, __) {
      _scrollToBottom();
    });

    // 스트리밍 중에도 스크롤
    ref.listen(chatNotifierProvider.select((s) => s.isStreaming), (_, isStreaming) {
      if (isStreaming) _scrollToBottom();
    });

    // 결정 감지 시 결정 화면으로 이동
    ref.listen(chatNotifierProvider.select((s) => s.decision), (prev, next) {
      if (prev == null && next != null) {
        // 약간의 딜레이로 마지막 메시지를 보여준 후 이동
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.go('/decision');
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
          onPressed: () {
            ref.read(chatNotifierProvider.notifier).resetSession();
            context.go('/');
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍜 ', style: TextStyle(fontSize: 22)),
            Text(
              chatState.mode == ChatMode.modeA
                  ? AppStrings.modeATitle
                  : AppStrings.modeBTitle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(chatNotifierProvider.notifier).resetSession();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 대화 영역
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: chatState.messages.length,
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return MessageBubble(
                    message: message,
                    onPlayAudio: message.audioBase64 != null
                        ? () async {
                            try {
                              await ref
                                  .read(audioPlayerProvider)
                                  .playBase64Audio(message.audioBase64!);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('음성 재생에 실패했어요'),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    onRetry: message.isError
                        ? () {
                            ref
                                .read(chatNotifierProvider.notifier)
                                .retryLastMessage();
                          }
                        : null,
                  );
                },
              ),
            ),

            // 스트리밍 인디케이터
            if (chatState.isStreaming)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 44), // 아바타 공간
                    _TypingIndicator(),
                  ],
                ),
              ),

            // 빠른 답장 칩
            if (chatState.quickReplies.isNotEmpty &&
                !chatState.isStreaming &&
                !chatState.isRecording)
              QuickReplyChips(
                replies: chatState.quickReplies,
                onTap: (reply) {
                  ref.read(chatNotifierProvider.notifier).sendTextMessage(reply);
                },
              ),

            // 입력 영역
            _buildInputArea(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 텍스트 입력
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.textInputHint,
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _textController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.send,
                                  color: AppColors.primary, size: 20),
                              onPressed: _sendText,
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _sendText(),
                    enabled: !chatState.isStreaming,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 녹음 버튼
              RecordButton(
                isRecording: chatState.isRecording,
                isProcessing: chatState.isStreaming,
                recordingSeconds: chatState.recordingDurationSeconds,
                onTap: chatState.isStreaming
                    ? () {}
                    : () {
                        ref
                            .read(chatNotifierProvider.notifier)
                            .toggleRecording();
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 상태: 파형 바 or 텍스트
          chatState.isRecording
              ? _AudioWaveBar(amplitude: chatState.currentAmplitude)
              : Text(
                  chatState.isStreaming
                      ? AppStrings.processing
                      : AppStrings.tapToRecord,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
        ],
      ),
    );
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _focusNode.unfocus();
    ref.read(chatNotifierProvider.notifier).sendTextMessage(text);
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (i) {
            final offset = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final opacity = 0.3 + (0.7 * (1 - (offset - 0.5).abs() * 2)).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AudioWaveBar extends StatelessWidget {
  final double amplitude;

  const _AudioWaveBar({required this.amplitude});

  @override
  Widget build(BuildContext context) {
    // amplitude는 dB (-160 ~ 0), 0.0~1.0으로 정규화
    final normalized = ((amplitude + 50) / 50).clamp(0.0, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        // 각 바에 약간의 변화를 줌
        final barHeight =
            4.0 + (normalized * 16.0 * (1.0 - (i - 3).abs() / 4.0));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.recordingRed,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
