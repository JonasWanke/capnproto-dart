import 'dart:typed_data';

import '../pointer.dart';
import '../segment.dart';
import 'list.dart';

typedef StructFactory<T> = T Function(StructReader reader);

abstract class Struct {
  const Struct(this.reader);

  final StructReader reader;
}

class StructReader {
  StructReader(this.segmentView, this.dataSectionLengthInWords)
      : assert(segmentView.lengthInWords >= dataSectionLengthInWords);

  final SegmentView segmentView;

  final int dataSectionLengthInWords;
  int get pointerSectionLengthInWords =>
      segmentView.lengthInWords - dataSectionLengthInWords;

  // Primitives:
  void getVoid() {}
  bool getBool(int index) => segmentView.getBool(index);

  int getUInt8(int index, {int defaultValue = 0}) =>
      segmentView.getUInt8(index, defaultValue: defaultValue);
  int getUInt16(int index, {int defaultValue = 0}) =>
      segmentView.getUInt16(index, defaultValue: defaultValue);
  int getUInt32(int index, {int defaultValue = 0}) =>
      segmentView.getUInt32(index, defaultValue: defaultValue);
  int getUInt64(int index, {int defaultValue = 0}) =>
      segmentView.getUInt64(index, defaultValue: defaultValue);

  int getInt8(int index, {int defaultValue = 0}) =>
      segmentView.getInt8(index, defaultValue: defaultValue);
  int getInt16(int index, {int defaultValue = 0}) =>
      segmentView.getInt16(index, defaultValue: defaultValue);
  int getInt32(int index, {int defaultValue = 0}) =>
      segmentView.getInt32(index, defaultValue: defaultValue);
  int getInt64(int index, {int defaultValue = 0}) =>
      segmentView.getInt64(index, defaultValue: defaultValue);

  double getFloat32(int index) => segmentView.getFloat32(index);
  double getFloat64(int index) => segmentView.getFloat64(index);

  String getText(int index) =>
      segmentView.getText(dataSectionLengthInWords + index);
  Uint8List getData(int index) =>
      segmentView.getData(dataSectionLengthInWords + index);

  // Nested structs:
  T getStruct<T>(int index, StructFactory<T> factory) =>
      segmentView.getStruct(dataSectionLengthInWords + index, factory);

  // Lists of primitives:
  BoolList getBoolList(int index) =>
      segmentView.getBoolList(dataSectionLengthInWords + index);
  Uint8List getUInt8List(int index) =>
      segmentView.getUInt8List(dataSectionLengthInWords + index);
  Uint16List getUInt16List(int index) =>
      segmentView.getUInt16List(dataSectionLengthInWords + index);
  Uint32List getUInt32List(int index) =>
      segmentView.getUInt32List(dataSectionLengthInWords + index);
  Uint64List getUInt64List(int index) =>
      segmentView.getUInt64List(dataSectionLengthInWords + index);
  Int8List getInt8List(int index) =>
      segmentView.getInt8List(dataSectionLengthInWords + index);
  Int16List getInt16List(int index) =>
      segmentView.getInt16List(dataSectionLengthInWords + index);
  Int32List getInt32List(int index) =>
      segmentView.getInt32List(dataSectionLengthInWords + index);
  Int64List getInt64List(int index) =>
      segmentView.getInt64List(dataSectionLengthInWords + index);
  Float32List getFloat32List(int index) =>
      segmentView.getFloat32List(dataSectionLengthInWords + index);

  // Complex types:
  CompositeList<T> getCompositeList<T>(int index, StructFactory<T> factory) =>
      segmentView.getCompositeList(dataSectionLengthInWords + index, factory);

  // ignore: avoid-unused-parameters
  AnyPointer getPointer(int index) {
    // TODO(JonasWanke): implement
    throw UnsupportedError('Not yet implemented.');
  }
}
