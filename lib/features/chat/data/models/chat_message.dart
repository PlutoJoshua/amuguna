enum MessageRole { user, assistant, system }

enum ChatMode { modeA, modeB }

class EmotionData {
  final int tired;
  final int excited;
  final int stressed;
  final int hesitant;

  const EmotionData({
    this.tired = 0,
    this.excited = 0,
    this.stressed = 0,
    this.hesitant = 0,
  });

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    return EmotionData(
      tired: (json['tired'] as num?)?.toInt() ?? 0,
      excited: (json['excited'] as num?)?.toInt() ?? 0,
      stressed: (json['stressed'] as num?)?.toInt() ?? 0,
      hesitant: (json['hesitant'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final String? audioBase64;
  final EmotionData? emotion;
  /// AI가 한 줄로 정리한 사용자 의도 (assistant 메시지에서만 채워짐).
  /// 예: "피곤해서 든든하고 빠른 끼니를 원함"
  final String? intent;
  /// 음성 메시지였을 때 AI가 받아 적은 사용자 발화 (user 메시지에 채워짐).
  final String? transcript;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.audioBase64,
    this.emotion,
    this.intent,
    this.transcript,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    String? audioBase64,
    EmotionData? emotion,
    String? intent,
    String? transcript,
    bool? isError,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      audioBase64: audioBase64 ?? this.audioBase64,
      emotion: emotion ?? this.emotion,
      intent: intent ?? this.intent,
      transcript: transcript ?? this.transcript,
      isError: isError ?? this.isError,
      timestamp: timestamp,
    );
  }
}
