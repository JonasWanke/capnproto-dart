import 'dart:typed_data';

import 'package:capnproto/src/objects/list.dart';
import 'package:capnproto/src/pointer.dart';

import 'constants.dart';
import 'message.dart';

class Segment {
  Segment(this.message, this.data)
      : assert(message != null),
        assert(data != null),
        assert(data.lengthInBytes % CapnpConstants.bytesPerWord == 0);

  final Message message;
  final ByteData data;
  int get lengthInBytes => data.lengthInBytes;

  SegmentView view(int offsetInWords, int lengthInWords) =>
      SegmentView._(this, offsetInWords, lengthInWords);
}

class SegmentView {
  SegmentView._(this.segment, this.offsetInWords, this.lengthInWords)
      : assert(segment != null),
        assert(offsetInWords != null),
        assert(offsetInWords >= 0),
        assert(lengthInWords != null),
        assert(lengthInWords >= 0),
        assert((offsetInWords + lengthInWords) * CapnpConstants.bytesPerWord <=
            segment.lengthInBytes),
        data = segment.data.buffer.asByteData(
          segment.data.offsetInBytes +
              offsetInWords * CapnpConstants.bytesPerWord,
          lengthInWords * CapnpConstants.bytesPerWord,
        );

  final Segment segment;
  final ByteData data;
  final int offsetInWords;
  int get offsetInBytes => offsetInWords * CapnpConstants.bytesPerWord;
  int get totalOffsetInBytes => segment.data.offsetInBytes + offsetInBytes;
  final int lengthInWords;
  int get lengthInBytes => lengthInWords * CapnpConstants.bytesPerWord;

  SegmentView subview(int offsetInWords, int lengthInWords) {
    assert(offsetInWords != null);
    assert(offsetInWords >= 0);
    assert(lengthInWords != null);
    assert(lengthInWords >= 0);
    assert(offsetInWords + lengthInWords <= this.lengthInWords);

    return SegmentView._(
      segment,
      this.offsetInWords + offsetInWords,
      lengthInWords,
    );
  }

  SegmentView viewRelativeToEnd(int offsetInWords, int lengthInWords) {
    assert(offsetInWords != null);
    assert(offsetInWords >= 0);
    assert(lengthInWords != null);
    assert(lengthInWords >= 0);

    return SegmentView._(
      segment,
      this.offsetInWords + this.lengthInWords + offsetInWords,
      lengthInWords,
    );
  }

  // TODO(JonasWanke): default values
  void getVoid(int offsetInBits) {}
  bool getBool(int offsetInBits) {
    final byte = data.getUint8(offsetInBits ~/ CapnpConstants.bitsPerByte);
    final bitIndex = offsetInBits % CapnpConstants.bitsPerByte;
    final bit = (byte >> bitIndex) & 1;
    return bit == 1;
  }

  int getUInt8(int offsetInBytes) => data.getUint8(offsetInBytes);
  int getUInt16(int offsetInBytes) =>
      data.getUint16(offsetInBytes, Endian.little);
  int getUInt32(int offsetInBytes) =>
      data.getUint32(offsetInBytes, Endian.little);
  int getUInt64(int offsetInBytes) =>
      data.getUint64(offsetInBytes, Endian.little);

  int getInt8(int offsetInBytes) => data.getInt8(offsetInBytes);
  int getInt16(int offsetInBytes) =>
      data.getInt16(offsetInBytes, Endian.little);
  int getInt32(int offsetInBytes) =>
      data.getInt32(offsetInBytes, Endian.little);
  int getInt64(int offsetInBytes) =>
      data.getInt64(offsetInBytes, Endian.little);

  double getFloat32(int offsetInBytes) =>
      data.getFloat32(offsetInBytes, Endian.little);
  double getFloat64(int offsetInBytes) =>
      data.getFloat64(offsetInBytes, Endian.little);

  String getText(int offsetInWords) {
    final pointer = ListPointer.fromView(subview(offsetInWords, 1));
    return Text(pointer).value;
  }

  UnmodifiableUint8ListView getData(int offsetInWords) {
    final pointer = ListPointer.fromView(subview(offsetInWords, 1));
    return CapnpUInt8List(pointer).value;
  }

  UnmodifiableBoolListView getBoolList(int offsetInWords) {
    final pointer = ListPointer.fromView(subview(offsetInWords, 1));
    return CapnpBoolList(pointer).value;
  }

  // List<T> getList<T>(int offset) {}
  // Enum<T> getEnum<T>(int offset) {}
  // T getStruct<T>(int offset) {}
  // TODO(JonasWanke): getInterface
  // TODO(JonasWanke): getAnyPointer
}
