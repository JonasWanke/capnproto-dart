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
      : segmentView = pointer.targetView;

  final SegmentView segmentView;
}

// Bool list:
class BoolList extends ListMixin<bool> {
  BoolList._(ByteBuffer buffer, int offsetInBytes, this.length)
      : data = buffer.asByteData(
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
  bool remove(Object? element) =>
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
  void sort([Comparator<E>? compare]) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');

  /// This operation is not supported by an unmodifiable list.
  @override
  void shuffle([Random? random]) =>
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
  void fillRange(int start, int end, [E? fill]) =>
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
  BoolList asBoolList([int offsetInBytes = 0, int? length]) {
    return BoolList._(
      this,
      offsetInBytes,
      length ?? (lengthInBytes - offsetInBytes) * CapnpConstants.bitsPerByte,
    );
  }
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
      : assert(!pointer.isCompositeList),
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
      : assert(!pointer.isCompositeList),
        assert(pointer.elementSizeInBits ==
            elementSizeInBytes * CapnpConstants.bitsPerByte),
        length = pointer.elementCount,
        super(pointer);

  final int length;
  int get lengthInBytes => length * elementSizeInBytes;
  final int elementSizeInBytes;
}

// Unsigned integer lists:
class CapnpUInt8List extends _ByteBasedList {
  CapnpUInt8List(ListPointer pointer) : super(pointer, 1);

  UnmodifiableUint8ListView get value {
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableUint8ListView(list);
  }
}

class CapnpUInt16List extends _ByteBasedList {
  CapnpUInt16List(ListPointer pointer) : super(pointer, 2);

  UnmodifiableUint16ListView get value {
    final list = segmentView.data.buffer
        .asUint16List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableUint16ListView(list);
  }
}

class CapnpUInt32List extends _ByteBasedList {
  CapnpUInt32List(ListPointer pointer) : super(pointer, 4);

  UnmodifiableUint32ListView get value {
    final list = segmentView.data.buffer
        .asUint32List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableUint32ListView(list);
  }
}

class CapnpUInt64List extends _ByteBasedList {
  CapnpUInt64List(ListPointer pointer) : super(pointer, 8);

  UnmodifiableUint64ListView get value {
    final list = segmentView.data.buffer
        .asUint64List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableUint64ListView(list);
  }
}

// Signed integer lists:
class CapnpInt8List extends _ByteBasedList {
  CapnpInt8List(ListPointer pointer) : super(pointer, 1);

  UnmodifiableInt8ListView get value {
    final list = segmentView.data.buffer
        .asInt8List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableInt8ListView(list);
  }
}

class CapnpInt16List extends _ByteBasedList {
  CapnpInt16List(ListPointer pointer) : super(pointer, 2);

  UnmodifiableInt16ListView get value {
    final list = segmentView.data.buffer
        .asInt16List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableInt16ListView(list);
  }
}

class CapnpInt32List extends _ByteBasedList {
  CapnpInt32List(ListPointer pointer) : super(pointer, 4);

  UnmodifiableInt32ListView get value {
    final list = segmentView.data.buffer
        .asInt32List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableInt32ListView(list);
  }
}

class CapnpInt64List extends _ByteBasedList {
  CapnpInt64List(ListPointer pointer) : super(pointer, 8);

  UnmodifiableInt64ListView get value {
    final list = segmentView.data.buffer
        .asInt64List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableInt64ListView(list);
  }
}

// Float lists:
class CapnpFloat32List extends _ByteBasedList {
  CapnpFloat32List(ListPointer pointer) : super(pointer, 4);

  UnmodifiableFloat32ListView get value {
    final list = segmentView.data.buffer
        .asFloat32List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableFloat32ListView(list);
  }
}

class CapnpFloat64List extends _ByteBasedList {
  CapnpFloat64List(ListPointer pointer) : super(pointer, 8);

  UnmodifiableFloat64ListView get value {
    final list = segmentView.data.buffer
        .asFloat64List(segmentView.totalOffsetInBytes, length);
    return UnmodifiableFloat64ListView(list);
  }
}

// Text list:
class Text extends _ByteBasedList {
  Text(ListPointer pointer) : super(pointer, 1);

  String get value {
    // We don't need the final 0-byte.
    final list = segmentView.data.buffer
        .asUint8List(segmentView.totalOffsetInBytes, lengthInBytes - 1);
    return utf8.decode(list);
  }
}

// Composite list:
abstract class CompositeList<T> extends ListMixin<T> {
  CompositeList();

  factory CompositeList.fromPointer(CompositeListPointer<T> pointer) =>
      _CompositeList(pointer);
}

class _CompositeList<T> extends CompositeList<T> {
  factory _CompositeList(CompositeListPointer<T> pointer) {
    final tagWord = StructPointer.fromView(pointer.targetView.subview(0, 1));
    final elementCount = tagWord.offsetInWords;
    final elementDataSectionLengthInWords = tagWord.dataSectionLengthInWords;
    final elementLengthInWords =
        elementDataSectionLengthInWords + tagWord.pointerSectionLengthInWords;
    return _CompositeList._(
      pointer,
      elementCount,
      elementDataSectionLengthInWords,
      elementLengthInWords,
    );
  }
  _CompositeList._(
    this._pointer,
    this.length,
    this._elementDataSectionLengthInWords,
    this._elementLengthInWords,
  );

  final CompositeListPointer<T> _pointer;
  final int _elementDataSectionLengthInWords;
  final int _elementLengthInWords;

  @override
  final int length;
  @override
  set length(newLength) =>
      throw UnsupportedError('Cannot resize a fixed-length list');

  @override
  T operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, 'index');
    }

    final segmentView = _pointer.targetView.subview(
      1 + index * _elementLengthInWords,
      _elementLengthInWords,
    );
    return _pointer.factory(segmentView, _elementDataSectionLengthInWords);
  }

  @override
  void operator []=(int index, T value) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, 'index');
    }

    // TODO(JonasWanke): support writing to a CompositeList
    throw UnsupportedError('Not yet implemented.');
  }
}

/// View of a [CompositeList] that disallows modification.
class UnmodifiableCompositeListView<T> extends ListBase<T>
    with _UnmodifiableListMixin<T>
    implements CompositeList<T> {
  UnmodifiableCompositeListView(CompositeList<T> list) : _list = list;

  final CompositeList<T> _list;

  @override
  int get length => _list.length;
  @override
  T operator [](int index) => _list[index];
}
