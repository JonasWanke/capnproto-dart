import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

import '../capnproto.dart';

abstract base class SetterInput {
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

abstract base class CapnpReader implements SetterInput {
  const CapnpReader();
}

abstract base class CapnpBuilder<R extends CapnpReader> {
  const CapnpBuilder();

  R get asReader;
}

// Struct

// TODO(JonasWanke): better names to differentiate against `StructReader`
abstract base class CapnpStructReader extends CapnpReader {
  const CapnpStructReader(this.reader);

  final StructReader reader;

  @override
  CapnpResult<void> setPointerBuilder(
    PointerBuilder builder, {
    bool canonicalize = false,
  }) =>
      reader.setPointerBuilder(builder, canonicalize: canonicalize);
}

abstract base class CapnpStructBuilder<R extends CapnpStructReader>
    extends CapnpBuilder<R> {
  const CapnpStructBuilder(this.builder);

  final StructBuilder builder;

  @override
  R get asReader;
}
