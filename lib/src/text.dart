import 'dart:convert';
import 'dart:typed_data';

import 'error.dart';
import 'private/layout.dart';

class TextReader {
  const TextReader(this.data);

  static CapnpResult<TextReader> fromPointer(
    PointerReader reader,
    ByteData? defaultValue,
  ) =>
      reader.getText(defaultValue);

  final Uint8List data;

  int get lengthInBytes => data.length;
  bool get isEmpty => lengthInBytes == 0;
  bool get isNotEmpty => !isEmpty;

  /// [allowMalformed] defines how to deal with invalid or unterminated
  /// character sequences.
  ///
  /// If it is `true`, replace invalid (or unterminated) character sequences
  /// with the Unicode Replacement character `U+FFFD` (�). Otherwise, throw a
  /// [FormatException].
  @override
  String toString({bool allowMalformed = false}) =>
      Utf8Decoder(allowMalformed: allowMalformed).convert(data);
}
