import 'dart:core' as core;
import 'dart:core';
import 'dart:typed_data';

import 'error.dart';
import 'private/layout.dart';
import 'reader_builder.dart';
import 'utils.dart';

class PrimitiveListReader<T> extends CapnpListReader<T> {
  const PrimitiveListReader(super.reader, this._get);

  // Void

  static PrimitiveListReader<void> void_(ListReader reader) =>
      PrimitiveListReader(reader, (reader, index) {});
  static CapnpResult<PrimitiveListReader<void>> voidGetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.void_)
        .map(void_);
  }

  // Bool

  static PrimitiveListReader<core.bool> bool(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, index) => reader.data.getBool(index * reader.stepBits),
    );
  }

  static CapnpResult<PrimitiveListReader<core.bool>> boolGetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.bit)
        .map(bool);
  }

  // Int8

  static PrimitiveListReader<int> int8(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getInt8(offset),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int8GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.byte)
        .map(int8);
  }

  // UInt8

  static PrimitiveListReader<int> uint8(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getUint8(offset),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint8GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.byte)
        .map(uint8);
  }

  // Int16

  static PrimitiveListReader<int> int16(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getInt16(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int16GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.twoBytes)
        .map(int16);
  }

  // UInt16

  static PrimitiveListReader<int> uint16(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getUint16(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint16GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.twoBytes)
        .map(uint16);
  }

  // Int32

  static PrimitiveListReader<int> int32(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getInt32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int32GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.fourBytes)
        .map(int32);
  }

  // UInt32

  static PrimitiveListReader<int> uint32(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getUint32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint32GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.fourBytes)
        .map(uint32);
  }

  // Int64

  static PrimitiveListReader<int> int64(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getInt64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int64GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.eightBytes)
        .map(int64);
  }

  // UInt64

  static PrimitiveListReader<int> uint64(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getUint64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint64GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.eightBytes)
        .map(uint64);
  }

  // Float32

  static PrimitiveListReader<double> float32(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getFloat32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<double>> float32GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.fourBytes)
        .map(float32);
  }

  // Float64

  static PrimitiveListReader<double> float64(ListReader reader) {
    return PrimitiveListReader(
      reader,
      (reader, offset) => reader.data.getFloat64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<double>> float64GetFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.eightBytes)
        .map(float64);
  }

  final T Function(ListReader reader, int index) _get;

  @override
  T operator [](int index) => _get(reader, index);
}

