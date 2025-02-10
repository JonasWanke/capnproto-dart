import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../data.dart';
import '../error.dart';
import '../text.dart';
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

  static final nullPointer =
      WirePointer(ByteData(CapnpConstants.bytesPerPointer));

  final ByteData data;
  int get _offsetAndKind => data.getUint32(0, Endian.little);
  int get _upper32Bits => data.getUint32(4, Endian.little);

  bool get isNull => _offsetAndKind == 0 && _upper32Bits == 0;

  WirePointerKind get kind => WirePointerKind.values[_offsetAndKind & 3];

  /// Matches [WirePointerKind.struct] and [WirePointerKind.list], but not
  /// [WirePointerKind.far] and [WirePointerKind.other].
  bool get isPositional => _offsetAndKind & 2 == 0;

  CapnpResult<int> _targetFromSegment(
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

  // List

  ElementSize get listElementSize {
    assert(kind == WirePointerKind.list);
    return ElementSize.values[_upper32Bits & 7];
  }

  int get listElementCount {
    assert(kind == WirePointerKind.list);
    return _upper32Bits >> 3;
  }

  int get listInlineCompositeWordCount => listElementCount;

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

enum WirePointerKind { struct, list, far, other }

enum PointerType { null_, struct, list, capability }

class PointerReader {
  PointerReader._(
    this.arena,
    this.segmentId,
    this.pointer, {
    required this.nestingLimit,
  });

  static final defaultReader = PointerReader._(
    const NullArena(),
    SegmentId.zero,
    WirePointer.nullPointer,
    nestingLimit: 0x7fffffff,
  );

  static CapnpResult<PointerReader> getRoot(
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
            segmentId,
            pointer,
            nestingLimit: nestingLimit,
          ),
        );
  }

  final ReaderArena arena;
  final WirePointer pointer;
  final SegmentId segmentId;
  final int nestingLimit;

  bool get isNull => pointer.isNull;

  CapnpResult<StructReader> getStruct(ByteData? defaultValue) {
    assert(
      defaultValue == null ||
          defaultValue.lengthInBytes == CapnpConstants.bytesPerPointer,
    );

    var arena = this.arena;
    var segmentId = this.segmentId;
    var reff = pointer;
    if (reff.isNull) {
      if (defaultValue == null) return Ok(StructReader.defaultReader);

      reff = WirePointer(defaultValue);
      if (reff.isNull) return Ok(StructReader.defaultReader);

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
    switch (arena.getInterval(segmentId, start, reff.structDataSize)) {
      case Ok(:final value):
        data = value;
      case Err(:final error):
        return Err(error);
    }

    final ByteData pointers;
    switch (arena.getInterval(
      segmentId,
      start + data.lengthInBytes,
      reff.structPointerCount,
    )) {
      case Ok(:final value):
        pointers = value;
      case Err(:final error):
        return Err(error);
    }

    return Ok(
      StructReader._(
        arena,
        segmentId,
        data: data,
        pointers: pointers,
        nestingLimit: nestingLimit - 1,
      ),
    );
  }

  CapnpResult<TextReader> getText(ByteData? defaultValue) {
    assert(
      defaultValue == null ||
          defaultValue.lengthInBytes == CapnpConstants.bytesPerPointer,
    );

    var arena = this.arena;
    var segmentId = this.segmentId;
    var reff = pointer;
    if (reff.isNull) {
      if (defaultValue == null) return Ok(TextReader(Uint8List(0)));

      reff = WirePointer(defaultValue);
      arena = const NullArena();
      segmentId = SegmentId.zero;
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

    if (reff.kind != WirePointerKind.list) {
      return const Err(
        MessageContainsNonListPointerWhereTextWasExpectedCapnpError(),
      );
    }
    if (reff.listElementSize != ElementSize.byte) {
      return const Err(
        MessageContainsListPointerOfNonBytesWhereTextWasExpectedCapnpError(),
      );
    }

    final size = reff.listElementCount;
    final ByteData data;
    switch (arena.getInterval(segmentId, start, _roundBytesUpToWords(size))) {
      case Ok(:final value):
        data = value;
      case Err(:final error):
        return Err(error);
    }

    if (size == 0 || data.getUint8(size - 1) != 0) {
      return const Err(MessageContainsTextThatIsNotNULTerminatedCapnpError());
    }

    return Ok(
      TextReader(data.buffer.asUint8List(data.offsetInBytes, size - 1)),
    );
  }

  CapnpResult<DataReader> getData(ByteData? defaultValue) {
    assert(
      defaultValue == null ||
          defaultValue.lengthInBytes == CapnpConstants.bytesPerPointer,
    );

    var arena = this.arena;
    var segmentId = this.segmentId;
    var reff = pointer;
    if (reff.isNull) {
      if (defaultValue == null) return Ok(DataReader(ByteData(0)));

      reff = WirePointer(defaultValue);
      arena = const NullArena();
      segmentId = SegmentId.zero;
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

    if (reff.kind != WirePointerKind.list) {
      return const Err(
        MessageContainsNonListPointerWhereDataWasExpectedCapnpError(),
      );
    }
    if (reff.listElementSize != ElementSize.byte) {
      return const Err(
        MessageContainsListPointerOfNonBytesWhereDataWasExpectedCapnpError(),
      );
    }

    final size = reff.listElementCount;
    final ByteData data;
    switch (arena.getInterval(segmentId, start, _roundBytesUpToWords(size))) {
      case Ok(:final value):
        data = value;
      case Err(:final error):
        return Err(error);
    }

    return Ok(DataReader(data.buffer.asByteData(data.offsetInBytes, size)));
  }
}

/// Follows a [WirePointer] to get a triple containing:
///
/// - the resolved [WirePointer], whose [WirePointer.kind] is something other
///   than [WirePointerKind.far]
/// - the ID of the segment on which the pointed-to object lives
/// - the offset of the pointed-to object in its segment
CapnpResult<(WirePointer, SegmentId, int)> _followFars(
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
    this.segmentId, {
    required this.data,
    required this.pointers,
    required this.nestingLimit,
  });

  static final defaultReader = StructReader._(
    const NullArena(),
    SegmentId.zero,
    data: ByteData(0),
    pointers: ByteData(0),
    nestingLimit: 0x7fffffff,
  );

  final ReaderArena arena;
  final SegmentId segmentId;

  final ByteData data;
  int get dataSize => data.lengthInBytes;

  final ByteData pointers;
  int get pointerCount =>
      pointers.lengthInBytes ~/ CapnpConstants.bytesPerPointer;

  final int nestingLimit;

  // We need to check the indexes because the struct may have been created with
  // an old version of the protocol that did not contain the field.

  // ignore: avoid_positional_boolean_parameters
  bool getBool(int index, bool mask) {
    assert(index >= 0);
    if (index > dataSize) return mask;

    final byte = data.getInt8(index ~/ CapnpConstants.bitsPerByte);
    final value = byte & (1 << (index % CapnpConstants.bitsPerByte)) != 0;
    return value ^ mask;
  }

  // Integers

  int getInt8(int index, int mask) {
    assert(index >= 0);
    if (index > dataSize) return mask;
    return data.getInt8(index) ^ mask;
  }

  int getUint8(int index, int mask) {
    assert(index >= 0);
    if (index > dataSize) return mask;
    return data.getUint8(index) ^ mask;
  }

  int getInt16(int index, int mask) {
    assert(index >= 0);
    if (index * 2 > dataSize) return mask;
    return data.getInt16(index * 2, Endian.little) ^ mask;
  }

  int getUint16(int index, int mask) {
    assert(index >= 0);
    if (index * 2 > dataSize) return mask;
    return data.getUint16(index * 2, Endian.little) ^ mask;
  }

  int getInt32(int index, int mask) {
    assert(index >= 0);
    if (index * 4 > dataSize) return mask;
    return data.getInt32(index * 4, Endian.little) ^ mask;
  }

  int getUint32(int index, int mask) {
    assert(index >= 0);
    if (index * 4 > dataSize) return mask;
    return data.getUint32(index * 4, Endian.little) ^ mask;
  }

  int getInt64(int index, int mask) {
    assert(index >= 0);
    if (index * 8 > dataSize) return mask;
    return data.getInt64(index * 8, Endian.little) ^ mask;
  }

  int getUint64(int index, int mask) {
    assert(index >= 0);
    if (index * 8 > dataSize) return mask;
    return data.getUint64(index * 8, Endian.little) ^ mask;
  }

  // Floating Point

  static final _floatXorData = ByteData(8);

  double getFloat32(int index, int mask) {
    assert(index >= 0);
    final isOutOfBounds = index * 4 >= dataSize;
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
    final isOutOfBounds = index * 8 >= dataSize;
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

  // Pointer

  PointerReader getPointerField(int index) {
    assert(index >= 0);
    if (index >= pointerCount) return PointerReader.defaultReader;
    return PointerReader._(
      arena,
      segmentId,
      WirePointer.fromSegment(pointers, index),
      nestingLimit: nestingLimit,
    );
  }
}

int _roundBytesUpToWords(int bytes) =>
    (bytes + CapnpConstants.bytesPerWord - 1) ~/ CapnpConstants.bytesPerWord;
