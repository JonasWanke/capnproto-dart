import 'dart:typed_data';

import 'error.dart';
import 'message.dart';
import 'private/layout.dart';
import 'reader_builder.dart';

class StructListReader<R extends CapnpReader> extends Iterable<R> {
  const StructListReader(this.reader, this.fromStruct);

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

  final ListReader reader;
  final FromStructReader<R> fromStruct;

  @override
  Iterator<R> get iterator =>
      Iterable.generate(length, (index) => this[index]).iterator;

  @override
  int get length => reader.length;
  @override
  bool get isEmpty => length == 0;

  @override
  R get last {
    if (isEmpty) throw StateError('No element');
    return this[length - 1];
  }

  R operator [](int index) => fromStruct(reader.getStructElement(index));
  @override
  R elementAt(int index) => this[index];
}

class StructListBuilder<B extends CapnpBuilder<R>, R extends CapnpReader>
    extends Iterable<B> {
  StructListBuilder(
    this.builder,
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

  static CapnpResult<StructListBuilder<B, R>>
      getFromPointer<B extends CapnpBuilder<R>, R extends CapnpReader>(
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

  final ListBuilder builder;
  final FromStructBuilder<B, R> fromStructBuilder;
  final FromStructReader<R> fromStructReader;

  @override
  Iterator<B> get iterator =>
      Iterable.generate(length, (index) => this[index]).iterator;

  @override
  int get length => builder.length;
  @override
  bool get isEmpty => length == 0;

  @override
  B get last {
    if (isEmpty) throw StateError('No element');
    return this[length - 1];
  }

  B operator [](int index) =>
      fromStructBuilder(builder.getStructElement(index));
  @override
  B elementAt(int index) => this[index];
}
