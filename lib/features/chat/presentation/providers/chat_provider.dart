import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/audio/audio_player_service.dart';
import '../../../../core/audio/audio_recorder_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/kanana_client.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

// --- Providers ---

final kananaClientProvider = Provider<KananaClient>((ref) {
  final client = KananaClient(apiKey: ApiConfig.apiKey);
  ref.onDispose(() => client.dispose());
  return client;
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(client: ref.read(kananaClientProvider));
});

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  final recorder = AudioRecorderService();
  ref.onDispose(() => recorder.dispose());
  return recorder;
});

final audioPlayerProvider = Provider<AudioPlayerService>((ref) {
  final player = AudioPlayerService();
  ref.onDispose(() => player.dispose());
  return player;
});

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    repository: ref.read(chatRepositoryProvider),
    recorder: ref.read(audioRecorderProvider),
    player: ref.read(audioPlayerProvider),
  );
});

// --- State ---

class ChatState {
  final List<ChatMessage> messages;
  final List<Map<String, dynamic>> apiHistory;
  final ChatMode mode;
  final int turnCount;
  final bool isStreaming;
  final bool isRecording;
  final String sessionId;
  final DateTime startTime;
  final String? decision;
  final EmotionData? currentEmotion;
  final List<EmotionData> emotionHistory;

  const ChatState({
    this.messages = const [],
    this.apiHistory = const [],
    this.mode = ChatMode.modeA,
    this.turnCount = 0,
    this.isStreaming = false,
    this.isRecording = false,
    this.sessionId = '',
    required this.startTime,
    this.decision,
    this.currentEmotion,
    this.emotionHistory = const [],
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? apiHistory,
    ChatMode? mode,
    int? turnCount,
    bool? isStreaming,
    bool? isRecording,
    String? sessionId,
    String? decision,
    EmotionData? currentEmotion,
    List<EmotionData>? emotionHistory,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      apiHistory: apiHistory ?? this.apiHistory,
      mode: mode ?? this.mode,
      turnCount: turnCount ?? this.turnCount,
      isStreaming: isStreaming ?? this.isStreaming,
      isRecording: isRecording ?? this.isRecording,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime,
      decision: decision ?? this.decision,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      emotionHistory: emotionHistory ?? this.emotionHistory,
    );
  }

  /// 결정까지 걸린 시간 (초)
  int get elapsedSeconds => DateTime.now().difference(startTime).inSeconds;
}

