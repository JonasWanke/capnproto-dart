import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../constants.dart';
import '../data.dart';
import '../error.dart';
import '../serialize.dart';
import '../text.dart';
import '../utils.dart';
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
  inlineComposite;

  int get dataBitsPerElement {
    return switch (this) {
      ElementSize.void_ => 0,
      ElementSize.bit => 1,
      ElementSize.byte => 8,
      ElementSize.twoBytes => 16,
      ElementSize.fourBytes => 32,
      ElementSize.eightBytes => 64,
      ElementSize.pointer => 0,
      ElementSize.inlineComposite => 0,
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
      ElementSize.inlineComposite => 0,
    };
  }
}

@immutable
final class StructSize {
  const StructSize({required this.dataWords, required this.pointerCount})
      : assert(0 <= dataWords && dataWords <= 0xFFFF),
        assert(0 <= pointerCount && pointerCount <= 0xFFFF);

  factory StructSize.max(StructSize a, StructSize b) {
    return StructSize(
      dataWords: max(a.dataWords, b.dataWords),
      pointerCount: max(a.pointerCount, b.pointerCount),
    );
  }

  final int dataWords;
  final int pointerCount;
  int get totalWords =>
      dataWords + pointerCount * CapnpConstants.wordsPerPointer;

  @override
  bool operator ==(Object other) {
    return other is StructSize &&
        other.dataWords == dataWords &&
        other.pointerCount == pointerCount;
  }

  @override
  int get hashCode => Object.hash(dataWords, pointerCount);

  @override
  String toString() =>
      'StructSize(dataWords: $dataWords, pointersCount: $pointerCount)';
}

@immutable
final class WirePointer {
  WirePointer(this.data)
      : assert(data.lengthInBytes == CapnpConstants.bytesPerPointer);
  WirePointer.fromOffset(ByteData segment, int offsetWords)
      : data = segment.buffer.asByteData(
          segment.offsetInBytes + offsetWords * CapnpConstants.bytesPerPointer,
          CapnpConstants.bytesPerPointer,
        );

  static final nullPointer =
      WirePointer(ByteData(CapnpConstants.bytesPerPointer));

  final ByteData data;

  int get _offsetAndKind => data.getUint32(0, Endian.little);
  set _offsetAndKind(int value) => data.setUint32(0, value, Endian.little);

  int get _offset => (1 + (_offsetAndKind >> 2)) * CapnpConstants.bytesPerWord;

  int get _upper32Bits => data.getUint32(4, Endian.little);
  set _upper32Bits(int value) => data.setUint32(4, value, Endian.little);

  bool get isNull => _offsetAndKind == 0 && _upper32Bits == 0;
  void setNull() {
    _offsetAndKind = 0;
    _upper32Bits = 0;
  }

  WirePointerKind get kind => WirePointerKind.values[_offsetAndKind & 3];

  /// Matches [WirePointerKind.struct] and [WirePointerKind.list], but not
  /// [WirePointerKind.far] and [WirePointerKind.other].
  bool get isPositional => _offsetAndKind & 2 == 0;

  ByteData get target => data.buffer.asByteData(data.offsetInBytes + _offset);

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

    final target = data.offsetInBytes + _offset - segment.offsetInBytes;
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

  // TODO(JonasWanke): merge above getters to `StructSize get structSize`
  StructSize get structSize {
    assert(kind == WirePointerKind.struct);
    return StructSize(
      dataWords: structDataSize,
      pointerCount: structPointerCount,
    );
  }

  set structSize(StructSize size) {
    assert(kind == WirePointerKind.struct);
    _upper32Bits = size.dataWords | (size.pointerCount << 16);
  }

  int get inlineCompositeListElementCount {
    assert(kind == WirePointerKind.struct);
    return _offsetAndKind >> 2;
  }

  void setKindAndTarget(WirePointerKind kind, ByteData target) {
    assert(data.buffer == target.buffer);
    final offset = (target.offsetInBytes - data.offsetInBytes) ~/
            CapnpConstants.bytesPerWord -
        1;
    _offsetAndKind = (offset << 2) | kind.index;
  }

