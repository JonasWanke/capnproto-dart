import 'dart:collection';
import 'dart:typed_data';

class CapnpConstants {
  const CapnpConstants._();

  static const bytesPerWord = 8;
  static const bitsPerWord = bytesPerWord * bitsPerByte;

  static const bitsPerByte = 8;
}

typedef StructFactory<T> = T Function(
  SegmentView segmentView,
  int dataSectionLengthInWords,
);

class Message {
  factory Message.fromBuffer(ByteBuffer buffer) {
    assert(buffer != null);

    // https://capnproto.org/encoding.html#serialization-over-a-stream
    final data = buffer.asByteData();
    final segmentCount = 1 + data.getUint32(0, Endian.little);

    final message = Message._();
    var offsetInWords = ((1 + segmentCount) / 2).ceil();
    for (var i = 0; i < segmentCount; i++) {
      final segmentLengthInWords = data.getUint32(4 + i * 4, Endian.little);
      final segmentData = buffer.asByteData(
        offsetInWords * CapnpConstants.bytesPerWord,
        segmentLengthInWords * CapnpConstants.bytesPerWord,
      );
      message._addSegment(Segment(message, segmentData));

      offsetInWords += segmentLengthInWords;
    }
    return message;
  }

  // ignore: prefer_collection_literals, Literals create an unmodifiable list.
  Message._() : _segments = List<Segment>();

  final List<Segment> _segments;
  List<Segment> get segments => UnmodifiableListView(_segments);

  void _addSegment(Segment segment) {
    assert(segment != null);
    assert(segment.message == this);

    _segments.add(segment);
  }

  T getRoot<T>(StructFactory<T> factory) {
    assert(segments.isNotEmpty);

    final pointer = StructPointer.inSegment(segments.first, 0);
    return pointer.load(factory);
  }
}

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
        assert(lengthInWords > 0),
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
  final int lengthInWords;
  int get lengthInBytes => lengthInWords * CapnpConstants.bytesPerWord;

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
    // TODO(JonasWanke): implement getText
    return null;
  }

  UnmodifiableByteDataView getData(int offsetInWords) {
    // TODO(JonasWanke): implement getData
    return null;
  }

  // List<T> getList<T>(int offset) {}
  // Enum<T> getEnum<T>(int offset) {}
  // T getStruct<T>(int offset) {}
  // TODO(JonasWanke): getInterface
  // TODO(JonasWanke): getAnyPointer
}

abstract class Pointer {
  Pointer(this.segmentView)
      : assert(segmentView.lengthInBytes == lengthInBytes);

  static const lengthInBytes = 8;

  final SegmentView segmentView;
}

class StructPointer extends Pointer {
  factory StructPointer.inSegment(Segment segment, int offsetInWords) =>
      StructPointer.fromView(segment.view(offsetInWords, 1));
  StructPointer.fromView(SegmentView segmentView)
      : assert(
            segmentView.getBool(0) == false && segmentView.getBool(1) == false),
        super(segmentView);

  int get offsetInWords {
    // This raw value has the first two bits set
    final rawValue = segmentView.getInt32(0);
    // TODO(JonasWanke): make sure this is correct
    return (rawValue & 0x3F) | (rawValue >> 2);
  }

  int get dataSectionLengthInWords => segmentView.getUInt16(4);
  int get pointerSectionLengthInWords => segmentView.getUInt16(6);

  SegmentView get structView {
    return segmentView.segment.view(
      segmentView.offsetInWords + 1 + offsetInWords,
      dataSectionLengthInWords + pointerSectionLengthInWords,
    );
  }

  T load<T>(StructFactory<T> factory) =>
      factory(structView, dataSectionLengthInWords);
}

