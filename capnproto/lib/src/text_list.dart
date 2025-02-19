import 'dart:typed_data';

import 'error.dart';
import 'private/layout.dart';
import 'reader_builder.dart';

class TextListReader extends CapnpListReader<String> {
  const TextListReader(super.reader);

  static CapnpResult<TextListReader> getFromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(defaultValue, expectedElementSize: ElementSize.pointer)
        .map(TextListReader.new);
  }

  @override
  String operator [](int index) =>
      reader.getPointerElement(index).getText(null).unwrap();
}

class TextListBuilder extends CapnpListBuilder<String, TextListReader> {
  TextListBuilder(super.builder);

  factory TextListBuilder.initPointer(PointerBuilder builder, int length) =>
      TextListBuilder(builder.initList(length, ElementSize.pointer));
  static CapnpResult<TextListBuilder> getFromPointer(
    PointerBuilder builder,
    ByteData? defaultValue,
  ) {
    return builder
        .getList(ElementSize.pointer, defaultValue)
        .map(TextListBuilder.new);
  }

  @override
  TextListReader get asReader => TextListReader(builder.asReader);

  @override
  String operator [](int index) =>
      builder.getPointerElement(index).getText(null).unwrap();
  @override
  void operator []=(int index, String value) =>
      builder.getPointerElement(index).setText(value);
}
