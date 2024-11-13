import 'constants.dart';
import 'objects/list.dart';
import 'objects/struct.dart';
import 'segment.dart';

enum PointerType { struct, list, interSegment, capability }

typedef PointerFactory<P extends AnyPointer> = P Function(
  SegmentView segmentView,
);

abstract class AnyPointer {
  AnyPointer(this.segmentView)
      : assert(segmentView.lengthInWords == lengthInWords);
  static P resolvedFromSegmentView<P extends AnyPointer>(
    SegmentView segmentView,
    PointerFactory<P> factory,
  ) {
    while (typeOf(segmentView) == PointerType.interSegment) {
      segmentView = InterSegmentPointer.fromView(segmentView).target;
    }
    return factory(segmentView);
  }

  static PointerType typeOf(SegmentView segmentView) {
    assert(segmentView.lengthInWords == AnyPointer.lengthInWords);
    final rawType = segmentView.getUInt8(0) & 0x3;
    return switch (rawType) {
      0x00 => PointerType.struct,
      0x01 => PointerType.list,
      0x02 => PointerType.interSegment,
      0x03 => throw StateError('Capability pointers are not yet supported.'),
      _ => throw const FormatException(
          "Unsigned 2-bit number can't be outside 0 – 3.",
        ),
    };
  }

  static const lengthInWords = 1;

  final SegmentView segmentView;
}

class StructPointer extends AnyPointer {
  factory StructPointer.inSegment(Segment segment, int offsetInWords) =>
      StructPointer.fromView(segment.view(offsetInWords, 1));
  StructPointer.fromView(super.segmentView)
      : assert(AnyPointer.typeOf(segmentView) == PointerType.struct);
  factory StructPointer.resolvedFromView(SegmentView segmentView) {
    return AnyPointer.resolvedFromSegmentView(
      segmentView,
      StructPointer.fromView,
    );
  }

  int get offsetInWords => segmentView.getInt32(0) >> 2;

  int get dataSectionLengthInWords => segmentView.getUInt16(2);
  int get pointerSectionLengthInWords => segmentView.getUInt16(3);

  SegmentView get structView {
    return segmentView.viewRelativeToEnd(
      offsetInWords,
      dataSectionLengthInWords + pointerSectionLengthInWords,
    );
  }

  StructReader get reader => StructReader(structView, dataSectionLengthInWords);
}

/// https://capnproto.org/encoding.html#lists
class ListPointer extends AnyPointer {
  ListPointer.fromView(super.segmentView)
      : assert(AnyPointer.typeOf(segmentView) == PointerType.list);
  factory ListPointer.resolvedFromView(SegmentView segmentView) {
    return AnyPointer.resolvedFromSegmentView(
      segmentView,
      ListPointer.fromView,
    );
  }

  int get offsetInWords => segmentView.getInt32(0) >> 2;

  int get _rawElementSize => segmentView.getUInt8(4) & 0x07;
  bool get isCompositeList => _rawElementSize == 7;
  int get elementSizeInBits {
    return switch (_rawElementSize) {
      0 => 0,
      1 => 1,
      2 => 1 * CapnpConstants.bitsPerByte,
      3 => 2 * CapnpConstants.bitsPerByte,
      4 => 4 * CapnpConstants.bitsPerByte,
      5 || 6 => 8 * CapnpConstants.bitsPerByte,
      // TODO(JonasWanke): Better return value for composite lists
      7 => -1,
      _ => throw StateError("Unsigned 3-bit number can't be outside 0 – 7."),
    };
  }

  int get _rawListSize => segmentView.getUInt32(1) >> 3;
  int get elementCount {
    assert(!isCompositeList);
    return _rawListSize;
  }

  int get wordCount {
    assert(isCompositeList);
    return 1 + _rawListSize;
  }

  SegmentView get targetView {
    assert(!isCompositeList, 'CompositeListPointer overwrites this field.');
    final lengthInWords =
        (elementSizeInBits * elementCount / CapnpConstants.bitsPerWord).ceil();
    return segmentView.viewRelativeToEnd(offsetInWords, lengthInWords);
  }
}

class CompositeListPointer<T> extends ListPointer {
  CompositeListPointer.fromView(super.segmentView, this.factory)
      : super.fromView() {
    assert(isCompositeList);
  }
  factory CompositeListPointer.resolvedFromView(
    SegmentView segmentView,
    StructFactory<T> factory,
  ) {
    return AnyPointer.resolvedFromSegmentView(
      segmentView,
      (it) => CompositeListPointer.fromView(it, factory),
    );
  }

  final StructFactory<T> factory;

  @override
  SegmentView get targetView =>
      segmentView.viewRelativeToEnd(offsetInWords, wordCount);

  CompositeList<T> get value => CompositeList(this);
}

/// https://capnproto.org/encoding.html#inter-segment-pointers
class InterSegmentPointer extends AnyPointer {
  InterSegmentPointer.fromView(super.segmentView)
      : assert(AnyPointer.typeOf(segmentView) == PointerType.interSegment),
        // TODO(JonasWanke): support other variant
        assert(segmentView.getUInt8(0) & 0x4 == 0x00);

  int get offsetInWords => segmentView.getUInt32(0) >> 3;
  int get targetSegmentId => segmentView.getUInt32(4);

  SegmentView get target {
    final targetSegment = segmentView.segment.message.segments[targetSegmentId];
    return targetSegment.view(offsetInWords, 1);
  }
}
