import '../segment.dart';

typedef StructFactory<T> = T Function(
  SegmentView segmentView,
  int dataSectionLengthInWords,
);
