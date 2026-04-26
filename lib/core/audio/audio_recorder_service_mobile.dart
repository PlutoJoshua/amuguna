import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_recorder_service.dart';

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
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
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
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

    // record 패키지가 직접 WAV 헤더를 작성하게 한다(pcm16bits + 수동 헤더 조합은
    // macOS에서 sampleRate가 무시돼 헤더와 실제 데이터가 어긋났음).
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
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

    final wavFile = File(path);
    if (!await wavFile.exists()) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    final Uint8List wavData;
    try {
      wavData = await wavFile.readAsBytes();
    } catch (e) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    // WAV 헤더 44 bytes + 0.5초 분량(16000 bytes @ 16kHz mono 16bit) 미만이면 무시
    if (wavData.length < 44 + 16000) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      try {
        await wavFile.delete();
      } catch (_) {}
      return null;
    }

    final base64Wav = base64Encode(wavData);

    try {
      await wavFile.delete();
    } catch (_) {}

    _state = RecordingState.idle;
    _stateController.add(_state);

    return base64Wav;
  }

  void _startSilenceDetection() {
    int silentFrames = 0;
    const silenceThresholdDb = -40.0;
    const silenceDurationFrames = 8; // ~2초 (250ms 간격)

    // record 패키지의 onAmplitudeChanged는 single-subscription stream이라
    // 두 번째 녹음에서 같은 stream에 다시 listen하면 Bad state 예외가 난다.
    // 무음 자동 종료가 안 되어도 chat_provider의 50초 하드 리밋이 안전망 역할을 하므로
    // 여기서 실패해도 녹음 자체는 계속 진행시킨다.
    try {
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 250))
          .listen(
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
        onError: (Object e) {
          // 무음 감지만 비활성화. 녹음은 계속.
        },
      );
    } catch (e) {
      // 이미 listen된 stream이면 무음 감지 건너뛰고 녹음 계속.
    }
  }

  @override
  Future<void> dispose() async {
    _amplitudeSub?.cancel();
    await _stateController.close();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
