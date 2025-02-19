class Imports {
  Imports(this.currentFile);

  final Uri currentFile;
  final imports = <Uri, String>{};

  String get bool => _importCore('bool');
  String get double => _importCore('double');
  String get int => _importCore('int');
  String get string => _importCore('String');
  String get override => _importCore('override');
  String _importCore(String identifier) =>
      import(Uri.parse('dart:core'), identifier, prefix: r'$core');

  String get byteData => _importTypedData('ByteData');
  String _importTypedData(String identifier) =>
      import(Uri.parse('dart:typed_data'), identifier, prefix: r'$typedData');

  String get pointerReader => _importCapnproto('PointerReader');
  String get pointerBuilder => _importCapnproto('PointerBuilder');
  String get capnpStructReader => _importCapnproto('CapnpStructReader');
  String get capnpStructBuilder => _importCapnproto('CapnpStructBuilder');
  String get structSize => _importCapnproto('StructSize');
  String get anyPointerReader => _importCapnproto('AnyPointerReader');
  String get anyPointerBuilder => _importCapnproto('AnyPointerBuilder');
  String get structReader => _importCapnproto('StructReader');
  String get structBuilder => _importCapnproto('StructBuilder');
  String get structListReader => _importCapnproto('StructListReader');
  String get structListBuilder => _importCapnproto('StructListBuilder');
  String get primitiveListReader => _importCapnproto('PrimitiveListReader');
  String get primitiveListBuilder => _importCapnproto('PrimitiveListBuilder');
  String get textListReader => _importCapnproto('TextListReader');
  String get textListBuilder => _importCapnproto('TextListBuilder');
  String get dataListReader => _importCapnproto('DataListReader');
  String get dataListBuilder => _importCapnproto('DataListBuilder');
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