  void setKindWithZeroOffset(WirePointerKind kind) =>
      _offsetAndKind = kind.index;
  void setKindAndTargetForEmptyStruct() {
    // This pointer points at an empty struct. Assuming the [WirePointer] itself
    // is in-bounds, we can set the target to point either at the [WirePointer]
    // itself, or immediately after it. The latter would cause the [WirePointer]
    // to be "null" (since, for an empty struct, the upper 32 bits are going to
    // be zero). So we set an offset of -1, as if the struct were
    // allocated immediately before this pointer, to distinguish it from null.
    _offsetAndKind = 0xFFFFFFFC;
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

  void setListSizeAndCount(ElementSize size, int elementCount) {
    assert(kind == WirePointerKind.list);
    assert(0 <= elementCount && elementCount < 1 << 29);
    _upper32Bits = (elementCount << 3) | size.index;
  }

  int get listInlineCompositeWordCount => listElementCount;
  set listInlineCompositeWordCount(int wordCount) =>
      setListSizeAndCount(ElementSize.inlineComposite, wordCount);

  void setKindAndInlineCompositeListElementCount(
    WirePointerKind kind,
    int elementCount,
  ) {
    assert(0 <= elementCount && elementCount < 1 << 30);
    _offsetAndKind = (elementCount << 2) | kind.index;
  }

  // Far Pointer

  SegmentId get farSegmentId {
    assert(kind == WirePointerKind.far);
    return SegmentId(_upper32Bits);
  }

  set farSegmentId(SegmentId value) {
    assert(kind == WirePointerKind.far);
    _upper32Bits = value.index;
  }

  int get farPositionInSegment {
    assert(kind == WirePointerKind.far);
    return _offsetAndKind >> 3;
  }

  bool get isDoubleFar {
    assert(kind == WirePointerKind.far);
    return (_offsetAndKind >> 2) & 1 != 0;
  }

  void setFar(int positionWords, {required bool isDoubleFar}) {
    _offsetAndKind = (positionWords << 3) |
        (isDoubleFar ? 1 << 2 : 0) |
        WirePointerKind.far.index;
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
    required int nestingLimit,
  }) {
    return arena
        .getSegment(segmentId)
        .andThen(
          (segment) => arena
              .getInterval(segmentId, 0, CapnpConstants.wordsPerPointer)
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
  final SegmentId segmentId;

  final WirePointer pointer;
  bool get isNull => pointer.isNull;

  final int nestingLimit;

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

  CapnpResult<ListReader> getList(
    ByteData? defaultValue, {
    ElementSize? expectedElementSize,
  }) {
    var arena = this.arena;
    var segmentId = this.segmentId;
    var reff = pointer;
    if (reff.isNull) {
      if (defaultValue == null) return Ok(ListReader.defaultReader);

      reff = WirePointer(defaultValue);
      if (reff.isNull) return Ok(ListReader.defaultReader);

      arena = const NullArena();
      segmentId = SegmentId.zero;
    }

    if (nestingLimit <= 0) return const Err(NestingLimitExceededCapnpError());

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
        MessageContainsNonListPointerWhereListPointerWasExpectedCapnpError(),
      );
    }

    final elementSize = reff.listElementSize;
    switch (elementSize) {
      case ElementSize.inlineComposite:
        final wordCount = reff.listInlineCompositeWordCount;

        ByteData data;
        switch (arena.getInterval(segmentId, start, wordCount)) {
          case Ok(:final value):
            data = value;
          case Err(:final error):
            return Err(error);
        }
        final tag = WirePointer.fromOffset(data, 0);
        data = data.buffer
            .asByteData(data.offsetInBytes + CapnpConstants.bytesPerPointer);

        if (tag.kind != WirePointerKind.struct) {
          return const Err(
            InlineCompositeListsOfNonStructTypeAreNotSupportedCapnpError(),
          );
        }

        final elementCount = tag.inlineCompositeListElementCount;
        final dataSize = tag.structDataSize;
        final pointerCount = tag.structPointerCount;
        final wordsPerElement = tag.structWordSize;

        if (elementCount * wordsPerElement > wordCount) {
          return const Err(
            InlineCompositeListsElementsOverrunItsWordCountCapnpError(),
          );
        }

        if (wordsPerElement == 0) {
          // Watch out for lists of zero-sized structs, which can claim to be
          // arbitrarily large without having sent actual data.
          if (arena.amplifiedRead(elementCount) case Err(:final error)) {
            return Err(error);
          }
        }

        // If a struct list was not expected, then presumably a non-struct list
        // was upgraded to a struct list. We need to manipulate the pointer to
        // point at the first field of the struct. Together with the `step`
        // field, this will allow the struct list to be accessed as if it were a
        // primitive list without branching.

        // Check whether the size is compatible.
        switch (expectedElementSize) {
          case null || ElementSize.void_ || ElementSize.inlineComposite:
            break;
          case ElementSize.bit:
            return const Err(
              FoundStructListWhereBitListWasExpectedCapnpError(),
            );
          case ElementSize.byte ||
                ElementSize.twoBytes ||
                ElementSize.fourBytes ||
                ElementSize.eightBytes:
            if (dataSize == 0) {
              return const Err(
                // ignore: lines_longer_than_80_chars
                ExpectedAPrimitiveListButGotAListOfPointerOnlyStructsCapnpError(),
              );
            }
          case ElementSize.pointer:
            if (pointerCount == 0) {
              return const Err(
                ExpectedAPointerListButGotAListOfDataOnlyStructsCapnpError(),
              );
            }
        }

        return Ok(
          ListReader._(
            arena,
            segmentId,
            data,
            elementSize: elementSize,
            length: elementCount,
            stepBits: wordsPerElement * CapnpConstants.bitsPerWord,
            structDataSizeBits: dataSize * CapnpConstants.bitsPerWord,
            structPointerCount: pointerCount,
            nestingLimit: nestingLimit - 1,
          ),
        );

      // ignore: no_default_cases
      default:
        // This is a primitive or pointer list, but all such lists can also be
        // interpreted as struct lists. We need to compute the data size and
        // pointer count for such structs.
        final dataSizeBits = reff.listElementSize.dataBitsPerElement;
        final pointerCount = reff.listElementSize.pointersPerElement;
        final elementCount = reff.listElementCount;
        final step =
            dataSizeBits + pointerCount * CapnpConstants.bitsPerPointer;

        final wordCount = _roundBitsUpToWords(elementCount * step);
        final ByteData data;
        switch (arena.getInterval(segmentId, start, wordCount)) {
          case Ok(:final value):
            data = value;
          case Err(:final error):
            return Err(error);
        }

        if (elementSize == ElementSize.void_) {
          if (arena.amplifiedRead(elementCount) case Err(:final error)) {
            return Err(error);
          }
        }

        if (expectedElementSize != null) {
          if (elementSize == ElementSize.bit &&
              expectedElementSize != ElementSize.bit) {
            return const Err(
              FoundBitListWhereStructListWasExpectedCapnpError(),
            );
          }

          // Verify that the elements are at least as large as the expected
          // type. Note that if we expected `ElementSize.inlineComposite`, the
          // expected sizes here will be zero, because bounds checking will be
          // performed at field access time. So this check here is for the case
          // where we expected a list of some primitive or pointer type.
          if (expectedElementSize.dataBitsPerElement > dataSizeBits ||
              expectedElementSize.pointersPerElement > pointerCount) {
            return const Err(
              MessageContainsListWithIncompatibleElementTypeCapnpError(),
            );
          }
        }

        return Ok(
          ListReader._(
            arena,
            segmentId,
            data,
            elementSize: elementSize,
            length: elementCount,
            stepBits: step,
            structDataSizeBits: dataSizeBits,
            structPointerCount: pointerCount,
            nestingLimit: nestingLimit - 1,
          ),
        );
    }
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
      if (defaultValue == null) return Ok(DataReader(_emptyByteData));

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

class PointerBuilder extends PointerReader {
  PointerBuilder._(BuilderArena super.arena, super.segmentId, super.pointer)
      : super._(nestingLimit: 0x7fffffff);

  factory PointerBuilder.getRoot(
    BuilderArena arena,
    SegmentId segmentId, {
    required int location,
  }) {
    final pointerData = arena
        .getInterval(
          segmentId,
          location,
          CapnpConstants.wordsPerPointer,
        )
        .expect('Failed to get root pointer data.');
    return PointerBuilder._(arena, segmentId, WirePointer(pointerData));
  }

  @override
  BuilderArena get arena => super.arena as BuilderArena;

  StructBuilder initStruct(StructSize size) {
    final (segmentId, reff, data) = _allocate(
      arena,
      this.segmentId,
      pointer,
      size.totalWords,
      WirePointerKind.struct,
    );
    reff.structSize = size;

    return StructBuilder._(
      arena,
      segmentId,
      data: data.offsetWords(0, size.dataWords),
      pointers: data.offsetWords(
        size.dataWords,
        size.pointerCount * CapnpConstants.wordsPerPointer,
      ),
    );
  }

  CapnpResult<StructBuilder> getStructBuilder(
    StructSize size,
    ByteData? defaultValue,
  ) {
    var segmentId = this.segmentId;
    var ref = pointer;
    var refTarget = ref.target;
    if (ref.isNull) {
      if (defaultValue == null) return Ok(initStruct(size));

      final defaultPointer = WirePointer.fromOffset(defaultValue, 0);
      if (defaultPointer.isNull) return Ok(initStruct(size));

      final (newSegmentId, newRef, newRefTarget) =
          _copyMessage(arena, segmentId, defaultPointer, ref);
      segmentId = newSegmentId;
      ref = newRef;
      refTarget = newRefTarget;
    }

    final SegmentId oldSegmentId;
    final WirePointer oldRef;
    final ByteData oldData;
    switch (_followBuilderFars(arena, segmentId, ref, refTarget)) {
      case Ok(:final value):
        oldSegmentId = value.$1;
        oldRef = value.$2;
        oldData = value.$3;
      case Err(:final error):
        return Err(error);
    }
    if (oldRef.kind != WirePointerKind.struct) {
      return const Err(
        // ignore: lines_longer_than_80_chars
        MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError(),
      );
    }

    final oldSize = oldRef.structSize;
    if (oldSize.dataWords >= size.dataWords ||
        oldSize.pointerCount >= size.pointerCount) {
      return Ok(
        StructBuilder._(
          arena,
          oldSegmentId,
          data: oldData.offsetWords(0, oldSize.dataWords),
          pointers:
              oldData.offsetWords(oldSize.dataWords, oldSize.pointerCount),
        ),
      );
    }

    // The space allocated for this struct is too small.
    //
    // Unlike with readers, we can't just run with it and do bounds checks at
    // access time, because how would we handle writes? Instead, we have to
    // copy the struct to a new space now.
    final newSize = StructSize.max(oldSize, size);

    // Don't let allocate() zero out the object just yet.
    _zeroPointerAndFars(arena, ref);

    final (newSegmentId, newRef, newData) = _allocate(
      arena,
      segmentId,
      ref,
      newSize.totalWords,
      WirePointerKind.struct,
    );
    newRef.structSize = newSize;

    // Copy data section.
    oldData.copyWordsTo(newData, oldSize.dataWords);

    // Copy pointer section.
    for (var i = 0; i < oldSize.pointerCount; i++) {
      _transferPointer(
        arena,
        oldSegmentId,
        WirePointer.fromOffset(oldData, oldSize.dataWords + i),
        newSegmentId,
        WirePointer.fromOffset(newData, newSize.dataWords + i),
      );
    }

    oldData.zeroWords(0, oldSize.totalWords);

    return Ok(
      StructBuilder._(
        arena,
        newSegmentId,
        data: oldData.offsetWords(0, oldSize.dataWords),
        pointers: newData.offsetWords(newSize.dataWords, newSize.pointerCount),
      ),
    );
  }

  ListBuilder initList(int length, ElementSize elementSize) {
    assert(
      elementSize != ElementSize.inlineComposite,
      'Should have called `initStructList()` instead.',
    );

    final dataSize = elementSize.dataBitsPerElement;
    final pointerCount = elementSize.pointersPerElement;
    final stepBits = dataSize + pointerCount * CapnpConstants.bitsPerPointer;
    final wordCount = _roundBitsUpToWords(length * stepBits);
    final (segmentId, ref, data) = _allocate(
      arena,
      this.segmentId,
      pointer,
      wordCount,
      WirePointerKind.list,
    );

    ref.setListSizeAndCount(elementSize, length);

    return ListBuilder._(
      arena,
      segmentId,
      data,
      elementSize: elementSize,
      length: length,
      stepBits: stepBits,
      structDataSizeBits: dataSize,
      structPointerCount: pointerCount,
    );
  }

  ListBuilder initStructList(int length, StructSize structSize) {
    final wordsPerElement = structSize.totalWords;

    // Allocate the list, prefixed by a single WirePointer.
    final wordCount = length * wordsPerElement;
    final (segmentId, ref, data) = _allocate(
      arena,
      this.segmentId,
      this.pointer,
      CapnpConstants.wordsPerPointer + wordCount,
      WirePointerKind.list,
    );

    // Initialize the pointer.
    ref.listInlineCompositeWordCount = wordCount;
    final pointer = WirePointer.fromOffset(data, 0);
    pointer.setKindAndInlineCompositeListElementCount(
      WirePointerKind.struct,
      length,
    );
    pointer.structSize = structSize;

    return ListBuilder._(
      arena,
      segmentId,
      data.offsetWords(1),
      elementSize: ElementSize.inlineComposite,
      length: length,
      stepBits: wordsPerElement * CapnpConstants.bitsPerWord,
      structDataSizeBits: structSize.dataWords * CapnpConstants.bitsPerWord,
      structPointerCount: structSize.pointerCount,
    );
  }

  CapnpResult<ListBuilder> getStructList(
    StructSize structSize,
    ByteData? defaultValue,
  ) {
    var originalSegmentId = segmentId;
    var originalRef = pointer;
    var originalData = originalRef.target;
    if (pointer.isNull) {
      if (defaultValue == null) return Ok(ListBuilder.defaultBuilder(arena));

      final defaultRef = WirePointer.fromOffset(defaultValue, 0);
      if (defaultRef.isNull) return Ok(ListBuilder.defaultBuilder(arena));

      final (newOriginalSegment, newOriginalRef, newOriginalData) =
          _copyMessage(arena, originalSegmentId, defaultRef, originalRef);
      originalSegmentId = newOriginalSegment;
      originalRef = newOriginalRef;
      originalData = newOriginalData;
    }

    // We must verify that the pointer has the right size and potentially
    // upgrade it if not.

    final SegmentId oldSegmentId;
    final WirePointer oldRef;
    ByteData oldData;
    switch (_followBuilderFars(
      arena,
      originalSegmentId,
      originalRef,
      originalData,
    )) {
      case Ok(
          value: (final newOldSegmentId, final newOldRef, final newOldData)
        ):
        oldSegmentId = newOldSegmentId;
        oldRef = newOldRef;
        oldData = newOldData;
      case Err(:final error):
        return Err(error);
    }

    if (oldRef.kind != WirePointerKind.list) {
      return const Err(ExistingPointerIsNotAListCapnpError());
    }

    final oldSize = oldRef.listElementSize;
    if (oldSize == ElementSize.inlineComposite) {
      // Existing list is inline composite, but we need to verify that the sizes
      // match.

      final oldTag = WirePointer.fromOffset(oldData, 0);
      oldData = oldData.offsetWords(1);
      if (oldTag.kind != WirePointerKind.struct) {
        return const Err(
          InlineCompositeListWithNonStructElementsNotSupportedCapnpError(),
        );
      }

      final oldStructSize = oldTag.structSize;
      final elementCount = oldTag.inlineCompositeListElementCount;
      if (oldStructSize.dataWords >= structSize.dataWords &&
          oldStructSize.pointerCount >= structSize.pointerCount) {
        // Old size is at least as large as we need. Ship it.
        return Ok(
          ListBuilder._(
            arena,
            oldSegmentId,
            oldData,
            elementSize: ElementSize.inlineComposite,
            length: elementCount,
            stepBits: oldStructSize.totalWords * CapnpConstants.bitsPerWord,
            structDataSizeBits:
                oldStructSize.dataWords * CapnpConstants.bitsPerWord,
            structPointerCount: oldStructSize.pointerCount,
          ),
        );
      }

      // The structs in this list are smaller than expected, probably written
      // using an older version of the protocol. We need to make a copy and
      // expand them.

      final newStructSize = StructSize.max(oldStructSize, structSize);
      final totalSize = newStructSize.totalWords * elementCount;

      // Don't let allocate() zero out the object just yet.
      _zeroPointerAndFars(arena, originalRef);

      var (newSegmentId, newRef, newData) = _allocate(
        arena,
        originalSegmentId,
        originalRef,
        CapnpConstants.wordsPerPointer + totalSize,
        WirePointerKind.list,
      );
      newRef.listInlineCompositeWordCount = totalSize;

      final newTag = WirePointer.fromOffset(newData, 0);
      newTag.setKindAndInlineCompositeListElementCount(
        WirePointerKind.struct,
        elementCount,
      );
      newTag.structSize = newStructSize;

      newData = newData.offsetWords(1);

      for (var i = 0; i < elementCount; i++) {
        // Copy data section.
        oldData.offsetWords(i * oldStructSize.totalWords).copyWordsTo(
              newData.offsetWords(i * newStructSize.totalWords),
              oldStructSize.dataWords,
            );

        // Copy pointer section
        for (var j = 0; j < oldStructSize.pointerCount; j++) {
          _transferPointer(
            arena,
            oldSegmentId,
            WirePointer.fromOffset(
              oldData,
              i * oldStructSize.totalWords + oldStructSize.dataWords,
            ),
            newSegmentId,
            WirePointer.fromOffset(
              newData,
              i * newStructSize.totalWords + newStructSize.dataWords,
            ),
          );
        }
      }

      oldData.zeroWords(-1, 1 + oldStructSize.totalWords * elementCount);

      return Ok(
        ListBuilder._(
          arena,
          newSegmentId,
          newData,
          elementSize: ElementSize.inlineComposite,
          length: elementCount,
          stepBits: newStructSize.totalWords * CapnpConstants.bitsPerWord,
          structDataSizeBits:
              newStructSize.dataWords * CapnpConstants.bitsPerWord,
          structPointerCount: newStructSize.pointerCount,
        ),
      );
    } else {
      // We're upgrading from a non-struct list.

      final oldDataBits = oldSize.dataBitsPerElement;
      final oldPointerCount = oldSize.pointersPerElement;
      final oldStepBits =
          oldDataBits + oldPointerCount * CapnpConstants.bitsPerPointer;
      final elementCount = oldRef.listElementCount;
      if (oldSize == ElementSize.void_) {
        // Nothing to copy, just allocate a new list.
        return Ok(
          PointerBuilder._(arena, originalSegmentId, originalRef)
              .initList(elementCount, ElementSize.inlineComposite),
        );
      }

      // Upgrade to an inline composite list.
      if (oldSize == ElementSize.bit) {
        return const Err(FoundBitListWhereStructListWasExpectedCapnpError());
      }

      // var newDataSize = structSize.dataWords;
      // var newPointerCount =
      final StructSize newStructSize;
      if (oldSize == ElementSize.pointer) {
        newStructSize = StructSize.max(
          structSize,
          const StructSize(dataWords: 0, pointerCount: 1),
        );
      } else {
        // Old list contains data elements, so we need at least one word of
        // data.
        newStructSize = StructSize.max(
          structSize,
          const StructSize(dataWords: 1, pointerCount: 0),
        );
      }

      final totalWords = elementCount * newStructSize.totalWords;

      // Don't let allocate() zero out the object just yet.
      _zeroPointerAndFars(arena, originalRef);

      var (newSegmentId, newRef, newData) = _allocate(
        arena,
        originalSegmentId,
        originalRef,
        CapnpConstants.wordsPerPointer + totalWords,
        WirePointerKind.list,
      );
      newRef.listInlineCompositeWordCount = totalWords;

      final tag = WirePointer.fromOffset(newData, 0);
      tag.setKindAndInlineCompositeListElementCount(
        WirePointerKind.struct,
        elementCount,
      );
      tag.structSize = newStructSize;
      newData = newData.offsetWords(1);

      if (oldSize == ElementSize.pointer) {
        for (var i = 0; i < elementCount; i++) {
          _transferPointer(
            arena,
            oldSegmentId,
            WirePointer.fromOffset(oldData, i),
            newSegmentId,
            WirePointer.fromOffset(
              newData,
              i * newStructSize.totalWords + newStructSize.dataWords,
            ),
          );
        }
      } else {
        for (var i = 0; i < elementCount; i++) {
          oldData
              .offsetBytes(i * oldStepBits ~/ CapnpConstants.bitsPerByte)
              .copyBytesTo(
                newData.offsetBytes(
                  i * newStructSize.totalWords * CapnpConstants.bytesPerWord,
                ),
                oldDataBits,
              );
        }
      }

      // Zero out old location.
      oldData.zeroBytes(0, _roundBitsUpToBytes(oldStepBits * elementCount));

      return Ok(
        ListBuilder._(
          arena,
          newSegmentId,
          newData,
          elementSize: ElementSize.inlineComposite,
          length: elementCount,
          stepBits: newStructSize.totalWords * CapnpConstants.bitsPerWord,
          structDataSizeBits:
              newStructSize.dataWords * CapnpConstants.bitsPerWord,
          structPointerCount: newStructSize.pointerCount,
        ),
      );
    }
  }

  void setText(String value) {
    final bytes = const Utf8Encoder().convert(value);
    final (_, data) = _initTextPointer(bytes.length);
    assert(bytes.length == data.lengthInBytes);
    data.buffer
        .asUint8List(data.offsetInBytes, data.lengthInBytes)
        .setRange(0, data.lengthInBytes, bytes);
  }

  (SegmentId, ByteData) _initTextPointer(int size) {
    // The byte list must include a NUL terminator.
    final byteSize = size + 1;
    final (segmentId, ref, data) = _allocate(
      arena,
      this.segmentId,
      pointer,
      _roundBytesUpToWords(byteSize),
      WirePointerKind.list,
    );

    ref.setListSizeAndCount(ElementSize.byte, byteSize);

    return (segmentId, data.offsetBytes(0, size));
  }

  @useResult
  static (SegmentId, WirePointer, ByteData) _allocate(
    BuilderArena arena,
    SegmentId segmentId,
    WirePointer reff,
    int wordCount,
    WirePointerKind kind,
  ) {
    if (!reff.isNull) _zeroObject(arena, reff);

    if (wordCount == 0 && kind == WirePointerKind.struct) {
      reff.setKindAndTargetForEmptyStruct();
      return (segmentId, reff, reff.data.offsetWords(0, 0));
    }

    if (arena.allocate(segmentId, wordCount)
        case (:final data, wordIndex: final _)?) {
      reff.setKindAndTarget(kind, data);
      return (segmentId, reff, data);
    }

    // Need to allocate in a different segment. We'll need to allocate an extra
    // pointer worth of space to act as the landing pad for a far pointer.
    final amountPlusRef = wordCount + CapnpConstants.wordsPerPointer;
    final (farSegmentId, :wordIndex, :data) =
        arena.allocateAnywhere(amountPlusRef);

    // Set up the original pointer to be a far pointer to the new segment.
    reff.setFar(wordIndex, isDoubleFar: false);
    reff.farSegmentId = farSegmentId;

    // Initialize the landing pad to indicate that the data immediately follows
    // the pad.
    final pad = WirePointer.fromOffset(data, 0);
    final dataWithoutPad = data.offsetWords(1);
    pad.setKindAndTarget(kind, dataWithoutPad);
    return (farSegmentId, pad, dataWithoutPad);
  }

  /// Zero out the pointed-to object. Use when the pointer is about to be
  /// overwritten, making the target object no longer reachable.
  static void _zeroObject(BuilderArena arena, WirePointer reff) {
    switch (reff.kind) {
      case WirePointerKind.struct ||
            WirePointerKind.list ||
            WirePointerKind.other:
        _zeroObjectHelper(arena, reff, reff.target);
      case WirePointerKind.far:
        final segment = arena.getSegmentMut(reff.farSegmentId);
        final pad = WirePointer.fromOffset(segment, reff.farPositionInSegment);

        if (reff.isDoubleFar) {
          final segmentId = pad.farSegmentId;
          final segment = arena.getSegmentMut(segmentId);
          final target = segment.buffer.asByteData(
            segment.offsetInBytes +
                pad.farPositionInSegment * CapnpConstants.bytesPerWord,
          );
          _zeroObjectHelper(arena, pad, target);
        } else {
          _zeroObject(arena, pad);
        }
    }
  }

  static void _zeroObjectHelper(
    BuilderArena arena,
    WirePointer tag,
    ByteData target,
  ) {
    switch (tag.kind) {
      case WirePointerKind.struct:
        final pointerSection = target.offsetWords(tag.structDataSize);
        for (var i = 0; i < tag.structPointerCount; i++) {
          _zeroObject(arena, WirePointer.fromOffset(pointerSection, i));
        }
        target.zeroWords(0, tag.structWordSize);
      case WirePointerKind.list:
        switch (tag.listElementSize) {
          case ElementSize.void_:
            break;
          case ElementSize.bit ||
                ElementSize.byte ||
                ElementSize.twoBytes ||
                ElementSize.fourBytes ||
                ElementSize.eightBytes:
            target.zeroWords(
              0,
              _roundBitsUpToWords(
                tag.listElementCount * tag.listElementSize.dataBitsPerElement,
              ),
            );
          case ElementSize.pointer:
            for (var i = 0; i < tag.listElementCount; i++) {
              _zeroObject(arena, WirePointer.fromOffset(target, i));
            }
            target.zeroWords(0, tag.listElementCount);
          case ElementSize.inlineComposite:
            final elementTag = WirePointer.fromOffset(target, 0);
            assert(
              elementTag.kind == WirePointerKind.struct,
              "Don't know how to handle non-struct inline composite list.",
            );

            final dataSize = elementTag.structDataSize;
            final pointerCount = elementTag.structPointerCount;
            final count = elementTag.inlineCompositeListElementCount;
            if (pointerCount > 0) {
              for (var i = 0; i < count; i++) {
                for (var j = 0; j < pointerCount; j++) {
                  _zeroObject(
                    arena,
                    WirePointer.fromOffset(target, (i + 1) * dataSize + j),
                  );
                }
              }
            }
            target.zeroWords(0, 1 + elementTag.structWordSize * count);
        }
      case WirePointerKind.far:
        throw ArgumentError.value(tag, 'tag', 'Unexpected far pointer.');
      case WirePointerKind.other:
        throw ArgumentError.value(
          tag,
          'tag',
          "Don't know how to handle other pointer kinds.",
        );
    }
  }

  /// Zero out the pointer itself and, if it is a far pointer, zero the landing
  /// pad as well, but do not zero the object body. Used when upgrading.
  static void _zeroPointerAndFars(BuilderArena arena, WirePointer ref) {
    if (ref.kind == WirePointerKind.far) {
      final segment = arena.getSegmentMut(ref.farSegmentId);
      segment.zeroWords(ref.farPositionInSegment, ref.isDoubleFar ? 2 : 1);
    }
    ref.setNull();
  }

  static (SegmentId, WirePointer, ByteData) _copyMessage(
    BuilderArena arena,
    SegmentId segmentId,
    WirePointer source,
    WirePointer destination,
  ) {
    switch (source.kind) {
      case WirePointerKind.struct:
        if (source.isNull) {
          destination.setNull();
          return (segmentId, destination, _emptyByteData);
        }

        final sourceData = source.target;
        final (destinationSegmentId, destinationTag, destinationData) =
            _allocate(
          arena,
          segmentId,
          destination,
          source.structWordSize,
          WirePointerKind.struct,
        );
        _copyStruct(
          arena,
          segmentId,
          sourceData,
          destinationData,
          source.structSize,
        );
        destinationTag.structSize = source.structSize;
        return (destinationSegmentId, destinationTag, destinationData);
      case WirePointerKind.list:
        switch (source.listElementSize) {
          case ElementSize.void_ ||
                ElementSize.bit ||
                ElementSize.byte ||
                ElementSize.twoBytes ||
                ElementSize.fourBytes ||
                ElementSize.eightBytes:
            final wordCount = _roundBitsUpToWords(
              source.listElementCount *
                  source.listElementSize.dataBitsPerElement,
            );
            final sourceData = source.target;
            final (destinationSegmentId, destinationTag, destinationData) =
                _allocate(
              arena,
              segmentId,
              destination,
              wordCount,
              WirePointerKind.list,
            );
            sourceData.copyWordsTo(destinationData, wordCount);
            destinationTag.setListSizeAndCount(
              source.listElementSize,
              source.listInlineCompositeWordCount,
            );
            return (destinationSegmentId, destinationTag, destinationData);
          case ElementSize.pointer:
            final sourceData = source.target;
            final (destinationSegmentId, destinationTag, destinationData) =
                _allocate(
              arena,
              segmentId,
              destination,
              source.listElementCount,
              WirePointerKind.list,
            );
            for (var i = 0; i < source.listElementCount; i++) {
              _copyMessage(
                arena,
                destinationSegmentId,
                WirePointer.fromOffset(sourceData, i),
                WirePointer.fromOffset(destinationData, i),
              );
            }
            destinationTag.setListSizeAndCount(
              ElementSize.pointer,
              source.listElementCount,
            );
            return (destinationSegmentId, destinationTag, destinationData);
          case ElementSize.inlineComposite:
            final sourceData = source.target;
            final (destinationSegmentId, destinationTag, destinationData) =
                _allocate(
              arena,
              segmentId,
              destination,
              source.listInlineCompositeWordCount + 1,
              WirePointerKind.list,
            );

            destinationTag.listInlineCompositeWordCount =
                source.listInlineCompositeWordCount;

            sourceData.copyWordsTo(destinationData, 1);
            final sourceTag = WirePointer.fromOffset(sourceData, 0);

            if (sourceTag.kind != WirePointerKind.struct) {
              throw ArgumentError.value(
                source,
                'source',
                'Inline composite list of non-structs is not supported.',
              );
            }
            final structSize = sourceTag.structSize;
            for (var i = 0; i < source.inlineCompositeListElementCount; i++) {
              _copyStruct(
                arena,
                destinationSegmentId,
                sourceData.offsetWords(1 + i * structSize.totalWords),
                destinationData.offsetWords(1 + i * structSize.totalWords),
                structSize,
              );
            }
            return (destinationSegmentId, destinationTag, destinationData);
        }
      case WirePointerKind.far:
        throw ArgumentError.value(
          source,
          'source',
          'Unchecked message contained a far pointer.',
        );
      case WirePointerKind.other:
        throw ArgumentError.value(
          source,
          'source',
          'Unchecked message contained an other pointer.',
        );
    }
  }

  /// Helper for [_copyMessage].
  static void _copyStruct(
    BuilderArena arena,
    SegmentId segmentId,
    ByteData source,
    ByteData destination,
    StructSize size,
  ) {
    source.copyWordsTo(destination, size.dataWords);

    for (var i = 0; i < size.pointerCount; i++) {
      _copyMessage(
        arena,
        segmentId,
        WirePointer.fromOffset(source, size.dataWords + i),
        WirePointer.fromOffset(destination, size.dataWords + i),
      );
    }
  }

  /// Make [destination] point to the same object as [source]. Both must reside
  /// in the same message, but can be in different segments.
  ///
  /// Caller MUST zero out the source pointer after calling this, to make sure
  /// no later code mistakenly thinks the source location still owns the object.
  /// [_transferPointer] doesn't do this zeroing itself because many callers
  /// transfer several pointers in a loop then zero out the whole section.
  static void _transferPointer(
    BuilderArena arena,
    SegmentId sourceSegmentId,
    WirePointer source,
    SegmentId destinationSegmentId,
    WirePointer destination,
  ) {
    assert(!destination.isNull);
    // We expect the caller to ensure the target is already null so won't leak.

    if (source.isNull) {
      destination.setNull();
      return;
    }

    if (source.isPositional) {
      _transferPointerSplit(
        arena,
        sourceSegmentId,
        source,
        source.target,
        destinationSegmentId,
        destination,
      );
      return;
    }

    source.data.copyWordsTo(destination.data, 1);
  }

  /// Like [_transferPointer], but splits `source` into a tag and a target.
  ///
  /// Particularly useful for OrphanBuilder.
  static void _transferPointerSplit(
    BuilderArena arena,
    SegmentId sourceSegmentId,
    WirePointer sourceTag,
    ByteData sourceData,
    SegmentId destinationSegmentId,
    WirePointer destination,
  ) {
    if (destinationSegmentId == sourceSegmentId) {
      // Same segment, so create a direct pointer.

      if (sourceTag.kind == WirePointerKind.struct &&
          sourceTag.structWordSize == 0) {
        destination.setKindAndTargetForEmptyStruct();
      } else {
        destination.setKindAndTarget(sourceTag.kind, sourceData);
      }

      // We can just copy the upper 32 bits.
      destination._upper32Bits = sourceTag._upper32Bits;
      return;
    }

    // Need to create a far pointer. Try to allocate it in the same segment as
    // the source, so that it doesn't need to be a double-far.
    if (arena.allocate(sourceSegmentId, 1)
        case (:final data, :final wordIndex)?) {
      // Simple landing pad is just a pointer.
      final sourceSegment = arena.getSegmentMut(sourceSegmentId);
      assert(
        wordIndex * CapnpConstants.bytesPerWord < sourceSegment.lengthInBytes,
      );

      final landingPad = WirePointer(data);
      landingPad.setKindAndTarget(sourceTag.kind, sourceData);
      landingPad._upper32Bits = sourceTag._upper32Bits;

      destination.setFar(wordIndex, isDoubleFar: false);
      destination.farSegmentId = sourceSegmentId;
      return;
    }

    // Darn, need a double-far.
    final (farSegmentId, data: farData, wordIndex: farWordIndex) =
        arena.allocateAnywhere(2);

    final sourceSegment = arena.getSegmentMut(sourceSegmentId);

    final landingPad = WirePointer.fromOffset(farData, 0);
    landingPad.setFar(
      (sourceData.offsetInBytes - sourceSegment.offsetInBytes) ~/
          CapnpConstants.bytesPerWord,
      isDoubleFar: false,
    );
    landingPad.farSegmentId = sourceSegmentId;

    final landingPad1 = WirePointer.fromOffset(farData, 1);
    landingPad1.setKindWithZeroOffset(sourceTag.kind);
    landingPad1._upper32Bits = sourceTag._upper32Bits;

    destination.setFar(farWordIndex, isDoubleFar: true);
    destination.farSegmentId = farSegmentId;
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
  final pad = WirePointer.fromOffset(newPointerData, 0);

  if (!reff.isDoubleFar) {
    return pad
        ._targetFromSegment(arena, farSegmentId)
        .map((target) => (pad, farSegmentId, target));
  }

  // Landing pad is another far pointer. It is followed by a tag describing the
  // pointed-to object.
  final tag = WirePointer.fromOffset(newPointerData, 1);
  final doubleFarSegmentId = pad.farSegmentId;

  return Ok((tag, doubleFarSegmentId, pad.farPositionInSegment));
}

/// If [ref] is a far pointer, follow it. On return, [ref] will have been
/// updated to point at a [WirePointer] that contains the type information about
/// the target object, and a pointer to the object contents is returned. The
/// caller must NOT use `ref.target` as this may or may not actually return a
/// valid pointer. [segmentId] is also updated to point at the segment which
/// actually contains the object.
///
/// If [ref] is not a far pointer, this simply returns [refTarget]. Usually,
/// [refTarget] should be the same as `ref.target`, but may not be in cases
/// where [ref] is only a tag.
CapnpResult<(SegmentId, WirePointer, ByteData)> _followBuilderFars(
  BuilderArena arena,
  SegmentId segmentId,
  WirePointer ref,
  ByteData refTarget,
) {
  if (ref.kind != WirePointerKind.far) return Ok((segmentId, ref, refTarget));

  segmentId = ref.farSegmentId;
  var segment = arena.getSegmentMut(segmentId);
  final pad = WirePointer.fromOffset(segment, ref.farPositionInSegment);
  if (!ref.isDoubleFar) return Ok((segmentId, pad, pad.target));

  // Landing pad is another far pointer. It is followed by a tag describing the
  // pointed-to object.
  ref = WirePointer(pad.data.offsetWords(1, 1));

  segmentId = pad.farSegmentId;
  segment = arena.getSegmentMut(segmentId);
  final data = segment.offsetWords(pad.farPositionInSegment);
  return Ok((segmentId, ref, data));
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
    data: _emptyByteData,
    pointers: _emptyByteData,
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
      WirePointer.fromOffset(pointers, index),
      nestingLimit: nestingLimit,
    );
  }
}

class StructBuilder extends StructReader {
  StructBuilder._(
    super.arena,
    super.segmentId, {
    required super.data,
    required super.pointers,
  }) : super._(nestingLimit: 0x7fffffff);

