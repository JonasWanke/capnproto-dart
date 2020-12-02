import 'package:capnproto/src/constants.dart';

import 'objects/struct.dart';
import 'segment.dart';

enum PointerType { struct, list, interSegment, capability }

abstract class Pointer {
  Pointer(this.segmentView)
      : assert(segmentView.lengthInWords == lengthInWords);
  factory Pointer.fromSegmentView(SegmentView segmentView) {
    assert(segmentView.lengthInWords == lengthInWords);

    final type = typeOf(segmentView);
    switch (type) {
      case PointerType.struct:
        return StructPointer.fromView(segmentView);
      case PointerType.list:
        return ListPointer.fromView(segmentView);
      case PointerType.interSegment:
        return InterSegmentPointer.fromView(segmentView);
      case PointerType.capability:
        throw StateError('Capability pointers are not yet supported.');
      default:
        throw StateError('Unknown pointer type: $type.');
    }
  }
  factory Pointer.resolvedFromSegmentView(SegmentView segmentView) {
    var pointer = Pointer.fromSegmentView(segmentView);
    while (pointer is InterSegmentPointer) {
      pointer = (pointer as InterSegmentPointer).target;
    }
    return pointer;
  }

  static PointerType typeOf(SegmentView segmentView) {
    assert(segmentView.lengthInWords == Pointer.lengthInWords);
    final rawType = segmentView.getUInt8(0) & 0x3;
    switch (rawType) {
      case 0x00:
        return PointerType.struct;
      case 0x01:
        return PointerType.list;
      case 0x02:
        return PointerType.interSegment;
      case 0x03:
        throw StateError('Capability pointers are not yet supported.');
      default:
        throw FormatException('Invalid pointer type: $rawType.');
    }
  }

  static const lengthInWords = 1;

  final SegmentView segmentView;
}

class StructPointer extends Pointer {
  factory StructPointer.inSegment(Segment segment, int offsetInWords) =>
      StructPointer.fromView(segment.view(offsetInWords, 1));
  StructPointer.fromView(SegmentView segmentView)
      : assert(Pointer.typeOf(segmentView) == PointerType.struct),
        super(segmentView);
  factory StructPointer.resolvedFromView(SegmentView segmentView) =>
      Pointer.resolvedFromSegmentView(segmentView) as StructPointer;

  int get offsetInWords => segmentView.getInt32(0) >> 2;

  int get dataSectionLengthInWords => segmentView.getUInt16(4);
  int get pointerSectionLengthInWords => segmentView.getUInt16(6);

  SegmentView get structView {
    return segmentView.viewRelativeToEnd(
      offsetInWords,
      dataSectionLengthInWords + pointerSectionLengthInWords,
    );
  }

  T load<T>(StructFactory<T> factory) =>
      factory(structView, dataSectionLengthInWords);
}

/// https://capnproto.org/encoding.html#lists
class ListPointer extends Pointer {
  ListPointer.fromView(SegmentView segmentView)
      : assert(Pointer.typeOf(segmentView) == PointerType.list),
        super(segmentView);
  factory ListPointer.resolvedFromView(SegmentView segmentView) =>
      Pointer.resolvedFromSegmentView(segmentView) as ListPointer;

  int get offsetInWords => segmentView.getInt32(0) >> 2;

  int get _rawElementSize => segmentView.getUInt8(4) & 0x07;
  bool get isCompositeList => _rawElementSize == 7;
  int get elementSizeInBits {
    switch (_rawElementSize) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 1 * CapnpConstants.bitsPerByte;
      case 3:
        return 2 * CapnpConstants.bitsPerByte;
      case 4:
        return 4 * CapnpConstants.bitsPerByte;
      case 5:
      case 6:
        return 8 * CapnpConstants.bitsPerByte;
      case 7:
        // TODO(JonasWanke): Better return value for composite lists?
        return -1;
      default:
        throw StateError("Unsigned 3-bit number can't be outside 0 – 7.");
    }
  }

  int get _rawListSize => segmentView.getUInt32(4) >> 3;
  int get elementCount {
    assert(!isCompositeList);
    return _rawListSize;
  }

  int get wordCount {
    assert(isCompositeList);
    return 1 + _rawListSize;
  }

  SegmentView get targetView {
    final lengthInWords = isCompositeList
        ? wordCount
        : (elementSizeInBits * elementCount / CapnpConstants.bitsPerWord)
            .ceil();
    return segmentView.viewRelativeToEnd(offsetInWords, lengthInWords);
  }
}

/// https://capnproto.org/encoding.html#inter-segment-pointers
class InterSegmentPointer extends Pointer {
  InterSegmentPointer.fromView(SegmentView segmentView)
      : assert(Pointer.typeOf(segmentView) == PointerType.interSegment),
        // TODO(JonasWanke): support other variant
        assert(segmentView.getUInt8(0) & 0x4 == 0x00),
        super(segmentView);

  int get offsetInWords => segmentView.getUInt32(0) >> 3;
  int get targetSegmentId => segmentView.getUInt32(4);

  Pointer get target {
    final targetSegment = segmentView.segment.message.segments[targetSegmentId];
    final targetSegmentView = targetSegment.view(offsetInWords, 1);
    return Pointer.fromSegmentView(targetSegmentView);
  }
}
