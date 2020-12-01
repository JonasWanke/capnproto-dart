import 'package:capnproto/src/constants.dart';

import 'objects/struct.dart';
import 'segment.dart';

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
      : assert(segmentView.getUInt8(0) & 0x3 == 0x00),
        super(segmentView);

  int get offsetInWords => segmentView.getInt32(0) >> 2;

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

/// https://capnproto.org/encoding.html#lists
class ListPointer extends Pointer {
  factory ListPointer.inSegment(Segment segment, int offsetInWords) =>
      ListPointer.fromView(segment.view(offsetInWords, 1));
  ListPointer.fromView(SegmentView segmentView)
      : assert(segmentView.getUInt8(0) & 0x3 == 0x01),
        super(segmentView);

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
