import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

import 'constants.dart';
import 'error.dart';
import 'message.dart';

/// Reads a serialized message (including a segment table) from a flat slice of
/// bytes, without copying.
///
/// The slice is allowed to extend beyond the end of the message.
CapnpResult<MessageReader> readMessage(
  ByteData data, {
  ReaderOptions options = const ReaderOptions(),
}) {
  switch (_readSegmentTable(data, options)) {
    case Ok(value: null):
      return const Err(PrematureEndOfFileCapnpError());
    case Ok(value: final segments?):
      return Ok(MessageReader(segments, options: options));
    case Err(:final error):
      return Err(error);
  }
}

const segmentCountLimit = 512;

/// Reads a segment table from `read` and returns the total number of words
/// across all segments, as well as the segment offsets.
///
/// The segment table format for streams is defined in the Cap'n Proto
/// [encoding spec](https://capnproto.org/encoding.html)
CapnpResult<Segments?> _readSegmentTable(
  ByteData data,
  ReaderOptions options,
) {
  if (data.lengthInBytes == 0) return const Ok(null);
  if (data.lengthInBytes < 4) return const Err(PrematureEndOfFileCapnpError());

  final segmentCount = data.getUint32(0, Endian.little) + 1;
  if (segmentCount > segmentCountLimit || segmentCount == 0) {
    return Err(InvalidNumberOfSegmentsCapnpError(segmentCount));
  }

  var offset = 4;
  if (data.lengthInBytes < offset + segmentCount * 4) {
    return const Err(PrematureEndOfFileCapnpError());
  }

  final builder = SegmentLengthsBuilder();
  for (var i = 0; i < segmentCount; i++) {
    final length = data.getUint32(offset, Endian.little);
    builder.addSegment(length);
    offset += 4;
  }

  // Don't accept a message which the receiver couldn't possibly traverse
  // without hitting the traversal limit. Without this check, a malicious client
  // could transmit a very large segment size to make the receiver allocate
  // excessive space and possibly crash.
  if (options.traversalLimitWords case final limit?) {
    if (builder.totalWords > limit) {
      return Err(MessageTooLargeCapnpError(builder.totalWords));
    }
  }

  if (segmentCount.isEven) offset += 4;

  if (data.lengthInBytes < offset + builder.totalWords) {
    return const Err(PrematureEndOfFileCapnpError());
  }

  return Ok(
    builder.intoSegments(data.buffer.asByteData(data.offsetInBytes + offset)),
  );
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
