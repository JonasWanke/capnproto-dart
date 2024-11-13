import 'dart:typed_data';

import 'constants.dart';
import 'message.dart';
import 'objects/list.dart';
import 'objects/struct.dart';
import 'pointer.dart';

class Segment {
  Segment(this.message, this.data)
      : assert(data.lengthInBytes % CapnpConstants.bytesPerWord == 0);

  final Message message;
  final ByteData data;
  int get lengthInBytes => data.lengthInBytes;

  SegmentView view(int offsetInWords, int lengthInWords) =>
      SegmentView._(this, offsetInWords, lengthInWords);
}

class SegmentView {
  SegmentView._(this.segment, this.offsetInWords, this.lengthInWords)
      : assert(offsetInWords >= 0),
        assert(lengthInWords >= 0),
        assert(
          (offsetInWords + lengthInWords) * CapnpConstants.bytesPerWord <=
              segment.lengthInBytes,
        ),
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
    assert(offsetInWords >= 0);
    assert(lengthInWords >= 0);
    assert(offsetInWords + lengthInWords <= this.lengthInWords);

    return SegmentView._(
      segment,
      this.offsetInWords + offsetInWords,
      lengthInWords,
    );
  }

  SegmentView viewRelativeToEnd(int offsetInWords, int lengthInWords) {
    assert(offsetInWords >= 0);
    assert(lengthInWords >= 0);

    return SegmentView._(
      segment,
      this.offsetInWords + this.lengthInWords + offsetInWords,
      lengthInWords,
    );
  }

  // TODO(JonasWanke): default values

  // Primitives:
  void getVoid() {}
  bool getBool(int index) {
    final byte = data.getUint8(index ~/ CapnpConstants.bitsPerByte);
    final bitIndex = index % CapnpConstants.bitsPerByte;
    final bit = (byte >> bitIndex) & 1;
    return bit == 1;
  }

  int getUInt8(int index, {int defaultValue = 0}) =>
      data.getUint8(index) ^ defaultValue;
  int getUInt16(int index, {int defaultValue = 0}) =>
      data.getUint16(index * 2, Endian.little) ^ defaultValue;
  int getUInt32(int index, {int defaultValue = 0}) =>
      data.getUint32(index * 4, Endian.little) ^ defaultValue;
  int getUInt64(int index, {int defaultValue = 0}) =>
      data.getUint64(index * 8, Endian.little) ^ defaultValue;

  int getInt8(int index, {int defaultValue = 0}) =>
      data.getInt8(index) ^ defaultValue;
  int getInt16(int index, {int defaultValue = 0}) =>
      data.getInt16(index * 2, Endian.little) ^ defaultValue;
  int getInt32(int index, {int defaultValue = 0}) =>
      data.getInt32(index * 4, Endian.little) ^ defaultValue;
  int getInt64(int index, {int defaultValue = 0}) =>
      data.getInt64(index * 8, Endian.little) ^ defaultValue;

  double getFloat32(int index) => data.getFloat32(index * 4, Endian.little);
  double getFloat64(int index) => data.getFloat64(index * 8, Endian.little);

  String getText(int offsetInWords) {
    final pointer = ListPointer.resolvedFromView(subview(offsetInWords, 1));
    return Text(pointer).value;
  }

  Uint8List getData(int offsetInWords) {
    final pointer = ListPointer.resolvedFromView(subview(offsetInWords, 1));
    return CapnpUInt8List(pointer).value;
  }

  // Nested structs:
  T getStruct<T>(int offsetInWords, StructFactory<T> factory) =>
      factory(StructPointer.resolvedFromView(subview(offsetInWords, 1)).reader);

  // Lists of primitives:
  ListPointer _listPointer(int offsetInWords) =>
      ListPointer.resolvedFromView(subview(offsetInWords, 1));
  BoolList getBoolList(int offsetInWords) =>
      CapnpBoolList(_listPointer(offsetInWords)).value;
  Uint8List getUInt8List(int offsetInWords) =>
      CapnpUInt8List(_listPointer(offsetInWords)).value;
  Uint16List getUInt16List(int offsetInWords) =>
      CapnpUInt16List(_listPointer(offsetInWords)).value;
  Uint32List getUInt32List(int offsetInWords) =>
      CapnpUInt32List(_listPointer(offsetInWords)).value;
  Uint64List getUInt64List(int offsetInWords) =>
      CapnpUInt64List(_listPointer(offsetInWords)).value;
  Int8List getInt8List(int offsetInWords) =>
      CapnpInt8List(_listPointer(offsetInWords)).value;
  Int16List getInt16List(int offsetInWords) =>
      CapnpInt16List(_listPointer(offsetInWords)).value;
  Int32List getInt32List(int offsetInWords) =>
      CapnpInt32List(_listPointer(offsetInWords)).value;
  Int64List getInt64List(int offsetInWords) =>
      CapnpInt64List(_listPointer(offsetInWords)).value;
  Float32List getFloat32List(int offsetInWords) =>
      CapnpFloat32List(_listPointer(offsetInWords)).value;

  // Complex types:
  CompositeList<T> getCompositeList<T>(
    int offsetInWords,
    StructFactory<T> factory,
  ) {
    final pointer = CompositeListPointer.resolvedFromView(
      subview(offsetInWords, 1),
      factory,
    );
    return CompositeList(pointer);
  }
  // Enum<T> getEnum<T>(int offset) {}
  // T getStruct<T>(int offset) {}
  // TODO(JonasWanke): getInterface
  // TODO(JonasWanke): getAnyPointer
}
