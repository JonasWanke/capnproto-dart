import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../constants.dart';
import '../pointer.dart';
import '../segment.dart';

/// https://capnproto.org/encoding.html#lists
abstract class CapnpList {
  CapnpList(ListPointer pointer)
      : assert(pointer != null),
        segmentView = pointer.targetView;

  final SegmentView segmentView;
}

// Bool list:
class BoolList extends ListMixin<bool> {
  BoolList._(ByteBuffer buffer, int offsetInBytes, this.length)
      : assert(buffer != null),
        assert(offsetInBytes != null),
        assert(length != null),
        assert(offsetInBytes + (length / CapnpConstants.bitsPerByte).ceil() !=
            null),
        data = buffer.asByteData(
            offsetInBytes, (length / CapnpConstants.bitsPerByte).ceil());

  final ByteData data;

  @override
  final int length;
  @override
  set length(newLength) =>
      throw UnsupportedError('Cannot resize a fixed-length list');

  @override
  bool operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, 'index');
    }

    final byte = data.getUint8(index ~/ CapnpConstants.bitsPerByte);
    final bitIndex = index % CapnpConstants.bitsPerByte;
    final bit = (byte >> bitIndex) & 1;
    return bit == 1;
  }

  @override
  void operator []=(int index, bool value) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, 'index');
    }

    final byteIndex = index ~/ CapnpConstants.bitsPerByte;
    final bitIndex = index % CapnpConstants.bitsPerByte;
    final setBit = 1 << bitIndex;
    final byte = data.getUint8(byteIndex) & ~setBit;
    final bit = value ? setBit : 0;
    data.setUint8(byteIndex, byte | bit);
  }
}

// Copied & modified from https://github.com/dart-lang/sdk/blob/6fe15f6df93150b377c306d15b1173454fda48c2/sdk/lib/internal/list.dart#L89-L193
mixin _UnmodifiableListMixin<E> on List<E> {
  /// This operation is not supported by an unmodifiable list.
  @override
  void operator []=(int index, E value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  // ignore: avoid_setters_without_getters
  set length(int newLength) => throw UnsupportedError(
      'Cannot change the length of an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  // ignore: avoid_setters_without_getters
  set first(E element) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  // ignore: avoid_setters_without_getters
  set last(E element) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void setAll(int at, Iterable<E> iterable) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void add(E value) =>
      throw UnsupportedError('Cannot add to an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void insert(int index, E element) =>
      throw UnsupportedError('Cannot add to an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void insertAll(int at, Iterable<E> iterable) =>
      throw UnsupportedError('Cannot add to an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void addAll(Iterable<E> iterable) =>
      throw UnsupportedError('Cannot add to an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  bool remove(Object element) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void removeWhere(bool Function(E element) test) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void retainWhere(bool Function(E element) test) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void sort([Comparator<E> compare]) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void shuffle([Random random]) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void clear() => throw UnsupportedError('Cannot clear an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  E removeAt(int index) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  E removeLast() =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void removeRange(int start, int end) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void replaceRange(int start, int end, Iterable<E> iterable) =>
      throw UnsupportedError('Cannot remove from an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void fillRange(int start, int end, [E fillValue]) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');
}

extension ByteBufferAsBoolList on ByteBuffer {
  /// Creates a [BoolList] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer. Any changes made to
  /// the `BoolList` will also change the buffer, and vice versa.
  ///
  /// The viewed region start at [offsetInBytes] and contains [length] bytes.
  /// If [length] is omitted, the range extends to the end of the buffer.
  ///
  /// The start index and length must describe a valid range of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + (length / 8).ceil()` must not be greater than
  ///   [lengthInBytes].
  BoolList asBoolList([int offsetInBytes = 0, int length]) =>
      BoolList._(this, offsetInBytes, length);
}

/// View of a [BoolList] that disallows modification.
class UnmodifiableBoolListView extends ListBase<bool>
    with _UnmodifiableListMixin<bool>
    implements BoolList {
  UnmodifiableBoolListView(BoolList list) : _list = list;

  final BoolList _list;

  @override
  UnmodifiableByteDataView get data => UnmodifiableByteDataView(_list.data);
  ByteBuffer get buffer => UnmodifiableByteBufferView(_list.data.buffer);

  @override
  int get length => _list.length;
  @override
  bool operator [](int index) => _list[index];
}

class CapnpBoolList extends CapnpList {
  CapnpBoolList(ListPointer pointer)
      : assert(pointer != null),
        assert(!pointer.isCompositeList),
        assert(pointer.elementSizeInBits == 1),
        length = pointer.elementCount,
        super(pointer);

  final int length;

  UnmodifiableBoolListView get value {
    final list = segmentView.data.buffer
        .asBoolList(segmentView.totalOffsetInBytes, length);
    return UnmodifiableBoolListView(list);
  }
}

abstract class _ByteBasedList extends CapnpList {
  _ByteBasedList(ListPointer pointer, this.elementSizeInBytes)
      : assert(pointer != null),
        assert(!pointer.isCompositeList),
        assert(pointer.elementSizeInBits ==
            elementSizeInBytes * CapnpConstants.bitsPerByte),
        length = pointer.elementCount,
        super(pointer);

  final int length;
  int get lengthInBytes => length * elementSizeInBytes;
  final int elementSizeInBytes;
}

class CapnpUInt8List extends _ByteBasedList {
  CapnpUInt8List(ListPointer pointer) : super(pointer, 1);

  UnmodifiableUint8ListView get value {
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, lengthInBytes);
    return UnmodifiableUint8ListView(list);
  }
}

class Text extends _ByteBasedList {
  Text(ListPointer pointer) : super(pointer, 1);

  String get value {
    // We don't need the final 0-byte.
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, lengthInBytes - 1);
    return utf8.decode(list);
  }
}

class CompositeList<T> extends CapnpList {
  factory CompositeList(ListPointer pointer) {
    final tagWord = StructPointer.fromView(pointer.segmentView.subview(0, 1));
    final elementCount = tagWord.offsetInWords;
    return CompositeList._(
      pointer,
      elementCount,
    );
  }
  CompositeList._(ListPointer pointer, this.length) : super(pointer);

  final int length;
}
