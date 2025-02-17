import 'package:capnproto/capnproto.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

@useResult
CapnpResult<void> generateConstant(
  String name,
  AnyPointerReader constant,
  StringBuffer buffer,
) {
  final int wordCount;
  switch (constant.reader.totalSize()) {
    case Ok(:final value):
      wordCount = value.wordCount + 1;
    case Err(:final error):
      return Err(error);
  }

  final message =
      MessageBuilder(allocator: HeapAllocator(firstSegmentWords: wordCount));

  if (message.setRoot(constant) case Err(:final error)) return Err(error);

  final segment = message.segmentsForOutput.single;

  final stringContent = segment.buffer
      .asUint16List()
      .map((it) => '\\u${it.toRadixString(16).padLeft(4, '0')}')
      .join();
  buffer.writeln("static const ${name}Data = '$stringContent';");
  buffer.writeln('static final $name = '
      'Uint16List.fromList(${name}Data.codeUnits).buffer.asByteData()');
  return const Ok(null);
}
