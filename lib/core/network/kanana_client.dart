import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

/// Kanana-o API 클라이언트 (OpenAI 호환)
class KananaClient {
  final String apiKey;
  final http.Client _httpClient = http.Client();

  KananaClient({required this.apiKey});

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
      Uri.parse('${ApiConfig.baseUrl}/chat/completions'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });
    request.body = jsonEncode(body);

    final response = await _httpClient.send(request);

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
          // RAW 로그: API 응답 구조 디버깅
          final choices = json['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'];
            final keys = (delta as Map?)?.keys.toList() ?? [];
            debugPrint('SSE delta keys: $keys');
          }
          final chunk = _parseChunk(json);
          if (chunk != null) yield chunk;
        } catch (_) {
          // 파싱 실패한 청크는 무시
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
      Uri.parse('${ApiConfig.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

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

    debugPrint('Chunk: content=${textDelta != null ? "${textDelta.length}ch" : "-"} '
        'transcript=${audioTranscript != null ? "${audioTranscript.length}ch" : "-"} '
        'audio=${audioDelta != null ? "${audioDelta.length}ch" : "-"}');

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
