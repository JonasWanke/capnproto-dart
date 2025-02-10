import 'error.dart';
import 'message.dart';
import 'private/layout.dart';

class AnyPointerReader {
  AnyPointerReader(this._reader);

  final PointerReader _reader;

  CapnpResult<T> getAs<T>(FromPointerReader<T> fromPointer) =>
      fromPointer(_reader, null);
}
