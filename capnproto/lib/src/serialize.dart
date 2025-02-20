import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'constants.dart';
import 'error.dart';
import 'message.dart';
import 'utils.dart';

const segmentCountLimit = 512;

/// Reads a serialized message (including a segment table) from [data], without
/// copying.
///
/// [data] is allowed to extend beyond the end of the message.
///
/// The segment table format for streams is defined in the Cap'n Proto
/// [encoding spec](https://capnproto.org/encoding.html).
@useResult
CapnpResult<MessageReader> readMessage(
  ByteData data, {
  ReaderOptions options = const ReaderOptions(),
}) {
  switch (tryReadMessage(data, options: options)) {
    case Ok(value: null):
      return const Err(PrematureEndOfInputCapnpError());
    case Ok(:final value?):
      return Ok(value);
    case Err(:final error):
      return Err(error);
  }
}

/// Like [readMessage], but returns `Ok(null)` instead of an error if the
/// [data] is empty.
@useResult
CapnpResult<MessageReader?> tryReadMessage(
  ByteData data, {
  ReaderOptions options = const ReaderOptions(),
}) {
  if (data.lengthInBytes == 0) return const Ok(null);
  if (data.lengthInBytes < 4) return const Err(PrematureEndOfInputCapnpError());

  final int segmentCount;
  switch (data.getSegmentCount()) {
    case Ok(:final value):
      segmentCount = value;
    case Err(:final error):
      return Err(error);
  }

  if (data.lengthInBytes < 4 + segmentCount * 4) {
    return const Err(PrematureEndOfInputCapnpError());
  }

  final SegmentLengthsBuilder builder;
  final int offset;
  switch (data.offsetBytes(4).getSegmentLengths(segmentCount, options)) {
    case Ok(:final value):
      builder = value.builder;
      offset = 4 + value.offset;
    case Err(:final error):
      return Err(error);
  }

  if (data.lengthInBytes < offset + builder.totalWords) {
    return const Err(PrematureEndOfInputCapnpError());
  }

  return Ok(
    MessageReader(
      builder.intoSegments(data.offsetBytes(offset)),
      options: options,
    ),
  );
}

extension on ByteData {
  CapnpResult<int> getSegmentCount() {
    final segmentCount = getUint32(0, Endian.little) + 1;
    if (segmentCount > segmentCountLimit || segmentCount == 0) {
      return Err(InvalidNumberOfSegmentsCapnpError(segmentCount));
    }
    return Ok(segmentCount);
  }

  CapnpResult<({SegmentLengthsBuilder builder, int offset})> getSegmentLengths(
    int segmentCount,
    ReaderOptions options,
  ) {
    final builder = SegmentLengthsBuilder();
    var offset = 0;
    for (var i = 0; i < segmentCount; i++) {
      final length = getUint32(offset, Endian.little);
      builder.addSegment(length);
      offset += 4;
    }
    if (segmentCount.isEven) offset += 4;

    // Don't accept a message which the receiver couldn't possibly traverse
    // without hitting the traversal limit. Without this check, a malicious
    // client could transmit a very large segment size to make the receiver
    // allocate excessive space and possibly crash.
    if (options.traversalLimitWords case final limit?) {
      if (builder.totalWords > limit) {
        return Err(MessageTooLargeCapnpError(builder.totalWords));
      }
    }

    return Ok((builder: builder, offset: offset));
  }
}

class SegmentLengthsBuilder {
  SegmentLengthsBuilder();

  final List<({int offsetWords, int lengthWords})> segmentIndices = [];

  var _totalWords = 0;
  int get totalWords => _totalWords;

  void addSegment(int lengthWords) {
    segmentIndices.add((offsetWords: totalWords, lengthWords: lengthWords));
    _totalWords += lengthWords;
  }

  Segments intoSegments(ByteData data) {
    assert(data.lengthInBytes == _totalWords * CapnpConstants.bytesPerWord);
    return Segments(segmentIndices, data);
  }
}

void writeMessage(MessageBuilder message, Sink<List<int>> sink) {
  final segments = message.segmentsForOutput;
  _writeSegmentTable(segments, sink);
  _writeSegments(segments, sink);
}

/// Writes a segment table to [sink].
///
/// [segments] must contain at least one segment.
void _writeSegmentTable(List<ByteData> segments, Sink<List<int>> sink) {
  assert(segments.isNotEmpty);

  final buffer = ByteData(4 + segments.length * 4);
  buffer.setUint32(0, segments.length - 1, Endian.little);
  for (final (index, segment) in segments.indexed) {
    buffer.setUint32(
      4 + index * 4,
      segment.lengthInBytes ~/ CapnpConstants.bytesPerWord,
      Endian.little,
    );
  }
  sink.add(buffer.buffer.asUint8List());
}

void _writeSegments(List<ByteData> segments, Sink<List<int>> sink) {
  for (final segment in segments) {
    sink.add(
      segment.buffer.asUint8List(segment.offsetInBytes, segment.lengthInBytes),
    );
  }
}

// ignore: avoid-unused-parameters
extension type const SegmentId(int index) {
  static const zero = SegmentId(0);
}

class Segments {
  Segments(this.segmentIndices, this.segmentsData);

  final List<({int offsetWords, int lengthWords})> segmentIndices;
  final ByteData segmentsData;

  ByteData? getSegment(SegmentId id) {
    if (id.index < 0 || id.index >= segmentIndices.length) return null;

    final (:offsetWords, :lengthWords) = segmentIndices[id.index];
    return segmentsData.buffer.asByteData(
      segmentsData.offsetInBytes + offsetWords * CapnpConstants.bytesPerWord,
      lengthWords * CapnpConstants.bytesPerWord,
    );
  }
}
