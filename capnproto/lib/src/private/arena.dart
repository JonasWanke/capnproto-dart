import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../error.dart';
import '../message.dart';
import '../serialize.dart';
import '../utils.dart';
import 'read_limiter.dart';

abstract class ReaderArena {
  const ReaderArena();

  CapnpResult<ByteData> getSegment(SegmentId id);

  CapnpResult<void> checkOffset(SegmentId segmentId, int offset);
  CapnpResult<ByteData> getOffset(SegmentId segmentId, int offset);
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  );
  CapnpResult<void> amplifiedRead(int virtualAmount);

  int get sizeInWords;
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
  CapnpResult<ByteData> getOffset(SegmentId segmentId, int offset) {
    return getSegment(segmentId).andThen((segment) {
      if (offset < 0 || offset > segment.lengthInBytes) {
        return const Err(MessageContainsOutOfBoundsPointerCapnpError());
      }

      return Ok(segment.offsetBytes(offset));
    });
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

  @override
  int get sizeInWords {
    var result = 0;
    for (var i = 0; i < _segments.length; i++) {
      final segment = _segments.getSegment(SegmentId(i));
      result += (segment?.lengthInBytes ?? 0) ~/ CapnpConstants.bytesPerWord;
    }
    return result;
  }
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
  CapnpResult<ByteData> getOffset(SegmentId segmentId, int offset) =>
      Ok(ByteData(0));
  @override
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  ) =>
      Ok(ByteData(sizeInWords * CapnpConstants.bytesPerWord));

  @override
  CapnpResult<void> amplifiedRead(int virtualAmount) => const Ok(null);

  @override
  int get sizeInWords => 0;
}

abstract class BuilderArena extends ReaderArena {
  ({int wordIndex, ByteData data})? allocate(
    SegmentId segmentId,
    int wordCount,
  );
  (SegmentId, {int wordIndex, ByteData data}) allocateAnywhere(int wordCount);

  ByteData getSegmentMut(SegmentId id);
}

class BuilderArenaImpl extends BuilderArena {
  BuilderArenaImpl({HeapAllocator? allocator})
      : allocator = allocator ?? HeapAllocator(),
        segments = [];

  final HeapAllocator allocator;

  final List<BuilderSegment> segments;
  List<ByteData> get segmentsForOutput {
    return segments
        .map(
          (it) => it.data.buffer.asByteData(
            it.data.offsetInBytes,
            it.allocatedWords * CapnpConstants.bytesPerWord,
          ),
        )
        .toList();
  }

  int get length => segments.length;
  bool get isEmpty => segments.isEmpty;
  bool get isNotEmpty => segments.isNotEmpty;

  void allocateSegment(int minimumSizeWords) => segments
      .add(BuilderSegment(allocator.allocateSegment(minimumSizeWords), 0));

  @override
  ({int wordIndex, ByteData data})? allocate(
    SegmentId segmentId,
    int wordCount,
  ) {
    final segment = segments[segmentId.index];
    if (wordCount >
        segment.data.lengthInBytes ~/ CapnpConstants.bytesPerWord -
            segment.allocatedWords) {
      return null;
    }

    final wordIndex = segment.allocatedWords;
    final start = wordIndex * CapnpConstants.bytesPerWord;
    segment._allocatedWords += wordCount;
    return (
      wordIndex: wordIndex,
      data: segment.data.buffer.asByteData(
        segment.data.offsetInBytes + start,
        wordCount * CapnpConstants.bytesPerWord,
      ),
    );
  }

  @override
  (SegmentId, {int wordIndex, ByteData data}) allocateAnywhere(int wordCount) {
    // First, try the existing segments, then try allocating a new segment.
    for (var i = 0; i < segments.length; i++) {
      final segmentId = SegmentId(i);
      if (allocate(segmentId, wordCount)
          case (:final wordIndex, :final data)?) {
        return (segmentId, wordIndex: wordIndex, data: data);
      }
    }

    // Need to allocate a new segment.
    final segmentId = SegmentId(segments.length);
    allocateSegment(wordCount);
    final (:wordIndex, :data) = allocate(segmentId, wordCount)!;
    return (segmentId, wordIndex: wordIndex, data: data);
  }

  @override
  CapnpResult<ByteData> getSegment(SegmentId id) => Ok(getSegmentMut(id));
  @override
  ByteData getSegmentMut(SegmentId id) {
    final segment = segments[id.index];
    return segment.data.buffer
        .asByteData(segment.data.offsetInBytes, segment.allocatedWords);
  }

  @override
  CapnpResult<void> checkOffset(SegmentId segmentId, int offset) =>
      const Ok(null);

  @override
  CapnpResult<ByteData> getOffset(SegmentId segmentId, int offset) {
    final segment = getSegmentMut(segmentId);
    assert(segment.offsetInBytes == 0);

    if (offset < 0 || offset > segment.buffer.lengthInBytes) {
      return const Err(MessageContainsOutOfBoundsPointerCapnpError());
    }

    return Ok(segment.offsetBytes(offset));
  }

  @override
  CapnpResult<ByteData> getInterval(
    SegmentId segmentId,
    int start,
    int sizeInWords,
  ) {
    final segment = getSegmentMut(segmentId);
    assert(segment.offsetInBytes == 0);

    final size = sizeInWords * CapnpConstants.bytesPerWord;
    if (start < 0 || start + size > segment.buffer.lengthInBytes) {
      return const Err(MessageContainsOutOfBoundsPointerCapnpError());
    }

    return Ok(segment.buffer.asByteData(start, size));
  }

  @override
  CapnpResult<void> amplifiedRead(int virtualAmount) => const Ok(null);

  @override
  int get sizeInWords => segments.map((it) => it.allocatedWords).sum;
}

class HeapAllocator {
  HeapAllocator({int firstSegmentWords = 1024})
      : _nextSizeWords = firstSegmentWords;

  static const maxSegmentWords = 1 << 29;

  int _nextSizeWords;
  int get nextSizeWords => _nextSizeWords;

  ByteData allocateSegment(int minimumSizeWords) {
    final size = max(minimumSizeWords, nextSizeWords);
    final data = ByteData(size);
    if (size < maxSegmentWords - nextSizeWords) {
      _nextSizeWords += size;
    } else {
      _nextSizeWords = nextSizeWords + maxSegmentWords;
    }
    return data;
  }
}

class BuilderSegment {
  BuilderSegment(this.data, this._allocatedWords)
      : assert(
          _allocatedWords * CapnpConstants.bytesPerWord < data.lengthInBytes,
        );

  final ByteData data;

  int _allocatedWords;
  int get allocatedWords => _allocatedWords;
}