  @override
  BuilderArena get arena => super.arena as BuilderArena;

  // ignore: avoid_positional_boolean_parameters
  void setBool(int index, bool value, bool mask) {
    assert(index >= 0);
    final byteIndex = index ~/ CapnpConstants.bitsPerByte;
    final bitIndex = index % CapnpConstants.bitsPerByte;
    final byte = data.getInt8(byteIndex);
    data.setInt8(
      byteIndex,
      (byte & ~(1 << bitIndex)) | (value ^ mask ? 1 << bitIndex : 0),
    );
  }

  // Integers

  void setInt8(int index, int value, int mask) {
    assert(index >= 0);
    data.setInt8(index, value ^ mask);
  }

  void setUint8(int index, int value, int mask) {
    assert(index >= 0);
    data.setUint8(index, value ^ mask);
  }

  void setInt16(int index, int value, int mask) {
    assert(index >= 0);
    data.setInt16(index * 2, value ^ mask, Endian.little);
  }

  void setUint16(int index, int value, int mask) {
    assert(index >= 0);
    data.setUint16(index * 2, value ^ mask, Endian.little);
  }

  void setInt32(int index, int value, int mask) {
    assert(index >= 0);
    data.setInt32(index * 4, value ^ mask, Endian.little);
  }

  void setUint32(int index, int value, int mask) {
    assert(index >= 0);
    data.setUint32(index * 4, value ^ mask, Endian.little);
  }

