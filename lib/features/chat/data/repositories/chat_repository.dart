import 'dart:async';

import '../../../../core/network/kanana_client.dart';
import '../models/chat_message.dart';
import '../prompts/mode_a_prompt.dart';
import '../prompts/mode_b_prompt.dart';

class ChatRepository {
  final KananaClient _client;

  ChatRepository({required KananaClient client}) : _client = client;

  /// 음성 메시지로 대화 (스트리밍).
  ///
  /// 음성 모달리티에서는 시스템 프롬프트의 페르소나/태그 출력 지시가 약하게 적용되는
  /// 경향이 있어, 매 호출마다 짧은 텍스트 reminder를 audio와 함께 같은 user 메시지로
  /// 묶어 보낸다.
  Stream<KananaStreamChunk> sendVoiceMessage({
    required String audioBase64,
    required List<Map<String, dynamic>> history,
    required ChatMode mode,
  }) {
    final messages = _buildMessages(
      history: history,
      mode: mode,
      currentContent: [
        {
          'type': 'input_audio',
          'input_audio': {'data': audioBase64, 'format': 'wav'},
        },
        {
          'type': 'text',
          'text': _voiceReminder,
        },
      ],
    );

    return _client.chatCompletionStream(
      messages: messages,
      includeAudio: true,
    );
  }

  static const _voiceReminder = '''(시스템 리마인더 — 음성으로 읽지 마)
응답: 2-3문장, 친한 카톡 톤, 메뉴 최대 2개. 카테고리 나열 금지, 질문은 한 번에 하나만.''';

  /// 텍스트 메시지로 대화 (스트리밍, 텍스트만 응답)
  Stream<KananaStreamChunk> sendTextMessage({
    required String text,
    required List<Map<String, dynamic>> history,
    required ChatMode mode,
  }) {
    final messages = _buildMessages(
      history: history,
      mode: mode,
      currentContent: [
        {'type': 'text', 'text': text},
      ],
    );

    return _client.chatCompletionStream(
      messages: messages,
      includeAudio: false,
    );
  }

  /// 메인 호출이 USER_HEARD를 빠뜨렸을 때만 호출되는 받아쓰기 전용 폴백.
  /// 단일 목적이라 모델이 다른 작업과 섞이지 않아 신뢰도가 높다.
  /// 다른 메타(INTENT/EMOTION/DECISION)는 룰베이스로 클라이언트에서 추출한다.
  Future<String> transcribeVoice(String audioBase64) {
    final messages = [
      {
        'role': 'system',
        'content':
            '한국어 음성을 듣고 그대로 받아 적어. 다른 말 금지. 출력은 받아 적은 한국어 문장 한 줄만.',
      },
      {
        'role': 'user',
        'content': [
          {
            'type': 'input_audio',
            'input_audio': {'data': audioBase64, 'format': 'wav'},
          },
          {
            'type': 'text',
            'text': '받아 적은 한국어 문장만 한 줄로:',
          },
        ],
      },
    ];
    return _client.chatCompletion(messages: messages);
  }

  /// 메뉴판 이미지 분석 (비스트리밍, 여러 장 지원)
  Future<String> analyzeMenu(List<String> imageBase64List) {
    final imageContents = imageBase64List.map((img) => {
          'type': 'image_url',
          'image_url': {'url': img},
        }).toList();

    final messages = [
      {
        'role': 'user',
        'content': [
          ...imageContents,
          {
            'type': 'text',
            'text': '''${imageBase64List.length > 1 ? '이 메뉴판 사진 ${imageBase64List.length}장을 종합해서' : '이 메뉴판을'} 분석해서 아래 두 가지를 알려줘.

1. 이 식당의 특징을 한줄로 요약 (예: "한식 중심의 가정식 백반집", "매운 요리가 많은 중식당")

2. 메뉴를 특성별로 분류해서 요약 (아래 형식으로)

🔥 매운 메뉴: 김치찌개, 제육볶음
🍲 따뜻한 국물: 된장찌개, 순두부
🥩 고기/구이류: 삼겹살, 불고기
🥗 가벼운 메뉴: 비빔밥, 샐러드
🍜 면류: 칼국수, 잔치국수

해당하는 특성만 쓰고, 메뉴가 없는 특성은 생략해.
가격 정보가 보이면 메뉴명 뒤에 (8,000원) 형태로 붙여줘.''',
          },
        ],
      },
    ];

    return _client.chatCompletion(messages: messages);
  }

  List<Map<String, dynamic>> _buildMessages({
    required List<Map<String, dynamic>> history,
    required ChatMode mode,
    required List<Map<String, dynamic>> currentContent,
  }) {
    final systemPrompt = mode == ChatMode.modeA
        ? modeASystemPrompt
        : modeBSystemPrompt;

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': currentContent},
    ];

    // 16K 컨텍스트 제한 대응: 히스토리가 너무 길면 최근 4턴만 유지
    if (history.length > 8) {
      final trimmedHistory = history.sublist(history.length - 8);
      return [
        {'role': 'system', 'content': systemPrompt},
        ...trimmedHistory,
        {'role': 'user', 'content': currentContent},
      ];
    }

    return messages;
  }
}
