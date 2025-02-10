import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../error.dart';
import '../message.dart';
import '../serialize.dart';
import 'read_limiter.dart';

abstract class ReaderArena {
  const ReaderArena();

  CapnpResult<ByteData> getSegment(SegmentId id);

  CapnpResult<void> checkOffset(SegmentId segmentId, int offset);
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  );
  CapnpResult<void> amplifiedRead(int virtualAmount);
}

class ReaderArenaImpl extends ReaderArena {
  ReaderArenaImpl(this._segments, ReaderOptions options)
      : readLimiter = ReadLimiter(options.traversalLimitWords),
        nestingLimit = options.nestingLimit;

  final Segments _segments;
  final ReadLimiter readLimiter;
  final int nestingLimit;

  @override
  CapnpResult<ByteData> getSegment(SegmentId id) {
    final segment = _segments.getSegment(id);
    if (segment == null) return Err(InvalidSegmentIdCapnpError(id));
    return Ok(segment);
  }

  @override
  CapnpResult<void> checkOffset(SegmentId segmentId, int offset) {
    return getSegment(segmentId).andThen((segment) {
      if (offset < 0 || offset > segment.lengthInBytes) {
        return const Err(MessageContainsOutOfBoundsPointerCapnpError());
      }

      return const Ok(null);
    });
  }

  @override
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  ) {
    return getSegment(segmentId).andThen((segment) {
      final size = sizeInWords * CapnpConstants.bytesPerWord;
      if (start < 0 || start + size > segment.lengthInBytes) {
        return const Err(MessageContainsOutOfBoundsPointerCapnpError());
      }

      return readLimiter.canRead(sizeInWords).map(
            (_) =>
                segment.buffer.asByteData(segment.offsetInBytes + start, size),
          );
    });
  }

  @override
  CapnpResult<void> amplifiedRead(int virtualAmount) =>
      readLimiter.canRead(virtualAmount);
}

class NullArena extends ReaderArena {
  const NullArena();

  @override
  CapnpResult<ByteData> getSegment(SegmentId id) =>
      const Err(TriedToReadFromNullArenaCapnpError());

  @override
  CapnpResult<void> checkOffset(SegmentId segmentId, int offset) =>
      const Ok(null);
  @override
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  ) =>
      Ok(ByteData(sizeInWords * CapnpConstants.bytesPerWord));

  @override
  CapnpResult<void> amplifiedRead(int virtualAmount) => const Ok(null);
}

// abstract class BuilderArena extends ReaderArena {}

// class BuilderArenaImpl extends BuilderArena {
//   BuilderArenaImpl() : segments = [];

//   final List<BuilderSegment> segments;
// }

// class BuilderSegment {
//   final ByteData data;
//   int allocated;
// }
