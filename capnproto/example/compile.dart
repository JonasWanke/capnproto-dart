#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

import 'package:supernova/supernova.dart';

Future<void> main(List<String> args) async {
  final Uint8List messageBytes;
  switch (args) {
    case []:
      final messageChunks = await stdin.toList();
      messageBytes = Uint8List(messageChunks.sumBy((it) => it.length));
      var offset = 0;
      for (final chunk in messageChunks) {
        messageBytes.setAll(offset, chunk);
        offset += chunk.length;
      }
    case [final fileName]:
      messageBytes = await File(fileName).readAsBytes();
    default:
      stderr.writeln('Usage: compile.dart [FILE]');
      exit(1);
  }

  stderr.writeln('Received message of ${messageBytes.length} bytes.');
  // final message = Message.fromBuffer(messageBytes.buffer);
  // final root = message.getRoot(CodeGeneratorRequest.new);
  // stderr.writeln(root.toString());

  // await File('request.bin').writeAsBytes(messageBytes);
}
