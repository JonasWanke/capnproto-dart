import 'dart:typed_data';

import 'package:capnproto/capnproto.dart';
import 'package:meta/meta.dart';

@useResult
String generateConstantPointerReader(
  String name,
  AnyPointerReader constant,
  StringBuffer buffer, {
  required bool isStatic,
}) {
  final wordCount = constant.reader.totalSize().unwrap().wordCount + 1;
  final message =
      MessageBuilder(allocator: HeapAllocator(firstSegmentWords: wordCount));

  message.setRoot(constant).unwrap();

  final reference = _generateConstantDataRaw(
    '${name}Data',
    message.segmentsForOutput.single,
    buffer,
    isStatic: isStatic,
  );
  return 'PointerReader.getRootUnchecked($reference)';
}

void generateConstantData(
  String name,
  ByteData data,
  StringBuffer buffer, {
  required bool isStatic,
}) {
  final staticString = isStatic ? 'static' : '';
  final reference =
      _generateConstantDataRaw(name, data, buffer, isStatic: isStatic);
  buffer.writeln('$staticString final $name = $reference;');
}

String _generateConstantDataRaw(
  String name,
  ByteData data,
  StringBuffer buffer, {
  required bool isStatic,
}) {
  final staticString = isStatic ? 'static' : '';
  final stringContent = data.buffer
      .asUint16List()
      .map((it) => '\\u${it.toRadixString(16).padLeft(4, '0')}')
      .join();
  buffer.writeln("$staticString const _${name}Encoded = '$stringContent';");
  return 'Uint16List.fromList(_${name}Encoded.codeUnits).buffer.asByteData()';
}
