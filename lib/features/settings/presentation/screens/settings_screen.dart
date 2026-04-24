import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(userApiKeyProvider) ?? '';
    _controller = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    setState(() => _saving = true);
    try {
      final prefs = ref.read(userPreferencesServiceProvider);
      if (key.isEmpty) {
        await prefs.clearUserApiKey();
        ref.read(userApiKeyProvider.notifier).state = null;
      } else {
        await prefs.setUserApiKey(key);
        ref.read(userApiKeyProvider.notifier).state = key;
      }
      // KananaClient 재구성 → 대화 세션도 초기화해서 새 클라이언트로 시작
      ref.invalidate(chatNotifierProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            key.isEmpty
                ? '내 키를 지웠어요. 이제 공용 쿼터로 쓰게 됩니다.'
                : '내 Kanana-o 키를 저장했어요. 이제 무제한으로 쓸 수 있어요!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = (ref.watch(userApiKeyProvider)?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 배너 — 현재 모드 표시
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasKey
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasKey
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasKey ? Icons.vpn_key : Icons.public,
                      color: hasKey ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasKey
                            ? '내 키 모드 — 본인 Kanana-o 쿼터로 무제한 사용'
                            : '공용 모드 — 하루 20명 선착순, 일 20회까지',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasKey
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              hasKey ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Kanana-o API 키 (선택)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '본인 Kanana-o API 키를 입력하면 공용 쿼터와 상관없이 바로 쓸 수 있어요. '
                '키는 이 기기에만 저장되고 서버로 전송되지 않습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'kanana-... 로 시작하는 API 키',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      IconButton(
                        icon: const Icon(Icons.paste),
                        tooltip: '붙여넣기',
                        onPressed: () async {
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            _controller.text = data!.text!.trim();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              hasKey ? '변경 사항 저장' : '키 저장하기',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (hasKey) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () {
                              _controller.clear();
                              _save();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.recordingRed,
                        side: const BorderSide(
                          color: AppColors.recordingRed,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('키 삭제'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kanana-o API 키는 어디서 받나요?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '카카오 Kanana 앰배서더/베타 프로그램에 참여하면 발급됩니다. '
                      '공식 문서는 HuggingFace의 Kanana-1.5-o-9.8B-instruct-2602-API_Doc 참고.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
