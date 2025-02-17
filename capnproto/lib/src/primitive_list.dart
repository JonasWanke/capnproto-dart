import 'dart:typed_data';

import 'constants.dart';
import 'error.dart';
import 'private/layout.dart';
import 'reader_builder.dart';
import 'utils.dart';

class PrimitiveListReader<T> extends CapnpListReader<T> {
  const PrimitiveListReader(super.reader, this._get);

  static CapnpResult<PrimitiveListReader<void>> voidFromPointer(
    PointerReader builder,
    ByteData? defaultValue,
  ) {
    return builder
        .getList(defaultValue, expectedElementSize: ElementSize.void_)
        .map((it) => PrimitiveListReader(it, (reader, index) {}));
  }

  static CapnpResult<PrimitiveListReader<bool>> boolFromPointer(
    PointerReader builder,
    ByteData? defaultValue,
  ) {
    return builder
        .getList(defaultValue, expectedElementSize: ElementSize.bit)
        .map(
          (it) => PrimitiveListReader(
            it,
            (reader, index) => reader.data.getBool(index * reader.stepBits),
          ),
        );
  }

  static CapnpResult<PrimitiveListReader<int>> int8FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.byte,
      (reader, offset) => reader.data.getInt8(offset),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint8FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.byte,
      (reader, offset) => reader.data.getUint8(offset),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int16FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.twoBytes,
      (reader, offset) => reader.data.getInt16(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint16FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.twoBytes,
      (reader, offset) => reader.data.getUint16(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int32FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getInt32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint32FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getUint32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> int64FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getInt64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<int>> uint64FromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getUint64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<double>> floatFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getFloat32(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<double>> doubleFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      reader,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getFloat64(offset, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListReader<T>> _fromPointer<T>(
    PointerReader reader,
    ByteData? defaultValue,
    ElementSize expectedElementSize,
    T Function(ListReader reader, int byteOffset) get,
  ) {
    assert(expectedElementSize.pointersPerElement == 0);

    return reader
        .getList(defaultValue, expectedElementSize: expectedElementSize)
        .map(
          (it) => PrimitiveListReader(
            it,
            (reader, index) => get(
              reader,
              index * reader.stepBits ~/ CapnpConstants.bitsPerByte,
            ),
          ),
        );
  }

  final T Function(ListReader reader, int index) _get;

  @override
  T operator [](int index) => _get(reader, index);
}

class PrimitiveListBuilder<T>
    extends CapnpListBuilder<T, PrimitiveListReader<T>> {
  PrimitiveListBuilder(super.builder, this._get, this._set);

  static CapnpResult<PrimitiveListBuilder<void>> voidFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return builder.getList(ElementSize.void_, defaultValue).map(
          (it) => PrimitiveListBuilder(
            it,
            (reader, index) {},
            (builder, index, value) {},
          ),
        );
  }

  static CapnpResult<PrimitiveListBuilder<bool>> boolFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return builder.getList(ElementSize.bit, defaultValue).map(
          (it) => PrimitiveListBuilder(
            it,
            (reader, index) => reader.data.getBool(index * reader.stepBits),
            (builder, index, value) =>
                builder.data.setBool(index * builder.stepBits, value),
          ),
        );
  }

  static CapnpResult<PrimitiveListBuilder<int>> int8FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.byte,
      (reader, offset) => reader.data.getInt8(offset),
      (builder, offset, value) => builder.data.setInt8(offset, value),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> uint8FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.byte,
      (reader, offset) => reader.data.getUint8(offset),
      (builder, offset, value) => builder.data.setUint8(offset, value),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> int16FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.twoBytes,
      (reader, offset) => reader.data.getInt16(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setInt16(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> uint16FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.twoBytes,
      (reader, offset) => reader.data.getUint16(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setUint16(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> int32FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getInt32(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setInt32(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> uint32FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getUint32(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setUint32(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> int64FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getInt64(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setInt64(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<int>> uint64FromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getUint64(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setUint64(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<double>> floatFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.fourBytes,
      (reader, offset) => reader.data.getFloat32(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setFloat32(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<double>> doubleFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return _fromPointer(
      builder,
      defaultValue,
      ElementSize.eightBytes,
      (reader, offset) => reader.data.getFloat64(offset, Endian.little),
      (builder, offset, value) =>
          builder.data.setFloat64(offset, value, Endian.little),
    );
  }

  static CapnpResult<PrimitiveListBuilder<T>> _fromPointer<T>(
    PointerBuilder builder,
    ByteData? defaultValue,
    ElementSize elementSize,
    T Function(ListReader reader, int byteOffset) get,
    void Function(ListBuilder builder, int byteOffset, T value) set,
  ) {
    assert(elementSize.pointersPerElement == 0);

    return builder.getList(elementSize, defaultValue).map(
          (it) => PrimitiveListBuilder(
            it,
            (reader, index) => get(
              reader,
              index * reader.stepBits ~/ CapnpConstants.bitsPerByte,
            ),
            (builder, index, value) => set(
              builder,
              index * builder.stepBits ~/ CapnpConstants.bitsPerByte,
              value,
            ),
          ),
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
