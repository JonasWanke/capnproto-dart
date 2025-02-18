class Imports {
  Imports(this.currentFile);

  final Uri currentFile;
  final imports = <Uri, String>{};

  String get bool => _importCore('bool');
  String get double => _importCore('double');
  String get int => _importCore('int');
  String get string => _importCore('String');
  String _importCore(String identifier) =>
      import(Uri.parse('dart:core'), identifier, prefix: r'$core');

  String get byteData => _importTypedData('ByteData');
  String _importTypedData(String identifier) =>
      import(Uri.parse('dart:typed_data'), identifier, prefix: r'$typed_data');

  String get capnpStructReader => _importCapnproto('CapnpStructReader');
  String get anyPointerReader => _importCapnproto('AnyPointerReader');
  String get structReader => _importCapnproto('StructReader');
  String get structListReader => _importCapnproto('StructListReader');
  String get primitiveListReader => _importCapnproto('PrimitiveListReader');
  String get textListReader => _importCapnproto('TextListReader');
  String get dataListReader => _importCapnproto('DataListReader');
  String _importCapnproto(String identifier) {
    return import(
      Uri.parse('package:capnproto/capnproto.dart'),
      identifier,
      prefix: r'$capnproto',
    );
  }

  String import(Uri uri, String identifier, {String? prefix}) {
    if (uri == currentFile) return identifier;

    prefix = imports.putIfAbsent(uri, () => prefix ?? '\$i${imports.length}');
    return '$prefix.$identifier';
  }

  void addImportsToBuffer(StringBuffer buffer) {
    for (final import in imports.entries) {
      buffer.writeln('import "${import.key}" as ${import.value};');
    }
  }
}
