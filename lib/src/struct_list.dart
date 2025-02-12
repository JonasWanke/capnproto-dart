import 'dart:typed_data';

import 'error.dart';
import 'message.dart';
import 'private/layout.dart';

class StructListReader<T> extends Iterable<T> {
  const StructListReader(this.reader, this.fromStructReader);

  static CapnpResult<StructListReader<T>> fromPointer<T>(
    PointerReader reader,
    FromStructReader<T> fromStruct,
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
  final FromStructReader<T> fromStructReader;

  @override
  Iterator<T> get iterator =>
      Iterable.generate(length, (index) => this[index]).iterator;

  @override
  int get length => reader.length;
  @override
  bool get isEmpty => length == 0;

  @override
  T get last {
    if (isEmpty) throw StateError('No element');
    return this[length - 1];
  }

  T operator [](int index) => fromStructReader(reader.getStructElement(index));
  @override
  T elementAt(int index) => this[index];
}

class StructListBuilder<T, B extends T> extends StructListReader<T> {
  StructListBuilder(this.builder, this.fromStruct)
      : super(builder, fromStruct.fromReader);

  factory StructListBuilder.initPointer(
    PointerBuilder builder,
    int length,
    StructSize structSize,
    FromStructBuilder<T, B> fromStruct,
  ) {
    return StructListBuilder(
      builder.initStructList(length, structSize),
      fromStruct,
    );
  }

  static CapnpResult<StructListBuilder<T, B>> getFromPointer<T, B extends T>(
    PointerBuilder builder,
    StructSize structSize,
    FromStructBuilder<T, B> fromStruct,
    ByteData? defaultValue,
  ) {
    return builder
        .getStructList(structSize, defaultValue)
        .map((it) => StructListBuilder(it, fromStruct));
  }

  final ListBuilder builder;
  final FromStructBuilder<T, B> fromStruct;

  @override
  B operator [](int index) =>
      fromStruct.fromBuilder(builder.getStructElement(index));
  @override
  B elementAt(int index) => this[index];
}
