// ignore_for_file: file_names

import 'dart:io';

import 'package:capnproto/capnproto.dart';
import 'package:capnproto_generator/src/generate.dart';
import 'package:capnproto_generator/src/schema.dart';

Future<void> main(List<String> args) async {
  final bytes = await File(args.single).readAsBytes();
  final request = readMessage(bytes.buffer.asByteData())
      .unwrap()
      .getRootAsStruct(CodeGeneratorRequest_Reader.new)
      .unwrap();

  await CodeGenerationCommand(
    outputDirectory: Directory('/home/user/GitHub/JonasWanke/capnproto-dart/'),
  ).run(request);
}
