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
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.audioBase64,
    this.emotion,
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    String? audioBase64,
    EmotionData? emotion,
    bool? isError,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      audioBase64: audioBase64 ?? this.audioBase64,
      emotion: emotion ?? this.emotion,
      isError: isError ?? this.isError,
      timestamp: timestamp,
    );
  }
}
