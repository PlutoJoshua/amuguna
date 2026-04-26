import '../../../chat/data/models/chat_message.dart';

/// 한 턴(요청-응답)의 디버그 정보. 세션 단위로 묶여 표시된다.
class DebugLogEntry {
  final String sessionId;
  final int turnIndex;
  final DateTime timestamp;
  final ChatMode mode;

  /// 사용자 입력 정보
  final bool wasVoice;
  final int? audioBytes;       // 보낸 base64의 디코드 후 PCM 추정 크기
  final double? audioSeconds;  // 헤더 기준 추정 길이
  final String? userText;      // 텍스트 입력일 때 원문
  final String? userTranscript; // 음성 입력일 때 USER_HEARD 결과

  /// 모델 응답 원문(메타 분리 전)
  final String rawResponse;

  /// 분리된 본문/메타
  final String body;
  final String? metaBlock;

  /// 파싱된 메타
  final String? intent;
  final EmotionData? emotion;
  final String? decision;
  final List<String> quickReplies;

  /// 분리 마커가 잘 적용됐는지
  final bool metaSeparated;

  /// 메타가 폴백(텍스트 전용 추가 호출)으로 채워졌는지
  final bool metaFromFallback;

  DebugLogEntry({
    required this.sessionId,
    required this.turnIndex,
    required this.timestamp,
    required this.mode,
    required this.wasVoice,
    this.audioBytes,
    this.audioSeconds,
    this.userText,
    this.userTranscript,
    required this.rawResponse,
    required this.body,
    this.metaBlock,
    this.intent,
    this.emotion,
    this.decision,
    this.quickReplies = const [],
    required this.metaSeparated,
    this.metaFromFallback = false,
  });

  DebugLogEntry copyWith({
    String? userTranscript,
    String? metaBlock,
    String? intent,
    EmotionData? emotion,
    String? decision,
    List<String>? quickReplies,
    bool? metaSeparated,
    bool? metaFromFallback,
  }) {
    return DebugLogEntry(
      sessionId: sessionId,
      turnIndex: turnIndex,
      timestamp: timestamp,
      mode: mode,
      wasVoice: wasVoice,
      audioBytes: audioBytes,
      audioSeconds: audioSeconds,
      userText: userText,
      userTranscript: userTranscript ?? this.userTranscript,
      rawResponse: rawResponse,
      body: body,
      metaBlock: metaBlock ?? this.metaBlock,
      intent: intent ?? this.intent,
      emotion: emotion ?? this.emotion,
      decision: decision ?? this.decision,
      quickReplies: quickReplies ?? this.quickReplies,
      metaSeparated: metaSeparated ?? this.metaSeparated,
      metaFromFallback: metaFromFallback ?? this.metaFromFallback,
    );
  }
}
