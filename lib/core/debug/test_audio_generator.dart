import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// 시뮬레이터 테스트용 샘플 WAV 생성기
class TestAudioGenerator {
  /// 간단한 사인파 WAV 생성 (재생 테스트용)
  /// [durationMs]: 밀리초 단위 길이
  /// [frequency]: Hz 단위 주파수 (기본 440Hz = A4음)
  static Uint8List generateSineWav({
    int durationMs = 1000,
    int sampleRate = 24000,
    double frequency = 440.0,
    double volume = 0.5,
  }) {
    const numChannels = 1;
    const bitsPerSample = 16;
    const headerSize = 44;

    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * numChannels * (bitsPerSample ~/ 8);
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

    // 사인파 PCM 데이터
    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * frequency * t) * volume * 32767).round();
      buffer.setInt16(headerSize + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// 테스트용 16kHz WAV (API 전송 테스트용)
  static String generateTestInputBase64() {
    final wav = generateSineWav(
      durationMs: 2000,
      sampleRate: 16000,
      frequency: 300.0,
      volume: 0.3,
    );
    return base64Encode(wav);
  }

  /// 테스트용 24kHz WAV (재생 테스트용)
  static Uint8List generateTestOutputWav() {
    return generateSineWav(
      durationMs: 1500,
      sampleRate: 24000,
      frequency: 440.0,
      volume: 0.4,
    );
  }

  static void _writeString(ByteData buffer, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
