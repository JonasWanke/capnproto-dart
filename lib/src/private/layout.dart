import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../error.dart';
import 'arena.dart';

/// Size of a list element.
enum ElementSize {
  void_,
  bit,
  byte,
  twoBytes,
  fourBytes,
  eightBytes,
  pointer,
  composite;

  int get dataBitsPerElement {
    return switch (this) {
      ElementSize.void_ => 0,
      ElementSize.bit => 1,
      ElementSize.byte => 8,
      ElementSize.twoBytes => 16,
      ElementSize.fourBytes => 32,
      ElementSize.eightBytes => 64,
      ElementSize.pointer => 0,
      ElementSize.composite => 0,
    };
  }

  int get pointersPerElement {
    return switch (this) {
      ElementSize.void_ ||
      ElementSize.bit ||
      ElementSize.byte ||
      ElementSize.twoBytes ||
      ElementSize.fourBytes ||
      ElementSize.eightBytes =>
        0,
      ElementSize.pointer => 1,
      ElementSize.composite => 0,
    };
  }
}

@immutable
final class WirePointer {
  const WirePointer(this.data);
  WirePointer.fromSegment(ByteData segment, int start)
      : data = segment.buffer.asByteData(
          segment.offsetInBytes + start,
          CapnpConstants.bytesPerPointer,
        );

  static final zero = WirePointer(ByteData(CapnpConstants.bytesPerPointer));

  final ByteData data;
  int get _offsetAndKind => data.getUint32(0, Endian.little);
  int get _upper32Bits => data.getUint32(4, Endian.little);

  bool get isZero => _offsetAndKind == 0 && _upper32Bits == 0;

  WirePointerKind get kind => WirePointerKind.from(_offsetAndKind & 3);

  /// Matches [WirePointerKind.struct] and [WirePointerKind.list], but not
  /// [WirePointerKind.far] and [WirePointerKind.other].
  bool get isPositional => _offsetAndKind & 2 == 0;

  Result<int, CapnpError> _targetFromSegment(
    ReaderArena arena,
    SegmentId segmentId,
  ) {
    final ByteData segment;
    switch (arena.getSegment(segmentId)) {
      case Ok(:final value):
        segment = value;
      case Err(:final error):
        return Err(error);
    }
    assert(segment.buffer == data.buffer);

    final target = data.offsetInBytes +
        (1 + _offsetAndKind >> 2) * CapnpConstants.bytesPerWord -
        segment.offsetInBytes;
    return arena.checkOffset(segmentId, target).map((_) => target);
  }

  // Struct

  int get structDataSize {
    assert(kind == WirePointerKind.struct);
    return _upper32Bits & 0xFFFF;
  }

  int get structPointerCount {
    assert(kind == WirePointerKind.struct);
    return (_upper32Bits >> 16) & 0xFFFF;
  }

  int get structWordSize {
    assert(kind == WirePointerKind.struct);
    return structDataSize + structPointerCount * CapnpConstants.wordsPerPointer;
  }

  // Far Pointer

  SegmentId get farSegmentId {
    assert(kind == WirePointerKind.far);
    return SegmentId(_upper32Bits);
  }

  int get farPositionInSegment {
    assert(kind == WirePointerKind.far);
    return _offsetAndKind >> 3;
  }

  bool get isDoubleFar {
    assert(kind == WirePointerKind.far);
    return (_offsetAndKind >> 2) & 1 != 0;
  }

  // Other

  @override
  bool operator ==(Object other) {
    return other is WirePointer &&
        other._offsetAndKind == _offsetAndKind &&
        other._upper32Bits == _upper32Bits;
  }

  @override
  int get hashCode => Object.hash(_offsetAndKind, _upper32Bits);

  @override
  String toString() {
    return 'WirePointer(_offsetAndKind: $_offsetAndKind, '
        '_upper32Bits: $_upper32Bits)';
  }
}

enum WirePointerKind {
  struct,
  list,
  far,
  other;

  factory WirePointerKind.from(int value) {
    return switch (value) {
      0 => WirePointerKind.struct,
      1 => WirePointerKind.list,
      2 => WirePointerKind.far,
      3 => WirePointerKind.other,
      _ => throw ArgumentError.value(
          value,
          'value',
          'Invalid WirePointerKind value',
        ),
    };
  }
}

