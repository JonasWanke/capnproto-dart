import 'package:oxidized/oxidized.dart';

import '../error.dart';
import 'message.dart';
import 'private/layout.dart';

class AnyPointerReader {
  AnyPointerReader(this._reader);

  final PointerReader _reader;

  Result<T, CapnpError> getAs<T>(FromPointerReader<T> fromPointer) =>
      fromPointer(_reader, null);
}
