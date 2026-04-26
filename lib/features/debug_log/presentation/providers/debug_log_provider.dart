import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/data/models/chat_message.dart';
import '../../data/models/debug_log_entry.dart';

/// 앱 전체에서 누적되는 디버그 로그.
/// 메모리에만 보관(앱 재시작 시 휘발). 한 세션 안에서 모든 턴이 연결돼 보임.
class DebugLogNotifier extends StateNotifier<List<DebugLogEntry>> {
  DebugLogNotifier() : super(const []);

  /// 가장 오래된 엔트리부터 잘라내는 보관 한도 (메모리 보호)
  static const _maxEntries = 200;

  void add(DebugLogEntry entry) {
    final next = [...state, entry];
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    state = next;
  }

  /// 가장 최근 엔트리(같은 세션·턴)에 메타 정보 보강.
  /// 메인 호출이 메타를 빠뜨려서 폴백 호출로 받은 결과를 반영할 때 쓴다.
  void updateLast({
    required String sessionId,
    required int turnIndex,
    String? userTranscript,
    String? intent,
    EmotionData? emotion,
    String? decision,
    List<String>? quickReplies,
    String? metaBlock,
  }) {
    if (state.isEmpty) return;
    final next = [...state];
    for (var i = next.length - 1; i >= 0; i--) {
      final e = next[i];
      if (e.sessionId == sessionId && e.turnIndex == turnIndex) {
        next[i] = e.copyWith(
          userTranscript: userTranscript,
          intent: intent,
          emotion: emotion,
          decision: decision,
          quickReplies: quickReplies,
          metaBlock: metaBlock,
          metaFromFallback: true,
          metaSeparated: true,
        );
        state = next;
        return;
      }
    }
  }

  void clear() {
    state = const [];
  }
}

final debugLogProvider =
    StateNotifierProvider<DebugLogNotifier, List<DebugLogEntry>>(
  (ref) => DebugLogNotifier(),
);

/// 세션 ID 기준으로 그룹핑된 보기용 selector.
final debugLogBySessionProvider =
    Provider<Map<String, List<DebugLogEntry>>>((ref) {
  final entries = ref.watch(debugLogProvider);
  final map = <String, List<DebugLogEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.sessionId, () => []).add(e);
  }
  return map;
});