enum PointerType { null_, struct, list, capability }

class PointerReader {
  PointerReader._(
    this.arena,
    this.pointer,
    this.segmentId, {
    required this.nestingLimit,
  });

  static Result<PointerReader, CapnpError> getRoot(
    ReaderArena arena,
    SegmentId segmentId, {
    required int location,
    required int nestingLimit,
  }) {
    return arena
        .getSegment(segmentId)
        .andThen(
          (segment) => arena
              .getInterval(
                segmentId,
                location,
                CapnpConstants.wordsPerPointer,
              )
              .map(WirePointer.new),
        )
        .map(
          (pointer) => PointerReader._(
            arena,
            pointer,
            segmentId,
            nestingLimit: nestingLimit,
          ),
        );
  }

  final ReaderArena arena;
  final WirePointer pointer;
  final SegmentId segmentId;
  final int nestingLimit;

  Result<StructReader, CapnpError> getStruct(ByteData? defaultValue) {
    assert(
      defaultValue == null ||
          defaultValue.lengthInBytes == CapnpConstants.bytesPerPointer,
    );

    var arena = this.arena;
    var segmentId = this.segmentId;
    var reff = pointer;
    if (reff.isZero) {
      if (defaultValue == null) return Ok(StructReader.defaultReader);

      reff = WirePointer(defaultValue);
      if (reff.isZero) return Ok(StructReader.defaultReader);

      arena = const NullArena();
      segmentId = SegmentId.zero;
    }

    if (nestingLimit <= 0) {
      return const Err(MessageIsTooDeeplyNestedOrContainsCyclesCapnpError());
    }

    final int start;
    switch (_followFars(arena, reff, segmentId)) {
      case Ok(value: (final reffValue, final segmentIdValue, final startValue)):
        reff = reffValue;
        segmentId = segmentIdValue;
        start = startValue;
      case Err(:final error):
        return Err(error);
    }

    if (reff.kind != WirePointerKind.struct) {
      return const Err(
        // ignore: lines_longer_than_80_chars
        MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError(),
      );
    }

    final ByteData data;
    switch (arena.getInterval(segmentId, start, reff.structWordSize)) {
      case Ok(:final value):
        data = value;
      case Err(:final error):
        return Err(error);
    }

    final dataSizeWords = reff.structDataSize;
    return Ok(
      StructReader._(
        arena,
        data,
        dataSizeBits: dataSizeWords * CapnpConstants.bitsPerWord,
        pointerCount: reff.structPointerCount,
        nestingLimit: nestingLimit - 1,
      ),
    );
  }
}

/// Follows a [WirePointer] to get a triple containing:
///
/// - the resolved [WirePointer], whose [WirePointer.kind] is something other
///   than [WirePointerKind.far]
/// - the ID of the segment on which the pointed-to object lives
/// - the offset of the pointed-to object in its segment
Result<(WirePointer, SegmentId, int), CapnpError> _followFars(
  ReaderArena arena,
  WirePointer reff,
  SegmentId segmentId,
) {
  if (reff.kind != WirePointerKind.far) {
    return reff
        ._targetFromSegment(arena, segmentId)
        .map((target) => (reff, segmentId, target));
  }

  final farSegmentId = reff.farSegmentId;
  final ByteData newPointerData;
  switch (arena.getInterval(
    farSegmentId,
    reff.farPositionInSegment * CapnpConstants.bytesPerWord,
    reff.isDoubleFar ? 2 : 1,
  )) {
    case Ok(:final value):
      newPointerData = value;
    case Err(:final error):
      return Err(error);
  }
  final pad = WirePointer.fromSegment(newPointerData, 0);

  if (!reff.isDoubleFar) {
    return pad
        ._targetFromSegment(arena, farSegmentId)
        .map((target) => (pad, farSegmentId, target));
  }

  // Landing pad is another far pointer. It is followed by a tag describing the
  // pointed-to object.
  final tag =
      WirePointer.fromSegment(newPointerData, CapnpConstants.bytesPerPointer);
  final doubleFarSegmentId = pad.farSegmentId;

  return Ok((tag, doubleFarSegmentId, pad.farPositionInSegment));
}

