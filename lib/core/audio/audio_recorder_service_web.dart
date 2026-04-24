import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'audio_recorder_service.dart';

AudioRecorderService createAudioRecorderService() =>
    WebAudioRecorderService();

class WebAudioRecorderService implements AudioRecorderService {
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

  StreamSubscription? _amplitudeSub;
  StreamSubscription? _recordSub;
  final List<Uint8List> _audioChunks = [];

  @override
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  @override
  Future<void> startRecording() async {
    // 이전 녹음 상태가 남아 있으면 강제로 정리하고 재시작
    if (_state != RecordingState.idle) {
      _amplitudeSub?.cancel();
      await _recordSub?.cancel();
      try {
        if (await _recorder.isRecording()) {
          await _recorder.cancel();
        }
      } catch (_) {}
      _audioChunks.clear();
      _state = RecordingState.idle;
      _stateController.add(_state);
    }

    _audioChunks.clear();

    // 웹에서는 WAV 인코더 사용 (브라우저 PCM 호환성 문제 회피)
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
    );

    _recordSub = stream.listen((data) {
      _audioChunks.add(data);
    });

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
    await _recordSub?.cancel();

    try {
      await _recorder.stop();
    } catch (e) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    if (_audioChunks.isEmpty) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    // 청크 합치기
    final totalLength =
        _audioChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final pcmData = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in _audioChunks) {
      pcmData.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _audioChunks.clear();

    // 너무 짧은 녹음은 무시 (0.5초 미만 = 16000 bytes)
    if (pcmData.length < 16000) {
      _state = RecordingState.idle;
      _stateController.add(_state);
      return null;
    }

    // PCM → WAV 헤더 추가
    final wavData = _encodePcmToWav(pcmData);
    final base64Wav = base64Encode(wavData);

    _state = RecordingState.idle;
    _stateController.add(_state);

    return base64Wav;
  }

  void _startSilenceDetection() {
    int silentFrames = 0;
    const silenceThresholdDb = -40.0;
    const silenceDurationFrames = 8;

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

  /// PCM 16-bit 데이터를 WAV로 변환 (WavEncoder와 동일한 로직, dart:io 의존 없음)
  Uint8List _encodePcmToWav(Uint8List pcmData) {
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const headerSize = 44;

    final dataSize = pcmData.length;
    final fileSize = headerSize + dataSize;
    final buffer = ByteData(fileSize);

    // RIFF header
    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, fileSize - 8, Endian.little);
    _writeString(buffer, 8, 'WAVE');

    // fmt sub-chunk
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, numChannels, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(
        28, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little);
    buffer.setUint16(32, numChannels * bitsPerSample ~/ 8, Endian.little);
    buffer.setUint16(34, bitsPerSample, Endian.little);

    // data sub-chunk
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    final wavBytes = buffer.buffer.asUint8List();
    wavBytes.setRange(headerSize, fileSize, pcmData);

    return wavBytes;
  }

  void _writeString(ByteData buffer, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  @override
  Future<void> dispose() async {
    _amplitudeSub?.cancel();
    await _recordSub?.cancel();
    await _stateController.close();
    await _amplitudeController.close();
    await _recorder.dispose();
  }
}