  void setInt64(int index, int value, int mask) {
    assert(index >= 0);
    data.setInt64(index * 8, value ^ mask, Endian.little);
  }

  void setUint64(int index, int value, int mask) {
    assert(index >= 0);
    data.setUint64(index * 8, value ^ mask, Endian.little);
  }

  // Floating Point

  static final _floatXorData = ByteData(8);

  void setFloat32(int index, double value, int mask) {
    assert(index >= 0);
    data.setFloat32(index * 4, value, Endian.little);
    if (mask == 0) return;

    final valueBits = _floatXorData.getInt32(0, Endian.little);
    _floatXorData.setInt32(index * 4, valueBits ^ mask, Endian.little);
  }

  void setFloat64(int index, double value, int mask) {
    assert(index >= 0);
    data.setFloat64(index * 8, value, Endian.little);
    if (mask == 0) return;

    final valueBits = _floatXorData.getInt64(0, Endian.little);
    _floatXorData.setInt64(index * 8, valueBits ^ mask, Endian.little);
  }

  // Pointer

  @override
  PointerBuilder getPointerField(int index) {
    assert(index >= 0);
    return PointerBuilder._(
      arena,
      segmentId,
      WirePointer.fromOffset(pointers, index),
    );
  }
}

class ListReader {
  ListReader._(
    this.arena,
    this.segmentId,
    this.data, {
    required this.elementSize,
    required this.length,
    required this.stepBits,
    required this.structDataSizeBits,
    required this.structPointerCount,
    required this.nestingLimit,
  });

