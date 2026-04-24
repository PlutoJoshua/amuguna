import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_recorder_service.dart';
import 'wav_encoder.dart';

AudioRecorderService createAudioRecorderService() =>
    MobileAudioRecorderService();

class MobileAudioRecorderService implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  RecordingState _state = RecordingState.idle;
  @override
  RecordingState get state => _state;

  final _stateController = StreamController<RecordingState>.broadcast();
  @override
  Stream<RecordingState> get stateStream => _stateController.stream;

  final _amplitudeController = StreamController<double>.broadcast();
  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  String? _currentPath;
  StreamSubscription? _amplitudeSub;

  @override
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  @override
  Future<void> startRecording() async {
    // 이전 녹음 상태가 남아 있으면 강제로 정리하고 재시작한다.
    // (이전 세션의 400 에러 등으로 record 패키지가 멎은 경우 대비)
    if (_state != RecordingState.idle) {
      _amplitudeSub?.cancel();
      try {
        if (await _recorder.isRecording()) {
          await _recorder.cancel();
        } else {
          await _recorder.stop();
        }
      } catch (_) {}
      _state = RecordingState.idle;
      _stateController.add(_state);
    }

    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.pcm';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _currentPath!,
    );

    _state = RecordingState.recording;
    _stateController.add(_state);

    _startSilenceDetection();
  }

  @override
  Future<String?> stopRecording() async {
    if (_state != RecordingState.recording) return null;

    _state = RecordingState.processing;
    _stateController.add(_state);

    _amplitudeSub?.cancel();

    try {
      await _recorder.stop();
    } catch (e) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

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

    final Uint8List pcmData;
    try {
      pcmData = await pcmFile.readAsBytes();
    } catch (e) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    // 너무 짧은 녹음은 무시 (0.5초 미만 = 16000 bytes)
    if (pcmData.length < 16000) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      try {
        await pcmFile.delete();
      } catch (_) {}
      return null;
    }

    final wavData = WavEncoder.encode(pcmData);
    final base64Wav = base64Encode(wavData);

    try {
      await pcmFile.delete();
    } catch (_) {}

    _state = RecordingState.idle;
    _stateController.add(_state);

    return base64Wav;
  }

  void _startSilenceDetection() {
    int silentFrames = 0;
    const silenceThresholdDb = -40.0;
    const silenceDurationFrames = 8; // ~2초 (250ms 간격)

    _amplitudeSub =
        _recorder.onAmplitudeChanged(const Duration(milliseconds: 250)).listen(
      (amp) {
        final db = amp.current;
        _amplitudeController.add(db);

        if (db < silenceThresholdDb) {
          silentFrames++;
          if (silentFrames >= silenceDurationFrames) {
            stopRecording();
          }
        } else {
          silentFrames = 0;
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    _amplitudeSub?.cancel();
    await _stateController.close();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