class PrimitiveListBuilder<T>
    extends CapnpListBuilder<T, PrimitiveListReader<T>> {
  PrimitiveListBuilder(super.builder, this._get, this._set);

  // Void

  static PrimitiveListBuilder<void> voidInitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      void_(builder.initList(length, ElementSize.void_));
  static CapnpResult<PrimitiveListBuilder<void>> voidGetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.void_, defaultValue).map(void_);
  static PrimitiveListBuilder<void> void_(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, index) {},
      (builder, index, value) {},
    );
  }

  // Bool

  static PrimitiveListBuilder<core.bool> boolInitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      bool(builder.initList(length, ElementSize.bit));
  static CapnpResult<PrimitiveListBuilder<core.bool>> boolGetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.bit, defaultValue).map(bool);
  static PrimitiveListBuilder<core.bool> bool(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, index) => reader.data.getBool(index * reader.stepBits),
      (builder, index, value) =>
          builder.data.setBool(index * builder.stepBits, value),
    );
  }

  // Int8

  static PrimitiveListBuilder<int> int8InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      int8(builder.initList(length, ElementSize.byte));
  static CapnpResult<PrimitiveListBuilder<int>> int8GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.byte, defaultValue).map(int8);
  static PrimitiveListBuilder<int> int8(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getInt8(offset),
      (builder, offset, value) => builder.data.setInt8(offset, value),
    );
  }

  // UInt8

  static PrimitiveListBuilder<int> uint8InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      uint8(builder.initList(length, ElementSize.byte));
  static CapnpResult<PrimitiveListBuilder<int>> uint8GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.byte, defaultValue).map(uint8);
  static PrimitiveListBuilder<int> uint8(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getUint8(offset),
      (builder, offset, value) => builder.data.setUint8(offset, value),
    );
  }

  // Int16

  static PrimitiveListBuilder<int> int16InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      int16(builder.initList(length, ElementSize.twoBytes));
  static CapnpResult<PrimitiveListBuilder<int>> int16GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.twoBytes, defaultValue).map(int16);
  static PrimitiveListBuilder<int> int16(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getInt16(offset),
      (builder, offset, value) => builder.data.setInt16(offset, value),
    );
  }

  // UInt16

  static PrimitiveListBuilder<int> uint16InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      uint16(builder.initList(length, ElementSize.twoBytes));
  static CapnpResult<PrimitiveListBuilder<int>> uint16GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.twoBytes, defaultValue).map(uint16);
  static PrimitiveListBuilder<int> uint16(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getUint16(offset),
      (builder, offset, value) => builder.data.setUint16(offset, value),
    );
  }

  // Int32

  static PrimitiveListBuilder<int> int32InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      int32(builder.initList(length, ElementSize.fourBytes));
  static CapnpResult<PrimitiveListBuilder<int>> int32GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.fourBytes, defaultValue).map(int32);
  static PrimitiveListBuilder<int> int32(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getInt32(offset),
      (builder, offset, value) => builder.data.setInt32(offset, value),
    );
  }

  // UInt32

  static PrimitiveListBuilder<int> uint32InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      uint32(builder.initList(length, ElementSize.fourBytes));
  static CapnpResult<PrimitiveListBuilder<int>> uint32GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.fourBytes, defaultValue).map(uint32);
  static PrimitiveListBuilder<int> uint32(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getUint32(offset),
      (builder, offset, value) => builder.data.setUint32(offset, value),
    );
  }

  // Int64

  static PrimitiveListBuilder<int> int64InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      int64(builder.initList(length, ElementSize.eightBytes));
  static CapnpResult<PrimitiveListBuilder<int>> int64GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.eightBytes, defaultValue).map(int64);
  static PrimitiveListBuilder<int> int64(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getInt64(offset),
      (builder, offset, value) => builder.data.setInt64(offset, value),
    );
  }

  // UInt64

  static PrimitiveListBuilder<int> uint64InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      uint64(builder.initList(length, ElementSize.eightBytes));
  static CapnpResult<PrimitiveListBuilder<int>> uint64GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.eightBytes, defaultValue).map(uint64);
  static PrimitiveListBuilder<int> uint64(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getUint64(offset),
      (builder, offset, value) => builder.data.setUint64(offset, value),
    );
  }

  // Float32

  static PrimitiveListBuilder<double> float32InitPointer(
    PointerBuilder builder,
    int length,
  ) =>
      float32(builder.initList(length, ElementSize.fourBytes));
  static CapnpResult<PrimitiveListBuilder<double>> float32GetFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.fourBytes, defaultValue).map(float32);
  static PrimitiveListBuilder<double> float32(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getFloat32(offset),
      (builder, offset, value) => builder.data.setFloat32(offset, value),
    );
  }

  // Float64

  static PrimitiveListBuilder<double> float64Pointer(
    PointerBuilder builder,
    int length,
  ) =>
      float64(builder.initList(length, ElementSize.eightBytes));
  static CapnpResult<PrimitiveListBuilder<double>> float64FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) =>
      builder.getList(ElementSize.eightBytes, defaultValue).map(float64);
  static PrimitiveListBuilder<double> float64(ListBuilder builder) {
    return PrimitiveListBuilder(
      builder,
      (reader, offset) => reader.data.getFloat64(offset),
      (builder, offset, value) => builder.data.setFloat64(offset, value),
    );
  }

  final T Function(ListReader reader, int index) _get;
  final void Function(ListBuilder builder, int index, T value) _set;

  @override
  PrimitiveListReader<T> get asReader =>
      PrimitiveListReader(builder.asReader, _get);

  @override
  T operator [](int index) => _get(builder.asReader, index);
  @override
  void operator []=(int index, T value) => _set(builder, index, value);
}
