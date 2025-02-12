import 'dart:typed_data';

import '../capnproto.dart';

extension ByteDataCapnp on ByteData {
  ByteData offsetBytes(int byteCount, [int? lengthBytes]) {
    assert(
      lengthBytes == null || lengthBytes >= 0 && lengthBytes <= lengthInBytes,
    );

    return buffer.asByteData(
      offsetInBytes + byteCount,
      lengthBytes ?? lengthInBytes - byteCount,
    );
  }

  ByteData offsetWords(int wordCount, [int? lengthWords]) {
    return offsetBytes(
      wordCount * CapnpConstants.bytesPerWord,
      lengthWords == null ? null : lengthWords * CapnpConstants.bytesPerWord,
    );
  }

  void zeroBytes(int offsetBytes, int lengthBytes) {
    buffer
        .asUint8List(offsetInBytes + offsetBytes, lengthBytes)
        .fillRange(0, lengthBytes, 0);
  }

  void zeroWords(int offsetWords, int lengthWords) {
    buffer
        .asUint64List(
          offsetInBytes + offsetWords * CapnpConstants.bytesPerWord,
          lengthWords,
        )
        .fillRange(0, lengthWords, 0);
  }

  void copyBytesTo(ByteData target, int lengthBytes) {
    target.buffer.asUint8List(target.offsetInBytes, lengthBytes).setRange(
          0,
          lengthBytes,
          buffer.asUint8List(offsetInBytes, lengthBytes),
        );
  }

  void copyWordsTo(ByteData target, int lengthWords) {
    target.buffer.asUint64List(target.offsetInBytes, lengthWords).setRange(
          0,
          lengthWords,
          buffer.asUint64List(offsetInBytes, lengthWords),
        );
  }
}
