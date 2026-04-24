import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

/// Kanana-o API 스트리밍 응답 청크
class KananaStreamChunk {
  final String? textDelta;       // delta.content (텍스트 응답)
  final String? audioDelta;      // delta.audio.data (오디오 바이너리)
  final String? audioTranscript; // delta.audio.transcript (오디오 전사)
  final bool isDone;

  const KananaStreamChunk({
    this.textDelta,
    this.audioDelta,
    this.audioTranscript,
    this.isDone = false,
  });
}

/// Kanana-o API 클라이언트 (OpenAI 호환).
///
/// 두 가지 호출 경로:
/// 1. **직접 호출** (네이티브 앱 전용): `baseUrl`이 Kanana-o 공식 엔드포인트.
///    `apiKey`가 반드시 필요.
/// 2. **프록시 경유** (웹 배포 + 네이티브도 가능):
///    `baseUrl`이 본 서비스 프록시. `apiKey`는 사용자가 입력한 키가 있으면
///    Authorization 헤더로 전달되고, 없으면 서버가 공용 키를 주입한다.
///
/// CORS 때문에 웹에서는 **반드시 프록시 경유** 방식만 동작한다.
class KananaClient {
  /// 요청을 보낼 베이스 URL. 뒤에 `/chat/completions`가 붙는다.
  /// 예:
  ///   직접: `https://kanana-o.a2s-endpoint.kr-central-2.kakaocloud.com/v1`
  ///   프록시: `https://<project>.web.app/api/kanana-proxy`
  final String baseUrl;

  /// Authorization Bearer 토큰으로 보낼 키. 비어있으면 헤더 생략.
  /// 프록시 경유 + 공용 키 모드일 때만 빈 문자열.
  final String apiKey;

  /// 서버 쿼터 카운터가 쓰는 익명 클라이언트 ID (X-Client-Id 헤더).
  final String? clientId;

  final http.Client _httpClient = http.Client();

  KananaClient({
    required this.baseUrl,
    required this.apiKey,
    this.clientId,
  });

  Map<String, String> _buildHeaders({required String contentType}) {
    final headers = <String, String>{
      'Content-Type': contentType,
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    if (clientId != null && clientId!.isNotEmpty) {
      headers['X-Client-Id'] = clientId!;
    }
    return headers;
  }

  /// Chat completion 스트리밍 호출
  Stream<KananaStreamChunk> chatCompletionStream({
    required List<Map<String, dynamic>> messages,
    bool includeAudio = true,
  }) async* {
    final body = <String, dynamic>{
      'model': ApiConfig.model,
      'messages': messages,
      'stream': true,
    };

    if (includeAudio) {
      body['modalities'] = ['text', 'audio'];
      body['audio'] = {'voice': ApiConfig.voicePreset};
    } else {
      body['modalities'] = ['text'];
    }

    // latency_first는 Kanana-o 전용 파라미터
    body['latency_first'] = true;

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/chat/completions'),
    );
    request.headers.addAll(_buildHeaders(contentType: 'application/json'));
    request.body = jsonEncode(body);

    final response = await _httpClient.send(request).timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw KananaApiException(
        statusCode: response.statusCode,
        message: errorBody,
      );
    }

    // SSE 스트리밍 파싱
    String buffer = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      // 마지막 줄은 불완전할 수 있으므로 버퍼에 보관
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed == 'data: [DONE]') {
          yield const KananaStreamChunk(isDone: true);
          return;
        }

        if (!trimmed.startsWith('data: ')) continue;

        final jsonStr = trimmed.substring(6);
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final chunk = _parseChunk(json);
          if (chunk != null) yield chunk;
        } catch (e) {
          // 파싱 실패한 청크 로깅 후 계속 진행
          // ignore: avoid_print
          print('SSE chunk parse failed: $e');
        }
      }
    }
  }

  /// 비스트리밍 호출 (텍스트만, 메뉴판 분석 등)
  Future<String> chatCompletion({
    required List<Map<String, dynamic>> messages,
  }) async {
    final body = {
      'model': ApiConfig.model,
      'messages': messages,
      'modalities': ['text'],
    };

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: _buildHeaders(contentType: 'application/json'),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw KananaApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    if (choices.isEmpty) return '';

    final message = choices[0]['message'] as Map<String, dynamic>;
    return message['content']?.toString() ?? '';
  }

  KananaStreamChunk? _parseChunk(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;

    final delta = choices[0]['delta'] as Map<String, dynamic>?;
    if (delta == null) return null;

    // 텍스트와 오디오를 분리해서 전달
    final textDelta = delta['content']?.toString();

    String? audioDelta;
    String? audioTranscript;
    final audioData = delta['audio'] as Map<String, dynamic>?;
    if (audioData != null) {
      audioDelta = audioData['data']?.toString();
      audioTranscript = audioData['transcript']?.toString();
    }

    if (textDelta == null && audioDelta == null && audioTranscript == null) {
      return null;
    }

    return KananaStreamChunk(
      textDelta: textDelta,
      audioDelta: audioDelta,
      audioTranscript: audioTranscript,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}

class KananaApiException implements Exception {
  final int statusCode;
  final String message;

  const KananaApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'KananaApiException($statusCode): $message';
}
