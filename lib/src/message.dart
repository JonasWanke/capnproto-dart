import 'dart:collection';
import 'dart:typed_data';

import 'constants.dart';
import 'objects/struct.dart';
import 'pointer.dart';
import 'segment.dart';

class Message {
  factory Message.fromBuffer(ByteBuffer buffer) {
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
  Message._() : _segments = <Segment>[];

  final List<Segment> _segments;
  List<Segment> get segments => UnmodifiableListView(_segments);

  void _addSegment(Segment segment) {
    assert(segment.message == this);

    _segments.add(segment);
  }

  T getRoot<T>(StructFactory<T> factory) {
    assert(segments.isNotEmpty);

    final pointer = StructPointer.inSegment(segments.first, 0);
    return pointer.load(factory);
  }
}