  static final defaultReader = ListReader._(
    const NullArena(),
    SegmentId.zero,
    _emptyByteData,
    elementSize: ElementSize.void_,
    length: 0,
    stepBits: 0,
    structDataSizeBits: 0,
    structPointerCount: 0,
    nestingLimit: 0x7fffffff,
  );

  final ReaderArena arena;
  final SegmentId segmentId;
  final ByteData data;

  final ElementSize elementSize;
  final int length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  final int stepBits;
  final int structDataSizeBits;
  final int structPointerCount;
  final int nestingLimit;

  StructReader getStructElement(int index) {
    assert(0 <= index && index < length);
    final indexByte = (index * stepBits) ~/ CapnpConstants.bitsPerByte;
    final structDataLength = structDataSizeBits ~/ CapnpConstants.bitsPerByte;
    return StructReader._(
      arena,
      segmentId,
      data: data.buffer.asByteData(
        data.offsetInBytes + indexByte,
        structDataLength,
      ),
      pointers: data.buffer.asByteData(
        data.offsetInBytes + indexByte + structDataLength,
        structPointerCount * CapnpConstants.bytesPerPointer,
      ),
      nestingLimit: nestingLimit - 1,
    );
  }
}

class ListBuilder extends ListReader {
  ListBuilder._(
    super.arena,
    super.segmentId,
    super.data, {
    required super.elementSize,
    required super.length,
    required super.stepBits,
    required super.structDataSizeBits,
    required super.structPointerCount,
  }) : super._(nestingLimit: 0x7fffffff);

