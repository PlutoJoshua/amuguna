import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../providers/theme_mode_provider.dart';

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
                ? '키를 지웠어요. 다시 입력해야 사용할 수 있어요.'
                : 'Kanana-o 키를 저장했어요!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      // 키가 비어있으면 라우팅 가드가 다시 여기로 돌려보낼 거라 pop 의미 없음.
      // 키가 있을 때만 이전 화면으로 복귀.
      if (mounted && key.isNotEmpty) context.pop();
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
    // dart-define으로 키가 빌드에 박혀 있으면 뒤로 갈 수 있음 (개발자 본인 빌드)
    final hasEffectiveKey =
        ref.watch(effectiveApiKeyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        leading: hasEffectiveKey
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 배너 — 키 상태 표시
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasKey
                      ? context.colors.primary.withValues(alpha: 0.15)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasKey
                        ? context.colors.primary
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasKey ? Icons.vpn_key : Icons.lock_outline,
                      color: hasKey ? context.colors.primary : context.colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasKey
                            ? '키 등록됨 — 본인 Kanana-o 쿼터로 사용 중'
                            : 'Kanana-o API 키를 입력해주세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasKey
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                          fontWeight:
                              hasKey ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── 테마 ─────────────────────────────────────
              Text(
                '🎨 테마',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('시스템'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('라이트'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('다크'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {ref.watch(themeModeProvider)},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) setThemeMode(ref, set.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Kanana-o API 키',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '본인의 Kanana-o API 키가 있어야 앱이 동작합니다. '
                '키는 이 기기에만 저장되고 서버로 전송되지 않습니다. '
                '호출 비용은 본인의 Kanana-o 계정으로 청구됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
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
                  fillColor: context.colors.surface,
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
                        backgroundColor: context.colors.primary,
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
                        foregroundColor: context.colors.recordingRed,
                        side: BorderSide(
                          color: context.colors.recordingRed,
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
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kanana-o API 키는 어디서 받나요?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '카카오 Kanana 앰배서더/베타 프로그램에 참여하면 발급됩니다. '
                      '공식 문서는 HuggingFace의 Kanana-1.5-o-9.8B-instruct-2602-API_Doc 참고.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary.withValues(alpha: 0.8),
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