// --- Notifier ---

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final AudioRecorderService _recorder;
  final AudioPlayerService _player;
  static const _uuid = Uuid();

  ChatNotifier({
    required ChatRepository repository,
    required AudioRecorderService recorder,
    required AudioPlayerService player,
  })  : _repository = repository,
        _recorder = recorder,
        _player = player,
        super(ChatState(
          sessionId: _uuid.v4(),
          startTime: DateTime.now(),
        )) {
    // 초기 인사 메시지
    _addAssistantGreeting();
  }

  void _addAssistantGreeting() {
    final greeting = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '안녕! 오늘은 뭐 먹을지 같이 정해볼까? 🍜\n말해도 좋고, 글로 써도 좋아!',
    );
    state = state.copyWith(messages: [greeting]);
  }

  /// 녹음 토글
  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await _stopAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecording();
      state = state.copyWith(isRecording: true);
    } catch (e) {
      // 권한 거부 등
    }
  }

  Future<void> _stopAndSend() async {
    state = state.copyWith(isRecording: false);
    final audioBase64 = await _recorder.stopRecording();
    if (audioBase64 == null) return;

    // 사용자 메시지 추가 (음성은 텍스트 미리보기 없이)
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: '🎙️ 음성 메시지',
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
    );

    await _streamResponse(
      stream: _repository.sendVoiceMessage(
        audioBase64: audioBase64,
        history: state.apiHistory,
        mode: state.mode,
      ),
    );
  }

  /// 텍스트 메시지 전송
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: text,
    );

    // API 히스토리에 텍스트 메시지 추가
    final updatedHistory = [
      ...state.apiHistory,
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': text},
        ],
      },
    ];

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      apiHistory: updatedHistory,
      isStreaming: true,
    );

    await _streamResponse(
      stream: _repository.sendTextMessage(
        text: text,
        history: state.apiHistory,
        mode: state.mode,
      ),
      addUserToHistory: false, // 이미 추가됨
    );
  }

  Future<void> _streamResponse({
    required Stream<KananaStreamChunk> stream,
    bool addUserToHistory = true,
  }) async {
    final assistantId = _uuid.v4();
    String latestContent = '';    // delta.content (누적형 - 매번 교체)
    String latestTranscript = ''; // delta.audio.transcript (누적형)
    final audioChunks = <Uint8List>[];

    // 빈 assistant 메시지 추가 (스트리밍 중 업데이트됨)
    final assistantMessage = ChatMessage(
      id: assistantId,
      role: MessageRole.assistant,
      text: '',
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
    );

    try {
      await for (final chunk in stream) {
        if (chunk.isDone) break;

        // Kanana-o는 누적 텍스트를 보냄 → 교체 (append 아님!)
        if (chunk.textDelta != null) {
          latestContent = chunk.textDelta!;
          _updateAssistantMessage(assistantId, latestContent);
        }

        if (chunk.audioTranscript != null) {
          latestTranscript = chunk.audioTranscript!;
          if (latestContent.isEmpty) {
            _updateAssistantMessage(assistantId, latestTranscript);
          }
        }

        if (chunk.audioDelta != null) {
          try {
            audioChunks.add(base64Decode(chunk.audioDelta!));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Stream error: $e');
      if (latestContent.isEmpty && latestTranscript.isEmpty) {
        latestContent = '죄송해요, 잠시 문제가 생겼어요. 다시 말해주세요!';
      }
    }

    // content가 있으면 content 사용, 없으면 transcript 사용
    final displayText = latestContent.isNotEmpty
        ? latestContent
        : latestTranscript;

    debugPrint('Response: content=${latestContent.length}ch, '
        'transcript=${latestTranscript.length}ch');

    // 감정 + 결정 데이터 파싱
    final emotion = _parseEmotion(displayText);
    final parsedDecision = _parseDecision(displayText);
    final cleanText = _removeDecisionTag(_removeEmotionTag(displayText));

    // 오디오 청크 합치기 → 다시 Base64로
    String? audioData;
    if (audioChunks.isNotEmpty) {
      final totalLength = audioChunks.fold<int>(0, (sum, c) => sum + c.length);
      final combined = Uint8List(totalLength);
      var offset = 0;
      for (final chunk in audioChunks) {
        combined.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      audioData = base64Encode(combined);
      debugPrint('Audio: ${combined.length} bytes, '
          'first 4: ${combined.take(4).toList()}');
    }

    // 최종 메시지 업데이트
    _updateAssistantMessage(
      assistantId,
      cleanText,
      audioBase64: audioData,
      emotion: emotion,
    );

    // API 히스토리 업데이트 (텍스트만)
    final updatedHistory = [
      ...state.apiHistory,
      {
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': cleanText},
        ],
      },
    ];

    state = state.copyWith(
      apiHistory: updatedHistory,
      isStreaming: false,
      turnCount: state.turnCount + 1,
      currentEmotion: emotion,
      emotionHistory: emotion != null
          ? [...state.emotionHistory, emotion]
          : state.emotionHistory,
      decision: parsedDecision ?? state.decision,
    );

    // 오디오 자동 재생
    if (audioData != null) {
      try {
        await _player.playBase64Audio(audioData);
      } catch (_) {}
    }
  }

  void _updateAssistantMessage(
    String id,
    String text, {
    String? audioBase64,
    EmotionData? emotion,
  }) {
    final messages = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(
          text: _removeEmotionTag(text),
          audioBase64: audioBase64,
          emotion: emotion,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(messages: messages);
  }

  /// [EMOTION]{...}[/EMOTION] 태그에서 감정 데이터 파싱
  EmotionData? _parseEmotion(String text) {
    final regex = RegExp(r'\[EMOTION\](.*?)\[/EMOTION\]', dotAll: true);
    final match = regex.firstMatch(text);
    if (match == null) return null;

    try {
      final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      return EmotionData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String _removeEmotionTag(String text) {
    return text
        .replaceAll(RegExp(r'\[EMOTION\].*?\[/EMOTION\]', dotAll: true), '')
        .trim();
  }

  /// [DECISION]메뉴명[/DECISION] 태그에서 결정 내용 파싱
  String? _parseDecision(String text) {
    final regex = RegExp(r'\[DECISION\](.*?)\[/DECISION\]', dotAll: true);
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final decision = match.group(1)?.trim();
    return (decision != null && decision.isNotEmpty) ? decision : null;
  }

  String _removeDecisionTag(String text) {
    return text
        .replaceAll(
            RegExp(r'\[DECISION\].*?\[/DECISION\]', dotAll: true), '')
        .trim();
  }

  /// 모드 B 준비 (인사 메시지 대신 분석 중 표시)
  void startModeB() {
    final loadingMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '메뉴판을 분석하고 있어요... 📸',
    );

    state = ChatState(
      sessionId: _uuid.v4(),
      startTime: DateTime.now(),
      mode: ChatMode.modeB,
      messages: [loadingMessage],
    );
  }

  /// 모드 B 분석 완료 (메뉴 결과 표시)
  void completeModeB(String menuSummary) {
    final menuMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '메뉴판 분석을 완료했어요!\n\n$menuSummary',
    );

    final guideMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '취향을 알려주시면 이 메뉴 중에서 딱 맞는 걸 추천해드릴게요!',
    );

    final updatedHistory = [
      {
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': '메뉴판 분석 완료. 메뉴 목록:\n$menuSummary'},
        ],
      },
    ];

    state = state.copyWith(
      messages: [menuMessage, guideMessage],
      apiHistory: updatedHistory,
    );
  }

  /// 결정 확정
  void confirmDecision(String decision) {
    state = state.copyWith(decision: decision);
  }

  /// 디버그용: 테스트 오디오를 API로 전송
  Future<void> sendTestAudio(String audioBase64) async {
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: '🎙️ [테스트 음성]',
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
    );

    await _streamResponse(
      stream: _repository.sendVoiceMessage(
        audioBase64: audioBase64,
        history: state.apiHistory,
        mode: state.mode,
      ),
    );
  }

  /// 세션 리셋
  void resetSession() {
    state = ChatState(
      sessionId: _uuid.v4(),
      startTime: DateTime.now(),
    );
    _addAssistantGreeting();
  }
}
