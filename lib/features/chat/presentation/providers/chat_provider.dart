import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/audio/audio_player_service.dart';
import '../../../../core/audio/audio_recorder_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/kanana_client.dart';
import '../../../../core/services/user_preferences_service.dart';
import '../../../debug_log/data/models/debug_log_entry.dart';
import '../../../debug_log/presentation/providers/debug_log_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/meta_extractor.dart';

// --- Providers ---

/// UserPreferencesService 싱글턴
final userPreferencesServiceProvider = Provider<UserPreferencesService>(
  (ref) => UserPreferencesService(),
);

/// 앱 부팅 시 `main()`에서 override로 초기값 주입.
/// Settings 화면에서 키 변경 시 notifier.state를 갱신하면
/// `kananaClientProvider`가 자동으로 새 클라이언트를 만든다.
final userApiKeyProvider = StateProvider<String?>((ref) => null);

/// 사용 가능한 API 키. 사용자 입력 키 → dart-define 키 → 빈 문자열 순으로 fallback.
/// 빈 문자열이면 키 미설정 (라우팅 가드가 설정 화면으로 보낸다).
final effectiveApiKeyProvider = Provider<String>((ref) {
  final userKey = ref.watch(userApiKeyProvider);
  if (userKey != null && userKey.isNotEmpty) return userKey;
  return ApiConfig.dartDefineApiKey;
});

