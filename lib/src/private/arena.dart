import 'dart:typed_data';

import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../error.dart';
import '../message.dart';
import 'read_limiter.dart';

// ignore: avoid-unused-parameters
extension type const SegmentId(int index) {
  static const zero = SegmentId(0);
}

abstract class ReaderArena {
  const ReaderArena();

  Result<ByteData, CapnpError> getSegment(SegmentId id);

  Result<void, CapnpError> checkOffset(SegmentId segmentId, int offset);
  Result<ByteData, CapnpError> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  );
}

class ReaderArenaImpl extends ReaderArena {
  ReaderArenaImpl(this._segments, ReaderOptions options)
      : readLimiter = ReadLimiter(options.traversalLimitInWords),
        nestingLimit = options.nestingLimit;

  final List<ByteData> _segments;
  final ReadLimiter readLimiter;
  final int nestingLimit;

  @override
  Result<ByteData, CapnpError> getSegment(SegmentId id) {
    if (id.index < 0 || id.index >= _segments.length) {
      return Err(InvalidSegmentIdCapnpError(id));
    }
    return Ok(_segments[id.index]);
  }

  @override
  Result<void, CapnpError> checkOffset(SegmentId segmentId, int offset) {
    return getSegment(segmentId).andThen((segment) {
      if (offset < 0 || offset > segment.lengthInBytes) {
        return const Err(MessageContainsOutOfBoundsPointerCapnpError());
      }

      return const Ok(null);
    });
  }

  @override
  Result<ByteData, CapnpError> getInterval(
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
}

class NullArena extends ReaderArena {
  const NullArena();

  @override
  Result<ByteData, CapnpError> getSegment(SegmentId id) =>
      const Err(TriedToReadFromNullArenaCapnpError());

  @override
  Result<void, CapnpError> checkOffset(SegmentId segmentId, int offset) =>
      const Ok(null);
  @override
  Result<ByteData, CapnpError> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  ) =>
      Ok(ByteData(sizeInWords * CapnpConstants.bytesPerWord));
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
