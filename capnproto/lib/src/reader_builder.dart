import 'dart:collection';
import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

import '../capnproto.dart';

abstract interface class SetterInput {
  const SetterInput();

  factory SetterInput.text(String value) {
    return SetterInput.fromFunction((builder, {canonicalize = false}) {
      builder.setText(value);
      return const Ok(null);
    });
  }
  factory SetterInput.data(ByteData value) {
    return SetterInput.fromFunction((builder, {canonicalize = false}) {
      builder.setData(value);
      return const Ok(null);
    });
  }
  factory SetterInput.fromFunction(
    CapnpResult<void> Function(PointerBuilder builder, {bool canonicalize})
        function,
  ) = _FunctionSetterInput;

  CapnpResult<void> setPointerBuilder(
    PointerBuilder builder, {
    bool canonicalize = false,
  });
}

final class _FunctionSetterInput extends SetterInput {
  const _FunctionSetterInput(this.function);

  final CapnpResult<void> Function(PointerBuilder builder, {bool canonicalize})
      function;

  @override
  CapnpResult<void> setPointerBuilder(
    PointerBuilder builder, {
    bool canonicalize = false,
  }) =>
      function(builder, canonicalize: canonicalize);
}

abstract class CapnpReader implements SetterInput {
  const CapnpReader();
}

abstract class CapnpBuilder<R extends CapnpReader> {
  const CapnpBuilder();

  R get asReader;
}

// Struct

// TODO(JonasWanke): better names to differentiate against `StructReader`
abstract class CapnpStructReader extends CapnpReader {
  const CapnpStructReader(this.reader);

  final StructReader reader;

  @override
  CapnpResult<void> setPointerBuilder(
    PointerBuilder builder, {
    bool canonicalize = false,
  }) =>
      reader.setPointerBuilder(builder, canonicalize: canonicalize);
}

abstract class CapnpStructBuilder<R extends CapnpStructReader>
    extends CapnpBuilder<R> {
  const CapnpStructBuilder(this.builder);

  final StructBuilder builder;

  @override
  R get asReader;
}

// List

abstract class CapnpListReader<R> extends ListBase<R> implements CapnpReader {
  const CapnpListReader(this.reader);

  final ListReader reader;

  @override
  int get length => reader.length;
  @override
  set length(int newLength) =>
      throw UnsupportedError('This list is read-only.');

  @override
  void operator []=(int index, R value) =>
      throw UnsupportedError('This list is read-only.');

  @override
  CapnpResult<void> setPointerBuilder(
    PointerBuilder builder, {
    bool canonicalize = false,
  }) =>
      reader.setPointerBuilder(builder, canonicalize: canonicalize);
}

abstract class CapnpListBuilder<B, ListOfR extends CapnpListReader<Object?>>
    extends ListBase<B> implements CapnpBuilder<ListOfR> {
  const CapnpListBuilder(this.builder);

  final ListBuilder builder;

  @override
  int get length => builder.length;
  @override
  // ignore: avoid_setters_without_getters
  set length(int newLength) {
    throw UnsupportedError(
      "The length of a Cap'n Proto list can't be changed.",
    );
  }
}
