import 'dart:typed_data';

import 'error.dart';
import 'private/layout.dart';
import 'reader_builder.dart';

class DataListReader extends CapnpListReader<ByteData> {
  const DataListReader(super.reader);

  static CapnpResult<DataListReader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.pointer)
        .map(DataListReader.new);
  }

  @override
  ByteData operator [](int index) =>
      reader.getPointerElement(index).getData(null).unwrap();
}

class DataListBuilder extends CapnpListBuilder<ByteData, DataListReader> {
  DataListBuilder(super.builder);

  factory DataListBuilder.initPointer(PointerBuilder builder, int length) =>
      DataListBuilder(builder.initList(length, ElementSize.pointer));
  static CapnpResult<DataListBuilder> getFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return builder
        .getList(ElementSize.pointer, defaultValue)
        .map(DataListBuilder.new);
  }

  @override
  DataListReader get asReader => DataListReader(builder.asReader);

  @override
  ByteData operator [](int index) =>
      builder.getPointerElement(index).getData(null).unwrap();
  @override
  void operator []=(int index, ByteData value) =>
      builder.getPointerElement(index).setData(value);
}
