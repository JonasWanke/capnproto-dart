import 'dart:io';
import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';
import 'package:test/test.dart';

// ignore_for_file: prefer_constructors_over_static_methods

void main() {
  test('decode simple message', () {
    final compiledFile = File('test/simple_message.bin');
    final message = Message.fromBuffer(compiledFile.readAsBytesSync().buffer);

    final testStruct = message.getRoot(TestStruct.from);
    expect(testStruct.boolean, true);
    expect(testStruct.booleanList, [true, false, false, true, true, true]);
    expect(testStruct.int8, -1);
    expect(testStruct.int16, -1);
    expect(testStruct.int32, -1);
    expect(testStruct.int64, -1);
    expect(testStruct.uint8, 1);
    expect(testStruct.uint16, 1);
    expect(testStruct.uint16List, [1, 5]);
    expect(testStruct.uint32, 12345);
    expect(testStruct.uint64, 1);
    expect(testStruct.float32, 1);
    expect(testStruct.float32List, [1, 0.5, 2]);
    expect(testStruct.float64, 1);
    expect(testStruct.text, 'Hello, world!');

    final data = Uint8List.fromList(List.generate(5, (i) => i + 1));
    expect(testStruct.data, data);

    expect(testStruct.foo, isNotNull);
    expect(testStruct.foo.bar, 123);

    expect(testStruct.fooList, isNotNull);
    expect(testStruct.fooList, hasLength(3));
    expect(testStruct.fooList[0], isNotNull);
    expect(testStruct.fooList[0].bar, 5);
    expect(testStruct.fooList[1], isNotNull);
    expect(testStruct.fooList[1].bar, 6);
    expect(testStruct.fooList[2], isNotNull);
    expect(testStruct.fooList[2].bar, 7);
  });
}

class TestStruct {
  const TestStruct(this.segmentView, this.dataSectionLengthInWords);

  static TestStruct from(
    SegmentView segmentView,
    int dataSectionLengthInWords,
  ) =>
      TestStruct(segmentView, dataSectionLengthInWords);

  final SegmentView segmentView;
  final int dataSectionLengthInWords;

  void get unit => segmentView.getVoid(0);
  bool get boolean => segmentView.getBool(0);
  UnmodifiableBoolListView get booleanList =>
      segmentView.getBoolList(dataSectionLengthInWords + 0);
  int get int8 => segmentView.getInt8(8 ~/ CapnpConstants.bitsPerByte);
  int get int16 => segmentView.getInt16(16 ~/ CapnpConstants.bitsPerByte);
  int get int32 => segmentView.getInt32(32 ~/ CapnpConstants.bitsPerByte);
  int get int64 => segmentView.getInt64(64 ~/ CapnpConstants.bitsPerByte);
  int get uint8 => segmentView.getUInt8(128 ~/ CapnpConstants.bitsPerByte);
  int get uint16 => segmentView.getUInt16(144 ~/ CapnpConstants.bitsPerByte);
  UnmodifiableUint16ListView get uint16List =>
      segmentView.getUInt16List(dataSectionLengthInWords + 1);
  int get uint32 => segmentView.getUInt32(160 ~/ CapnpConstants.bitsPerByte);
  int get uint64 => segmentView.getUInt64(192 ~/ CapnpConstants.bitsPerByte);
  double get float32 =>
      segmentView.getFloat32(256 ~/ CapnpConstants.bitsPerByte);
  UnmodifiableFloat32ListView get float32List =>
      segmentView.getFloat32List(dataSectionLengthInWords + 2);
  double get float64 =>
      segmentView.getFloat64(320 ~/ CapnpConstants.bitsPerByte);
  String get text => segmentView.getText(dataSectionLengthInWords + 3);
  UnmodifiableUint8ListView get data =>
      segmentView.getData(dataSectionLengthInWords + 4);
  Foo get foo => segmentView.getStruct(dataSectionLengthInWords + 5, Foo.from);
  UnmodifiableCompositeListView<Foo> get fooList =>
      segmentView.getCompositeList(dataSectionLengthInWords + 6, Foo.from);

  @override
  String toString() =>
      'TestStruct(unit: <void>, boolean: $boolean, booleanList: $booleanList, int8: $int8, int16: $int16, int32: $int32, int64: $int64, uint8: $uint8, uint16: $uint16, uint16List: $uint16List, uint32: $uint32, uint64: $uint64, float32: $float32, float32List: $float32List, float64: $float64, text: $text, data: $data, foo: $foo, fooList: $fooList';
}

class Foo {
  const Foo(this.segmentView, this.dataSectionLengthInWords);

  static Foo from(SegmentView segmentView, int dataSectionLengthInWords) =>
      Foo(segmentView, dataSectionLengthInWords);

  final SegmentView segmentView;
  final int dataSectionLengthInWords;

  int get bar => segmentView.getUInt8(0);

  @override
  String toString() => 'Foo(bar: $bar)';
}