final kananaClientProvider = Provider<KananaClient>((ref) {
  final apiKey = ref.watch(effectiveApiKeyProvider);
  final client = KananaClient(
    baseUrl: ApiConfig.baseUrl,
    apiKey: apiKey,
  );
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
    addDebugLog: (entry) =>
        ref.read(debugLogProvider.notifier).add(entry),
    updateDebugLogMeta: ({
      required sessionId,
      required turnIndex,
      userTranscript,
      intent,
      emotion,
      decision,
      quickReplies,
      metaBlock,
    }) =>
        ref.read(debugLogProvider.notifier).updateLast(
              sessionId: sessionId,
              turnIndex: turnIndex,
              userTranscript: userTranscript,
              intent: intent,
              emotion: emotion,
              decision: decision,
              quickReplies: quickReplies,
              metaBlock: metaBlock,
            ),
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
  /// Mode B에서 분석한 메뉴판 첫 장의 썸네일 바이트(채팅 상단 표시용)
  final Uint8List? menuThumbnail;
  /// Mode B에서 사용자가 업로드한 메뉴판 사진 수
  final int menuPhotoCount;

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
    this.menuThumbnail,
    this.menuPhotoCount = 0,
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
    Uint8List? menuThumbnail,
    int? menuPhotoCount,
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
      menuThumbnail: menuThumbnail ?? this.menuThumbnail,
      menuPhotoCount: menuPhotoCount ?? this.menuPhotoCount,
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
  final void Function(DebugLogEntry)? addDebugLog;
  final void Function({
    required String sessionId,
    required int turnIndex,
    String? userTranscript,
    String? intent,
    EmotionData? emotion,
    String? decision,
    List<String>? quickReplies,
    String? metaBlock,
  })? updateDebugLogMeta;
  static const _uuid = Uuid();
  StreamSubscription<double>? _amplitudeSub;
  Timer? _recordingTimer;
  bool _disposed = false;

  // 디버그 로그 빌드용으로 직전 입력의 메타데이터를 임시 보관
  bool _lastInputWasVoice = false;
  int? _lastAudioBytes;
  double? _lastAudioSeconds;
  String? _lastInputText;
  // 폴백 호출용으로 마지막 audio base64 보관
  String? _lastAudioBase64;

  ChatNotifier({
    required ChatRepository repository,
    required AudioRecorderService recorder,
    required AudioPlayerService player,
    this.addDebugLog,
    this.updateDebugLogMeta,
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
    // 마이크 권한 요청 (record 패키지가 플랫폼별로 처리)
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
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

      // 녹음 시간 타이머 + Kanana-o 60초 제한에 여유를 두고 50초에 자동 중지
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (_disposed) return;
        final next = state.recordingDurationSeconds + 1;
        state = state.copyWith(recordingDurationSeconds: next);
        if (next >= 50 && state.isRecording) {
          debugPrint('Auto-stop: 50s hard limit reached');
          await _stopAndSend();
        }
      });
    } catch (e, st) {
      debugPrint('startRecording failed: $e\n$st');
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
    if (audioBase64 == null) {
      debugPrint('[VOICE] stopRecording returned null (too short or device error)');
      return;
    }
    // 디버그: 실제로 보낸 오디오 크기 (디코드 후 PCM 바이트수 추정)
    final approxPcmBytes = (audioBase64.length * 3 / 4).round() - 44; // wav header 차감
    final approxSeconds = approxPcmBytes / (16000 * 2);
    debugPrint(
      '[VOICE] Sending audio: base64=${audioBase64.length}B, '
      '~${approxPcmBytes}B PCM, ~${approxSeconds.toStringAsFixed(1)}s',
    );

    // 디버그 로그용 입력 메타 보관 + 폴백용 오디오 캐시
    _lastInputWasVoice = true;
    _lastAudioBytes = approxPcmBytes;
    _lastAudioSeconds = approxSeconds;
    _lastInputText = null;
    _lastAudioBase64 = audioBase64;

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
    // 디버그 로그용 입력 메타
    _lastInputWasVoice = false;
    _lastAudioBytes = null;
    _lastAudioSeconds = null;
    _lastInputText = text;
    _lastAudioBase64 = null;
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
          } catch (e) {
            debugPrint('Audio chunk decode failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Stream error: $e');
      String errorMsg;
      if (e is KananaApiException) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          errorMsg = 'API 키가 유효하지 않아요. 설정에서 다시 입력해주세요.';
        } else if (e.statusCode == 429) {
          errorMsg = 'API 호출 한도에 도달했어요. 잠시 후 다시 시도해주세요.';
        } else {
          errorMsg = '서버 연결에 문제가 생겼어요. (${e.statusCode})';
        }
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
    final rawText = latestContent.isNotEmpty
        ? latestContent
        : latestTranscript;

    debugPrint('[AI RAW] ${rawText.replaceAll('\n', ' | ')}');

    // 본문/메타 분리: 모델이 마커 형식을 자주 변형하므로 너그럽게 매치한다.
    //   ---META---, --- | META |, --META--, *** META *** 등 모두 인식
    //   `META`라는 단어가 dash/pipe/공백으로 둘러싸인 형태면 분리자로 본다.
    final metaMarkerRegex =
        RegExp(r'\n?[\s\-\|\*]{2,}\s*META\s*[\s\-\|\*]{1,}\s*\n?');
    final metaSplit = rawText.split(metaMarkerRegex);
    final bodyPart = metaSplit.first;
    final metaPart = metaSplit.length > 1 ? metaSplit.sublist(1).join('\n') : '';

    final emotion = _parseEmotion(metaPart.isNotEmpty ? metaPart : rawText);
    final parsedDecision =
        _parseDecision(metaPart.isNotEmpty ? metaPart : rawText);
    final parsedQuickReplies =
        _parseQuickReplies(metaPart.isNotEmpty ? metaPart : rawText);
    final parsedUserHeard =
        _parseUserHeard(metaPart.isNotEmpty ? metaPart : rawText);
    final parsedIntent =
        _parseIntent(metaPart.isNotEmpty ? metaPart : rawText);

    // 사용자에게 보여줄 본문은 메타 마커 이전 부분, 거기서도 잔여 태그는 제거
    final cleanText = _stripAllTags(bodyPart).trim();

    debugPrint(
      '[PARSED] userHeard=$parsedUserHeard | intent=$parsedIntent | '
      'emotion=${emotion != null ? "ok" : "null"} | decision=$parsedDecision | '
      'metaSeparated=${metaPart.isNotEmpty}',
    );

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

    // 직전 user 메시지가 음성 placeholder('🎙️ 음성 메시지')라면
    // 받아쓰기 결과(USER_HEARD)로 업데이트한다.
    final messagesWithTranscript = [...state.messages];
    if (parsedUserHeard != null) {
      for (var i = messagesWithTranscript.length - 1; i >= 0; i--) {
        final m = messagesWithTranscript[i];
        if (m.role == MessageRole.user) {
          if (m.transcript == null) {
            messagesWithTranscript[i] = m.copyWith(transcript: parsedUserHeard);
          }
          break;
        }
      }
    }

    // 최종 assistant 메시지 업데이트 (intent 포함)
    final finalMessages = messagesWithTranscript.map((m) {
      if (m.id == assistantId) {
        return m.copyWith(
          text: cleanText,
          audioBase64: audioData,
          emotion: emotion,
          intent: parsedIntent,
        );
      }
      return m;
    }).toList();

    // API 히스토리 업데이트 (텍스트만)
    // 사용자 음성 발화도 텍스트로 history에 쌓아야 다음 턴 모델이 이전 발화를 본다.
    // - 메인 응답에서 USER_HEARD가 잡혔으면 그 텍스트
    // - 아니면 placeholder ("[음성 입력]"). 받아쓰기 폴백 끝나면 _runTranscribeFallback이 교체.
    final userHistoryEntry = _lastInputWasVoice
        ? {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': parsedUserHeard ?? '[음성 입력]',
              },
            ],
          }
        : null;
    final updatedHistory = [
      ...state.apiHistory,
      if (userHistoryEntry != null) userHistoryEntry,
      {
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': cleanText},
        ],
      },
    ];

    state = state.copyWith(
      messages: finalMessages,
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

    // 디버그 로그 적재
    addDebugLog?.call(DebugLogEntry(
      sessionId: state.sessionId,
      turnIndex: state.turnCount,
      timestamp: DateTime.now(),
      mode: state.mode,
      wasVoice: _lastInputWasVoice,
      audioBytes: _lastAudioBytes,
      audioSeconds: _lastAudioSeconds,
      userText: _lastInputText,
      userTranscript: parsedUserHeard,
      rawResponse: rawText,
      body: cleanText,
      metaBlock: metaPart.isNotEmpty ? metaPart.trim() : null,
      intent: parsedIntent,
      emotion: emotion,
      decision: parsedDecision,
      quickReplies: parsedQuickReplies,
      metaSeparated: metaPart.isNotEmpty,
    ));

    // 오디오 자동 재생
    if (audioData != null) {
      try {
        await _player.playBase64Audio(audioData);
      } catch (e) {
        debugPrint('Auto-play audio failed: $e');
      }
    }

    // ─── 룰베이스 보강: 모델이 안 줘도 본문/발화 텍스트로 추출 ───
    // 1) EMOTION: AI 응답 본문에 "지쳐 보이네" 같은 미러링 키워드가 있으면 추출
    if (emotion == null) {
      final ruled = MetaExtractor.extractEmotionFromBody(cleanText);
      if (ruled != null) {
        debugPrint('[RULE] Emotion extracted from body');
        // state는 아래에서 한 번에 갱신
        _applyMetaSupplement(
          assistantId: assistantId,
          ruleEmotion: ruled,
        );
      }
    }
    // 2) INTENT: 사용자 발화로부터
    if (parsedIntent == null) {
      final src = parsedUserHeard ?? _lastInputText ?? '';
      final ruled = MetaExtractor.extractIntent(src);
      if (ruled != null) {
        debugPrint('[RULE] Intent extracted: $ruled');
        updateDebugLogMeta?.call(
          sessionId: state.sessionId,
          turnIndex: state.turnCount - 1,
          intent: ruled,
        );
      }
    }
    // 3) DECISION: 사용자 확정 키워드 + 메뉴 사전
    // 최소 2턴 이상 진행돼야 룰베이스 결정 판정 (첫 턴에 오탐 방지)
    if (parsedDecision == null && state.turnCount >= 2) {
      final src = parsedUserHeard ?? _lastInputText ?? '';
      final ruled = MetaExtractor.extractDecision(
        userText: src,
        latestAiBody: cleanText,
      );
      if (ruled != null) {
        debugPrint('[RULE] Decision extracted: $ruled');
        state = state.copyWith(decision: ruled);
        updateDebugLogMeta?.call(
          sessionId: state.sessionId,
          turnIndex: state.turnCount - 1,
          decision: ruled,
        );
      }
    }

    // ─── USER_HEARD가 없으면 단순 받아쓰기 폴백 1회 ───
    // 받아쓰기는 단일 목적이라 모델이 잘 따른다. INTENT/EMOTION은 위 룰베이스로 처리.
    if (_lastInputWasVoice &&
        parsedUserHeard == null &&
        _lastAudioBase64 != null) {
      _runTranscribeFallback(
        audioBase64: _lastAudioBase64!,
        sessionId: state.sessionId,
        turnIndex: state.turnCount - 1,
      );
    }
  }

  /// 메인 응답 후 룰베이스로 추출한 메타를 메시지/상태/디버그 로그에 반영.
  void _applyMetaSupplement({
    required String assistantId,
    EmotionData? ruleEmotion,
  }) {
    if (ruleEmotion == null) return;
    final updated = state.messages.map((m) {
      if (m.id == assistantId && m.emotion == null) {
        return m.copyWith(emotion: ruleEmotion);
      }
      return m;
    }).toList();
    state = state.copyWith(
      messages: updated,
      currentEmotion: state.currentEmotion ?? ruleEmotion,
      emotionHistory: state.emotionHistory.isEmpty
          ? [ruleEmotion]
          : state.emotionHistory,
    );
    updateDebugLogMeta?.call(
      sessionId: state.sessionId,
      turnIndex: state.turnCount - 1,
      emotion: ruleEmotion,
    );
  }

  /// 받아쓰기(USER_HEARD) 누락 시에만 호출되는 단순 단일 목적 폴백.
  /// 받아쓴 한국어 문장 한 줄만 받음 → 해당 결과로 INTENT/DECISION 룰베이스 재실행.
  Future<void> _runTranscribeFallback({
    required String audioBase64,
    required String sessionId,
    required int turnIndex,
  }) async {
    try {
      final raw = await _repository.transcribeVoice(audioBase64);
      debugPrint('[TRANSCRIBE FALLBACK RAW] ${raw.replaceAll('\n', ' | ')}');

      // 모델이 가끔 응답 끝에 마침표/줄바꿈 등 잡스러운 거 붙임 → 한 줄만 깔끔히
      final transcript = raw.split('\n').first.trim().replaceAll('"', '');
      if (transcript.isEmpty) return;

      // 직전 user 메시지의 transcript 반영
      final updated = state.messages.map((m) => m).toList();
      for (var i = updated.length - 1; i >= 0; i--) {
        final m = updated[i];
        if (m.role == MessageRole.user) {
          if (m.transcript == null) {
            updated[i] = m.copyWith(transcript: transcript);
          }
          break;
        }
      }

      // apiHistory에 들어간 '[음성 입력]' placeholder를 실제 transcript로 교체.
      // 다음 턴 모델 호출 시 이전 발화를 정확히 보게 된다.
      final newHistory = [...state.apiHistory];
      for (var i = newHistory.length - 1; i >= 0; i--) {
        final entry = newHistory[i];
        if (entry['role'] == 'user') {
          final content = entry['content'];
          if (content is List && content.isNotEmpty) {
            final first = content.first;
            if (first is Map &&
                first['type'] == 'text' &&
                first['text'] == '[음성 입력]') {
              newHistory[i] = {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': transcript},
                ],
              };
            }
          }
          break;
        }
      }
      state = state.copyWith(messages: updated, apiHistory: newHistory);

      // 받아쓰기 결과로 INTENT/DECISION 룰베이스 재시도
      final ruledIntent = MetaExtractor.extractIntent(transcript);
      String? ruledDecision;
      if (state.turnCount >= 2) {
        final lastAiBody = state.messages.reversed
            .firstWhere(
              (m) => m.role == MessageRole.assistant && m.text.isNotEmpty,
              orElse: () => state.messages.first,
            )
            .text;
        ruledDecision = MetaExtractor.extractDecision(
          userText: transcript,
          latestAiBody: lastAiBody,
        );
      }

      updateDebugLogMeta?.call(
        sessionId: sessionId,
        turnIndex: turnIndex,
        userTranscript: transcript,
        intent: ruledIntent,
        decision: ruledDecision,
        metaBlock: '[TRANSCRIBE_FALLBACK]\n$transcript',
      );
      if (ruledDecision != null) {
        state = state.copyWith(decision: ruledDecision);
      }
    } catch (e) {
      debugPrint('[TRANSCRIBE FALLBACK] Failed: $e');
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
          text: _stripAllTags(text),
          audioBase64: audioBase64,
          emotion: emotion,
          isError: isError,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(messages: messages);
  }

  /// 태그 본문 추출. 모델이 닫는 태그(`[/TAG]`)를 빠뜨리는 경우가 잦아
  /// 1순위로 닫는 태그 형식, 2순위로 다음 `[` 또는 `|` 구분자 직전까지를 본문으로 본다.
  String? _extractTagBody(String text, String tagName) {
    final closed = RegExp(
      r'\[' + tagName + r'\](.*?)\[/' + tagName + r'\]',
      dotAll: true,
    );
    final m1 = closed.firstMatch(text);
    if (m1 != null) {
      final v = m1.group(1)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    // 폴백: [TAG]부터 다음 [ 또는 | 또는 끝까지
    final open = RegExp(
      r'\[' + tagName + r'\]\s*([^\[\|]*)',
      dotAll: true,
    );
    final m2 = open.firstMatch(text);
    final v = m2?.group(1)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// [EMOTION]{...}[/EMOTION] 태그에서 감정 데이터 파싱
  EmotionData? _parseEmotion(String text) {
    final body = _extractTagBody(text, 'EMOTION');
    if (body == null) return null;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return EmotionData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// [DECISION]메뉴명[/DECISION] 태그에서 결정 내용 파싱.
  /// "아직 못 정했어" 같은 비결정 문구는 null 처리.
  String? _parseDecision(String text) {
    final body = _extractTagBody(text, 'DECISION');
    if (body == null) return null;
    final isUnresolved = body.contains('아직') ||
        body.contains('못 정') ||
        body.contains('같이 골라') ||
        body.length > 30;
    return isUnresolved ? null : body;
  }

  /// [QUICK_REPLY] 태그를 모두 모아 답변 후보 리스트 구성.
  /// 모델이 [QUICK_REPLY]A|B|C 한 줄 vs 여러 [QUICK_REPLY] 블록 둘 다 보내므로 모두 처리.
  List<String> _parseQuickReplies(String text) {
    final all = RegExp(
      r'\[QUICK_REPLY\]\s*([^\[]*)',
      dotAll: true,
    ).allMatches(text);
    final result = <String>[];
    for (final m in all) {
      final raw = m.group(1)?.trim() ?? '';
      // 닫는 태그가 본문에 섞여있으면 잘라냄
      final cleaned = raw.replaceAll(RegExp(r'\[/?QUICK_REPLY\]'), '').trim();
      if (cleaned.isEmpty) continue;
      for (final piece in cleaned.split('|')) {
        final p = piece.trim();
        if (p.isNotEmpty && !result.contains(p)) result.add(p);
      }
    }
    return result.take(4).toList(); // UI 부담 방지
  }

  /// [USER_HEARD]사용자가 한 말[/USER_HEARD] — 음성 입력 받아쓰기
  String? _parseUserHeard(String text) => _extractTagBody(text, 'USER_HEARD');

  /// [INTENT]의도 한 줄 요약[/INTENT]
  String? _parseIntent(String text) => _extractTagBody(text, 'INTENT');

  /// 메시지 본문에서 모든 메타 태그 + 그 본문 제거.
  /// 닫는 태그가 없는 케이스도 대응하여 `[TAG] ... 다음[TAG_OR_END]`까지 한 번에 잘라낸다.
  String _stripAllTags(String text) {
    var result = text;
    const tags = [
      'EMOTION',
      'DECISION',
      'QUICK_REPLY',
      'USER_HEARD',
      'INTENT',
    ];
    for (final t in tags) {
      // 닫는 태그가 있으면 그것까지
      result = result.replaceAll(
        RegExp(r'\[' + t + r'\].*?\[/' + t + r'\]', dotAll: true),
        '',
      );
      // 닫는 태그 없는 잔여는 [TAG]부터 다음 [ 또는 줄 끝까지
      result = result.replaceAll(
        RegExp(r'\[' + t + r'\][^\[]*', dotAll: true),
        '',
      );
    }
    // 잔여 파이프/공백 정리
    result = result.replaceAll(RegExp(r'\s*\|\s*'), ' ').trim();
    return result;
  }

  /// 모드 B 준비 (인사 메시지 대신 분석 중 표시).
  /// 메뉴판 썸네일과 사진 수를 받아 채팅 상단에 표시한다.
  void startModeB({
    Uint8List? menuThumbnail,
    int photoCount = 0,
  }) {
    final loadingMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      text: '메뉴판을 확인하고 있어요... 📸',
    );

    state = ChatState(
      sessionId: _uuid.v4(),
      startTime: DateTime.now(),
      mode: ChatMode.modeB,
      messages: [loadingMessage],
      menuThumbnail: menuThumbnail,
      menuPhotoCount: photoCount,
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
