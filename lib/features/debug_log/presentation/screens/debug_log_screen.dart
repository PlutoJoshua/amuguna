import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../data/models/debug_log_entry.dart';
import '../providers/debug_log_provider.dart';

class DebugLogScreen extends ConsumerWidget {
  const DebugLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(debugLogBySessionProvider);
    // 세션은 가장 최근 활동순으로
    final sessionIds = grouped.keys.toList()
      ..sort((a, b) {
        final aLast = grouped[a]!.last.timestamp;
        final bLast = grouped[b]!.last.timestamp;
        return bLast.compareTo(aLast);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (sessionIds.isNotEmpty)
            IconButton(
              tooltip: '전체 비우기',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                ref.read(debugLogProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: sessionIds.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sessionIds.length,
                itemBuilder: (context, i) {
                  final sid = sessionIds[i];
                  final entries = grouped[sid]!;
                  return _SessionFolder(
                    sessionId: sid,
                    entries: entries,
                    isMostRecent: i == 0,
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '아직 기록된 대화가 없어요',
            style: TextStyle(
              color: context.colors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionFolder extends StatelessWidget {
  final String sessionId;
  final List<DebugLogEntry> entries;
  final bool isMostRecent;

  const _SessionFolder({
    required this.sessionId,
    required this.entries,
    required this.isMostRecent,
  });

  @override
  Widget build(BuildContext context) {
    final firstTime = entries.first.timestamp;
    final mode = entries.first.mode;
    final modeLabel = mode == ChatMode.modeA ? '🍜 뭐 먹지?' : '📋 뭐 시키지?';
    final dateStr =
        '${firstTime.month}/${firstTime.day} ${firstTime.hour.toString().padLeft(2, '0')}:${firstTime.minute.toString().padLeft(2, '0')}';
    final shortId = sessionId.split('-').first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: isMostRecent,
            leading: Icon(Icons.folder_outlined,
                color: context.colors.primary, size: 22),
            title: Text(
              '$modeLabel · $dateStr',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '$shortId · ${entries.length}턴',
              style: TextStyle(
                color: context.colors.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            childrenPadding:
                const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: entries.map((e) => _TurnTile(entry: e)).toList(),
          ),
        ),
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  final DebugLogEntry entry;

  const _TurnTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final ts = entry.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.metaSeparated
              ? context.colors.primary.withValues(alpha: 0.2)
              : context.colors.recordingRed.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '#${entry.turnIndex + 1} · $timeStr',
                style: TextStyle(
                  color: context.colors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (entry.wasVoice)
                _Chip(
                  label:
                      '🎙️ ${entry.audioSeconds?.toStringAsFixed(1) ?? "?"}s · ${((entry.audioBytes ?? 0) / 1024).toStringAsFixed(0)}KB',
                  color: context.colors.primary,
                )
              else
                _Chip(label: '⌨️ 텍스트', color: context.colors.primary),
              const Spacer(),
              if (!entry.metaSeparated)
                _Chip(
                  label: 'META 분리 실패',
                  color: context.colors.recordingRed,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 사용자 입력
          _Section(
            label: '입력',
            value: entry.wasVoice
                ? (entry.userTranscript ?? '(받아쓰기 없음)')
                : (entry.userText ?? ''),
            italic: entry.wasVoice,
          ),

          // 의도 / 감정 / 결정
          if (entry.intent != null)
            _Section(label: '의도', value: entry.intent!),
          if (entry.emotion != null)
            _Section(
              label: '감정',
              value:
                  '피곤 ${entry.emotion!.tired} · 들뜸 ${entry.emotion!.excited} · 스트레스 ${entry.emotion!.stressed} · 망설임 ${entry.emotion!.hesitant}',
            ),
          if (entry.decision != null)
            _Section(label: '결정', value: entry.decision!),
          if (entry.quickReplies.isNotEmpty)
            _Section(
              label: '빠른 답변',
              value: entry.quickReplies.join(' / '),
            ),

          const SizedBox(height: 8),

          // 본문
          _ExpandableSection(
            label: '응답 본문 (사용자 노출)',
            value: entry.body,
          ),

          // raw
          _ExpandableSection(
            label: 'AI RAW (원본)',
            value: entry.rawResponse,
            allowCopy: true,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String value;
  final bool italic;
  const _Section({
    required this.label,
    required this.value,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textSecondary.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 12,
                height: 1.4,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String label;
  final String value;
  final bool allowCopy;
  const _ExpandableSection({
    required this.label,
    required this.value,
    this.allowCopy = false,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: context.colors.textSecondary.withValues(alpha: 0.7),
                ),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: context.colors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.allowCopy) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    color: context.colors.textSecondary.withValues(alpha: 0.7),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    tooltip: '복사',
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: widget.value));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('복사했어요'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                widget.value.isEmpty ? '(empty)' : widget.value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'Menlo',
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
