import 'error.dart';
import 'message.dart';
import 'private/layout.dart';

class AnyPointerReader {
  AnyPointerReader(this._reader);

  final PointerReader _reader;

  CapnpResult<T> getAs<T>(FromPointerReader<T> fromPointer) =>
      fromPointer(_reader, null);
}

class AnyPointerBuilder {
  AnyPointerBuilder(this._builder);

  final PointerBuilder _builder;

  CapnpResult<T> getAs<T>(FromPointerBuilder<T> fromPointer) =>
      fromPointer.getFromPointer(_builder, null);
  T initAs<T>(FromPointerBuilder<T> fromPointer) =>
      fromPointer.initPointer(_builder, 0);
  T initAsListOf<T>(FromPointerBuilder<T> fromPointer, int length) =>
      fromPointer.initPointer(_builder, length);

  // TODO(JonasWanke): setAs(…)
}
