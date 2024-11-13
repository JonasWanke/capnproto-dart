import 'dart:io';
import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';
import 'package:test/test.dart';

// ignore_for_file: avoid-top-level-members-in-tests

void main() {
  test('decode simple message', () {
    final compiledFile = File('test/simple_message.bin');
    final message = Message.fromBuffer(compiledFile.readAsBytesSync().buffer);

    final testStruct = message.getRoot(TestStruct.new);
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

class TestStruct extends Struct {
  const TestStruct(super.reader);

  bool get boolean => reader.getBool(0);
  BoolList get booleanList => reader.getBoolList(0);
  int get int8 => reader.getInt8(1);
  int get int16 => reader.getInt16(1);
  int get int32 => reader.getInt32(1);
  int get int64 => reader.getInt64(1);
  int get uint8 => reader.getUInt8(16);
  int get uint16 => reader.getUInt16(9);
  Uint16List get uint16List => reader.getUInt16List(1);
  int get uint32 => reader.getUInt32(5);
  int get uint64 => reader.getUInt64(3);
  double get float32 => reader.getFloat32(8);
  Float32List get float32List => reader.getFloat32List(2);
  double get float64 => reader.getFloat64(5);
  String get text => reader.getText(3);
  Uint8List get data => reader.getData(4);
  Foo get foo => reader.getStruct(5, Foo.new);
  CompositeList<Foo> get fooList => reader.getCompositeList(6, Foo.new);

  @override
  String toString() {
    return 'TestStruct(unit: <void>, boolean: $boolean, '
        'booleanList: $booleanList, int8: $int8, int16: $int16, int32: $int32, '
        'int64: $int64, uint8: $uint8, uint16: $uint16, '
        'uint16List: $uint16List, uint32: $uint32, uint64: $uint64, '
        'float32: $float32, float32List: $float32List, float64: $float64, '
        'text: $text, data: $data, foo: $foo, fooList: $fooList)';
  }
}

class Foo extends Struct {
  const Foo(super.reader);

  int get bar => reader.getUInt8(0);

  @override
  String toString() => 'Foo(bar: $bar)';
}
