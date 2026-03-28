import 'dart:typed_data';

/// PCM 16-bit 데이터를 WAV 파일 포맷으로 인코딩한다.
/// Kanana-o API는 16kHz mono WAV를 요구한다.
class WavEncoder {
  WavEncoder._();

  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bitsPerSample = 16;
  static const int _headerSize = 44;

  /// PCM Int16 바이트 데이터를 WAV 파일 바이트로 변환
  static Uint8List encode(Uint8List pcmData) {
    final dataSize = pcmData.length;
    final fileSize = _headerSize + dataSize;
    final buffer = ByteData(fileSize);

    // RIFF header
    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, fileSize - 8, Endian.little);
    _writeString(buffer, 8, 'WAVE');

    // fmt sub-chunk
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // Sub-chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM format
    buffer.setUint16(22, _numChannels, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(
      28,
      _sampleRate * _numChannels * _bitsPerSample ~/ 8,
      Endian.little,
    ); // Byte rate
    buffer.setUint16(
      32,
      _numChannels * _bitsPerSample ~/ 8,
      Endian.little,
    ); // Block align
    buffer.setUint16(34, _bitsPerSample, Endian.little);

    // data sub-chunk
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    // PCM data
    final wavBytes = buffer.buffer.asUint8List();
    wavBytes.setRange(_headerSize, fileSize, pcmData);

    return wavBytes;
  }

  static void _writeString(ByteData buffer, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      buffer.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
