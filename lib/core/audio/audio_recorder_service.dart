import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'wav_encoder.dart';

enum RecordingState { idle, recording, processing }

class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  final _stateController = StreamController<RecordingState>.broadcast();
  Stream<RecordingState> get stateStream => _stateController.stream;

  final _amplitudeController = StreamController<double>.broadcast();
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  String? _currentPath;
  StreamSubscription? _dbSub;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 250));
    _isInitialized = true;
  }

  /// 녹음 시작 (PCM 16kHz mono)
  Future<void> startRecording() async {
    if (_state != RecordingState.idle) return;

    await _ensureInitialized();

    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.pcm';

    await _recorder.startRecorder(
      toFile: _currentPath,
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
    );

    _state = RecordingState.recording;
    _stateController.add(_state);

    _startSilenceDetection();
  }

  /// 녹음 종료 → WAV Base64 반환
  Future<String?> stopRecording() async {
    if (_state != RecordingState.recording) return null;

    _state = RecordingState.processing;
    _stateController.add(_state);

    _dbSub?.cancel();

    await _recorder.stopRecorder();

    final path = _currentPath;
    if (path == null) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    final pcmFile = File(path);
    if (!await pcmFile.exists()) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    final pcmData = await pcmFile.readAsBytes();

    // 너무 짧은 녹음은 무시 (0.5초 미만 = 16000 bytes)
    if (pcmData.length < 16000) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      await pcmFile.delete();
      return null;
    }

    final wavData = WavEncoder.encode(pcmData);
    final base64Wav = base64Encode(wavData);

    await pcmFile.delete();

    _state = RecordingState.idle;
    _stateController.add(_state);

    return base64Wav;
  }

  void _startSilenceDetection() {
    int silentFrames = 0;
    const silenceThresholdDb = -40.0;
    const silenceDurationFrames = 8; // ~2초 (250ms 간격)

    _dbSub = _recorder.onProgress?.listen((event) {
      final db = event.decibels ?? -160;
      _amplitudeController.add(db);

      if (db < silenceThresholdDb) {
        silentFrames++;
        if (silentFrames >= silenceDurationFrames) {
          stopRecording();
        }
      } else {
        silentFrames = 0;
      }
    });
  }

  Future<void> dispose() async {
    _dbSub?.cancel();
    await _stateController.close();
    await _amplitudeController.close();
    if (_isInitialized) {
      await _recorder.closeRecorder();
    }
  }
}
