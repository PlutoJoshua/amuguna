import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final String? lastUserText;
  final double currentAmplitude;
  final int recordingDurationSeconds;
  final List<String> quickReplies;

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
    this.lastUserText,
    this.currentAmplitude = -160.0,
    this.recordingDurationSeconds = 0,
    this.quickReplies = const [],
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
    String? lastUserText,
    double? currentAmplitude,
    int? recordingDurationSeconds,
    List<String>? quickReplies,
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
      lastUserText: lastUserText ?? this.lastUserText,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      recordingDurationSeconds:
          recordingDurationSeconds ?? this.recordingDurationSeconds,
      quickReplies: quickReplies ?? this.quickReplies,
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
  StreamSubscription<double>? _amplitudeSub;
  Timer? _recordingTimer;
  bool _disposed = false;

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
    _addAssistantGreeting();
  }

  @override
  void dispose() {
    _disposed = true;
    _amplitudeSub?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
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
    // 마이크 권한 요청
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        text: '마이크 권한이 필요해요. 설정에서 마이크를 허용해주세요.',
        isError: true,
      );
      state = state.copyWith(messages: [...state.messages, errorMsg]);
      return;
    }

    try {
      await _recorder.startRecording();
      state = state.copyWith(
        isRecording: true,
        quickReplies: [],
        recordingDurationSeconds: 0,
        currentAmplitude: -160.0,
      );

      // amplitude 구독
      _amplitudeSub = _recorder.amplitudeStream.listen((db) {
        if (!_disposed) {
          state = state.copyWith(currentAmplitude: db);
        }
      });

      // 녹음 시간 타이머
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_disposed) {
          state = state.copyWith(
            recordingDurationSeconds: state.recordingDurationSeconds + 1,
          );
        }
      });
    } catch (e) {
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        text: '녹음을 시작할 수 없어요. 다시 시도해주세요.',
        isError: true,
      );
      state = state.copyWith(messages: [...state.messages, errorMsg]);
    }
  }

  Future<void> _stopAndSend() async {
    _amplitudeSub?.cancel();
    _recordingTimer?.cancel();
    state = state.copyWith(
      isRecording: false,
      currentAmplitude: -160.0,
      recordingDurationSeconds: 0,
    );
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
    // 퀵 리플라이 초기화
    state = state.copyWith(quickReplies: []);

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
      lastUserText: text,
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
      String errorMsg;
      if (e is KananaApiException) {
        errorMsg = '서버 연결에 문제가 생겼어요. (${e.statusCode})';
      } else if (e is TimeoutException) {
        errorMsg = '응답 시간이 초과됐어요.';
      } else {
        errorMsg = '네트워크 연결을 확인해주세요.';
      }
      _updateAssistantMessage(assistantId, errorMsg, isError: true);
      state = state.copyWith(isStreaming: false);
      return;
    }

    // content가 있으면 content 사용, 없으면 transcript 사용
    final displayText = latestContent.isNotEmpty
        ? latestContent
        : latestTranscript;

    // 감정 + 결정 + 퀵 리플라이 파싱
    final emotion = _parseEmotion(displayText);
    final parsedDecision = _parseDecision(displayText);
    final parsedQuickReplies = _parseQuickReplies(displayText);
    final cleanText = _removeQuickReplyTag(
        _removeDecisionTag(_removeEmotionTag(displayText)));

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
      quickReplies: parsedQuickReplies,
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
    bool isError = false,
  }) {
    final messages = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(
          text: _removeEmotionTag(text),
          audioBase64: audioBase64,
          emotion: emotion,
          isError: isError,
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

  /// [QUICK_REPLY]옵션1|옵션2|옵션3[/QUICK_REPLY] 태그에서 빠른 답장 파싱
  List<String> _parseQuickReplies(String text) {
    final regex =
        RegExp(r'\[QUICK_REPLY\](.*?)\[/QUICK_REPLY\]', dotAll: true);
    final match = regex.firstMatch(text);
    if (match == null) return [];
    final raw = match.group(1)?.trim();
    if (raw == null || raw.isEmpty) return [];
    return raw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String _removeQuickReplyTag(String text) {
    return text
        .replaceAll(
            RegExp(r'\[QUICK_REPLY\].*?\[/QUICK_REPLY\]', dotAll: true), '')
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

  /// 마지막 메시지 재시도 (에러 메시지 제거 후 재전송)
  Future<void> retryLastMessage() async {
    final lastText = state.lastUserText;
    if (lastText == null) return;

    // 에러 메시지 제거
    final filtered = state.messages.where((m) => !m.isError).toList();
    state = state.copyWith(messages: filtered);

    await sendTextMessage(lastText);
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
