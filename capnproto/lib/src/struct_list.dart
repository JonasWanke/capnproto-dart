import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'error.dart';
import 'message.dart';
import 'private/layout.dart';
import 'reader_builder.dart';

class StructListReader<R extends CapnpReader> extends CapnpListReader<R> {
  const StructListReader(super.reader, this.fromStruct);

  static CapnpResult<StructListReader<R>> fromPointer<R extends CapnpReader>(
    PointerReader reader,
    FromStructReader<R> fromStruct,
    ByteData? defaultValue,
  ) {
    return reader
        .getList(
          defaultValue,
          expectedElementSize: ElementSize.inlineComposite,
        )
        .map((it) => StructListReader(it, fromStruct));
  }

  final FromStructReader<R> fromStruct;

  @override
  R operator [](int index) => fromStruct(reader.getStructElement(index));
}

class StructListBuilder<B extends CapnpStructBuilder<R>,
        R extends CapnpStructReader>
    extends CapnpListBuilder<B, StructListReader<R>> {
  StructListBuilder(
    super.builder,
    this.fromStructBuilder,
    this.fromStructReader,
  );

  factory StructListBuilder.initPointer(
    PointerBuilder builder,
    int length,
    StructSize structSize,
    FromStructBuilder<B, R> fromStructBuilder,
    FromStructReader<R> fromStructReader,
  ) {
    return StructListBuilder(
      builder.initStructList(length, structSize),
      fromStructBuilder,
      fromStructReader,
    );
  }

  static CapnpResult<StructListBuilder<B, R>> getFromPointer<
      B extends CapnpStructBuilder<R>, R extends CapnpStructReader>(
    PointerBuilder builder,
    StructSize structSize,
    FromStructBuilder<B, R> fromStructBuilder,
    FromStructReader<R> fromStructReader,
    ByteData? defaultValue,
  ) {
    return builder.getStructList(structSize, defaultValue).map(
          (it) => StructListBuilder(it, fromStructBuilder, fromStructReader),
        );
  }

  final FromStructBuilder<B, R> fromStructBuilder;
  final FromStructReader<R> fromStructReader;

  @override
  StructListReader<R> get asReader =>
      StructListReader(builder.asReader, fromStructReader);

  @override
  B operator [](int index) =>
      fromStructBuilder(builder.getStructElement(index));
  @override
  void operator []=(int index, B value) =>
      throw UnsupportedError('Use `setWithCaveats(…)` instead.');

  /// Sets the list element, with the following limitation based on the fact
  /// that structs in a struct list are allocated inline: If the source struct
  /// is larger than the target struct (as can happen if it was created with a
  /// newer version of the schema), then it will be truncated, losing fields.
  @useResult
  CapnpResult<void> setWithCaveats(int index, R value) {
    assert(0 <= index && index < length);
    return builder.getStructElement(index).copyContentFrom(value.reader);
  }
}