  factory ListBuilder.defaultBuilder(BuilderArena arena) {
    return ListBuilder._(
      arena,
      SegmentId.zero,
      _emptyByteData,
      elementSize: ElementSize.void_,
      length: 0,
      stepBits: 0,
      structDataSizeBits: 0,
      structPointerCount: 0,
    );
  }

  @override
  StructBuilder getStructElement(int index) {
    assert(0 <= index && index < length);
    final indexByte = (index * stepBits) ~/ CapnpConstants.bitsPerByte;
    final structDataLength = structDataSizeBits ~/ CapnpConstants.bitsPerByte;
    return StructBuilder._(
      arena,
      segmentId,
      data: data.buffer.asByteData(
        data.offsetInBytes + indexByte,
        structDataLength,
      ),
      pointers: data.buffer.asByteData(
        data.offsetInBytes + indexByte + structDataLength,
        structPointerCount * CapnpConstants.bytesPerPointer,
      ),
    );
  }
}

int _roundBitsUpToBytes(int bits) =>
    (bits + CapnpConstants.bitsPerByte - 1) ~/ CapnpConstants.bitsPerByte;
int _roundBitsUpToWords(int bits) =>
    (bits + CapnpConstants.bitsPerWord - 1) ~/ CapnpConstants.bitsPerWord;
int _roundBytesUpToWords(int bytes) =>
    (bytes + CapnpConstants.bytesPerWord - 1) ~/ CapnpConstants.bytesPerWord;

final _emptyByteData = ByteData(0);
