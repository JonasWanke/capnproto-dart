class Imports {
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

  String get capnpReader => _importCapnproto('CapnpReader');
  String get structReader => _importCapnproto('StructReader');
  String _importCapnproto(String identifier) {
    return import(
      Uri.parse('package:capnproto/capnproto.dart'),
      identifier,
      prefix: r'$capnproto',
    );
  }

  String import(Uri uri, String identifier, {String? prefix}) {
    prefix = imports.putIfAbsent(uri, () => prefix ?? '\$i${imports.length}');
    return '$prefix.$identifier';
  }

  void addImportsToBuffer(StringBuffer buffer) {
    for (final import in imports.entries) {
      buffer.writeln('import "${import.key}" as ${import.value};');
    }
  }
}
