import 'dart:async';

import 'audio_recorder_service_stub.dart'
    if (dart.library.io) 'audio_recorder_service_mobile.dart'
    if (dart.library.js_interop) 'audio_recorder_service_web.dart';

enum RecordingState { idle, recording, processing }

/// 플랫폼 독립 오디오 녹음 인터페이스
abstract class AudioRecorderService {
  RecordingState get state;
  Stream<RecordingState> get stateStream;
  Stream<double> get amplitudeStream;

  factory AudioRecorderService() => createAudioRecorderService();

  /// 마이크 권한 확인 및 요청
  Future<bool> hasPermission();

  /// 녹음 시작 (PCM 16kHz mono)
  Future<void> startRecording();

  /// 녹음 종료 → WAV Base64 반환
  Future<String?> stopRecording();

  Future<void> dispose();
}
