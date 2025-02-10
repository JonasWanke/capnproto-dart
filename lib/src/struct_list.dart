import 'dart:typed_data';

import 'error.dart';
import 'message.dart';
import 'private/layout.dart';

class StructListReader<T> extends Iterable<T> {
  const StructListReader(this.reader, this.fromStruct);

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
  final FromStructReader<T> fromStruct;

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

  T operator [](int index) => fromStruct(reader.getStructElement(index));
  @override
  T elementAt(int index) => this[index];
}
