import 'dart:convert';
import 'dart:typed_data';

import '../constants.dart';
import '../pointer.dart';
import '../segment.dart';

/// https://capnproto.org/encoding.html#lists
abstract class CapnpList {
  CapnpList(ListPointer pointer)
      : assert(pointer != null),
        segmentView = pointer.targetView;

  final SegmentView segmentView;
}

abstract class _ByteBasedList extends CapnpList {
  _ByteBasedList(ListPointer pointer, this.elementSizeInBytes)
      : assert(pointer != null),
        assert(!pointer.isCompositeList),
        assert(pointer.elementSizeInBits ==
            elementSizeInBytes * CapnpConstants.bitsPerByte),
        length = pointer.elementCount,
        super(pointer);

  final int length;
  int get lengthInBytes => length * elementSizeInBytes;
  final int elementSizeInBytes;
}

class CapnpUInt8List extends _ByteBasedList {
  CapnpUInt8List(ListPointer pointer) : super(pointer, 1);

  UnmodifiableUint8ListView get list {
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, lengthInBytes);
    return UnmodifiableUint8ListView(list);
  }
}

class Text extends _ByteBasedList {
  Text(ListPointer pointer) : super(pointer, 1);

  String get value {
    // We don't need the final 0-byte.
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, lengthInBytes - 1);
    return utf8.decode(list);
  }
}

class CompositeList<T> extends CapnpList {
  factory CompositeList(ListPointer pointer) {
    final tagWord = StructPointer.fromView(pointer.segmentView.subview(0, 1));
    final elementCount = tagWord.offsetInWords;
    return CompositeList._(
      pointer,
      elementCount,
    );
  }
  CompositeList._(ListPointer pointer, this.length) : super(pointer);

  final int length;
}