class StructReader {
  StructReader._(
    this.arena,
    this.data, {
    required this.dataSizeBits,
    required this.pointerCount,
    required this.nestingLimit,
  });

  static final defaultReader = StructReader._(
    const NullArena(),
    ByteData(0),
    dataSizeBits: 0,
    pointerCount: 0,
    nestingLimit: 0x7fffffff,
  );

  final ReaderArena arena;
  final ByteData data;
  final int dataSizeBits;
  final int pointerCount;
  final int nestingLimit;

  // We need to check the indexes because the struct may have been created with
  // an old version of the protocol that did not contain the field.

  // ignore: avoid_positional_boolean_parameters
  bool getBool(int index, bool mask) {
    assert(index >= 0);
    if (index > dataSizeBits) return mask;

    final byte = data.getInt8(index ~/ CapnpConstants.bitsPerByte);
    final value = byte & (1 << (index % CapnpConstants.bitsPerByte)) != 0;
    return value ^ mask;
  }

  // Integers

  int getInt8(int index, int mask) {
    assert(index >= 0);
    if (index * 8 > dataSizeBits) return mask;
    return data.getInt8(index) ^ mask;
  }

  int getUint8(int index, int mask) {
    assert(index >= 0);
    if (index * 8 > dataSizeBits) return mask;
    return data.getUint8(index) ^ mask;
  }

  int getInt16(int index, int mask) {
    assert(index >= 0);
    if (index * 16 > dataSizeBits) return mask;
    return data.getInt16(index * 2, Endian.little) ^ mask;
  }

  int getUint16(int index, int mask) {
    assert(index >= 0);
    if (index * 16 > dataSizeBits) return mask;
    return data.getUint16(index * 2, Endian.little) ^ mask;
  }

  int getInt32(int index, int mask) {
    assert(index >= 0);
    if (index * 32 > dataSizeBits) return mask;
    return data.getInt32(index * 4, Endian.little) ^ mask;
  }

  int getUint32(int index, int mask) {
    assert(index >= 0);
    if (index * 32 > dataSizeBits) return mask;
    return data.getUint32(index * 4, Endian.little) ^ mask;
  }

  int getInt64(int index, int mask) {
    assert(index >= 0);
    if (index * 64 > dataSizeBits) return mask;
    return data.getInt64(index * 8, Endian.little) ^ mask;
  }

  int getUint64(int index, int mask) {
    assert(index >= 0);
    if (index * 64 > dataSizeBits) return mask;
    return data.getUint64(index * 8, Endian.little) ^ mask;
  }

  // Floating Point

  static final _floatXorData = ByteData(8);

  double getFloat32(int index, int mask) {
    assert(index >= 0);
    final isOutOfBounds = index * 32 >= dataSizeBits;
    if (mask == 0) {
      if (isOutOfBounds) return 0;
      return data.getFloat32(index * 4, Endian.little);
    }

    final valueBits =
        isOutOfBounds ? 0 : data.getUint32(index * 4, Endian.little);
    // We need to perform a bitwise XOR on the float to apply the mask. [data]
    // might be unmodifiable, so we use a temporary buffer.
    _floatXorData.setInt32(0, valueBits ^ mask);
    return _floatXorData.getFloat32(0);
  }

  double getFloat64(int index, int mask) {
    assert(index >= 0);
    final isOutOfBounds = index * 64 >= dataSizeBits;
    if (mask == 0) {
      if (isOutOfBounds) return 0;
      return data.getFloat64(index * 8, Endian.little);
    }

    // TODO(JonasWanke): Avoid 64 bit ints completely to support JS?
    final valueBits =
        isOutOfBounds ? 0 : data.getUint64(index * 8, Endian.little);
    // We need to perform a bitwise XOR on the float to apply the mask. [data]
    // might be unmodifiable, so we use a temporary buffer.
    _floatXorData.setInt64(0, valueBits ^ mask);
    return _floatXorData.getFloat64(0);
  }
}
