import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  bool get isPlaying => _player.playing;

  Stream<bool> get playingStream => _player.playingStream;

  /// Base64 인코딩된 오디오 데이터를 재생 (Kanana-o 24kHz 응답)
  Future<void> playBase64Audio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      // Kanana-o 응답이 WAV인지 raw PCM인지 확인
      final wavBytes = _ensureWavFormat(bytes);
      await playBytes(wavBytes);
    } catch (e) {
      // 재생 실패 시 무시 (텍스트 응답은 이미 표시됨)
    }
  }

  Future<void> playBytes(Uint8List bytes) async {
    debugPrint('AudioPlayer: playing ${bytes.length} bytes, '
        'first 4: ${bytes.take(4).toList()}');
    final source = _BytesAudioSource(bytes);
    await _player.setAudioSource(source);
    await _player.play();
  }

  /// WAV 헤더가 없으면 24kHz mono PCM으로 간주하고 헤더를 붙인다
  Uint8List _ensureWavFormat(Uint8List bytes) {
    // WAV 파일은 "RIFF"로 시작
    if (bytes.length >= 4 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46) {
      // F
      return bytes; // 이미 WAV
    }

    // Raw PCM → WAV 24kHz mono 16-bit로 래핑
    return _wrapPcmAsWav(bytes, sampleRate: 24000);
  }

  Uint8List _wrapPcmAsWav(Uint8List pcmData, {required int sampleRate}) {
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
    buffer.setUint16(20, 1, Endian.little); // PCM
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

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}
