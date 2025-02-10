import 'dart:typed_data';

import 'error.dart';
import 'private/layout.dart';

class DataReader {
  const DataReader(this.data);

  static CapnpResult<DataReader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getData(defaultValue);

  final ByteData data;

  int get length => data.lengthInBytes;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;
}
