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
