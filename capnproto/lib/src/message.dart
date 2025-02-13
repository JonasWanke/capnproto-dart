import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'any_pointer.dart';
import 'error.dart';
import 'private/arena.dart';
import 'private/layout.dart';
import 'reader_builder.dart';
import 'serialize.dart';

@immutable
class ReaderOptions {
  const ReaderOptions({
    this.traversalLimitWords = 8 * 1024 * 1024,
    this.nestingLimit = 64,
  })  : assert(traversalLimitWords == null || traversalLimitWords > 0),
        assert(nestingLimit > 0);

  /// Limits how many total (8-byte) words of data are allowed to be traversed.
  ///
  /// Traversal is counted when a new struct or list builder is obtained, e.g.,
  /// from a `get()` accessor. This means that calling the getter for the same
  /// sub-struct multiple times will cause it to be double-counted. Once the
  /// traversal limit is reached, an error will be reported.
  ///
  /// This limit exists for security reasons. It is possible for an attacker to
  /// construct a message in which multiple pointers point at the same location.
  /// This is technically invalid, but hard to detect. Using such a message, an
  /// attacker could cause a message which is small on the wire to appear much
  /// larger when actually traversed, possibly exhausting server resources
  /// leading to denial-of-service.
  ///
  /// It makes sense to set a traversal limit that is much larger than the
  /// underlying message. Together with sensible coding practices (e.g., trying
  /// to avoid calling sub-object getters multiple times, which is expensive
  /// anyway), this should provide adequate protection without inconvenience.
  ///
  /// A traversal limit of `null` means that no limit is enforced.
  final int? traversalLimitWords;

  /// Limits how deeply nested a message structure can be, e.g., structs
  /// containing other structs or lists of structs.
  ///
  /// Like the traversal limit, this limit exists for security reasons. Since it
  /// is common to use recursive code to traverse recursive data structures, an
  /// attacker could easily cause a stack overflow by sending a very deeply
  /// nested (or even cyclic) message, without the message even being very
  /// large. The default limit of 64 is probably low enough to prevent any
  /// chance of stack overflow, yet high enough that it is never a problem in
  /// practice.
  final int nestingLimit;

  @override
  bool operator ==(Object other) {
    return other is ReaderOptions &&
        other.traversalLimitWords == traversalLimitWords &&
        other.nestingLimit == nestingLimit;
  }

  @override
  int get hashCode => Object.hash(traversalLimitWords, nestingLimit);

  @override
  String toString() {
    return 'ReaderOptions(traversalLimitWords: $traversalLimitWords, '
        'nestingLimit: $nestingLimit)';
  }
}

/// A container used to read a message.
class MessageReader {
  MessageReader(
    Segments segments, {
    ReaderOptions options = const ReaderOptions(),
  }) : _arena = ReaderArenaImpl(segments, options);

  final ReaderArenaImpl _arena;

  /// Gets the root of the message, interpreting it as the given type.
  CapnpResult<R> getRoot<R extends CapnpReader>(
    FromPointerReader<R> fromPointer,
  ) =>
      _getRootInternal().andThen((it) => it.getAs(fromPointer));
  CapnpResult<R> getRootAsStruct<R extends CapnpReader>(
    FromStructReader<R> fromReader,
  ) {
    return getRoot(
      (reader, defaultValue) => reader.getStruct(defaultValue).map(fromReader),
    );
  }

  CapnpResult<AnyPointerReader> _getRootInternal() {
    return PointerReader.getRoot(
      _arena,
      SegmentId.zero,
      nestingLimit: _arena.nestingLimit,
    ).map(AnyPointerReader.new);
  }
}

/// A container used to build a message.
class MessageBuilder {
  MessageBuilder() : _arena = BuilderArenaImpl();

  final BuilderArenaImpl _arena;
  List<ByteData> get segmentsForOutput => _arena.segmentsForOutput;

  /// Initializes the root as a value of the given type.
  B initRoot<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
  ) =>
      _getRootInternal().initAs(fromPointer);

  /// Initializes the root as a value of the given list type with the given
  /// length.
  B initRootAsListOf<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
    int length,
  ) =>
      _getRootInternal().initAsListOf(fromPointer, length);

  /// Gets the root, interpreting it as the given type.
  CapnpResult<B> getRoot<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerBuilder<B, R> fromPointer,
  ) =>
      _getRootInternal().getAs(fromPointer);

  CapnpResult<R>
      getRootAsReader<B extends CapnpBuilder<R>, R extends CapnpReader>(
    FromPointerReader<R> fromPointer,
  ) {
    if (_arena.isEmpty) {
      return AnyPointerReader(PointerReader.defaultReader).getAs(fromPointer);
    }

    return PointerReader.getRoot(
      _arena,
      SegmentId.zero,
      nestingLimit: 0x7fffffff,
    ).andThen((it) => AnyPointerReader(it).getAs(fromPointer));
  }

  // TODO(JonasWanke): setRoot(…), setRootCanonical(…)

  AnyPointerBuilder _getRootInternal() {
    if (_arena.isEmpty) {
      _arena.allocateSegment(1);
      _arena.allocate(SegmentId.zero, 1);
    }
    return AnyPointerBuilder(
      PointerBuilder.getRoot(_arena, SegmentId.zero, location: 0),
    );
  }
}

typedef FromPointerReader<R extends CapnpReader> = CapnpResult<R> Function(
  PointerReader reader,
  ByteData? defaultValue,
);

final class FromPointerBuilder<B extends CapnpBuilder<R>,
    R extends CapnpReader> {
  FromPointerBuilder({required this.initPointer, required this.getFromPointer});

  final B Function(PointerBuilder builder, int length) initPointer;
  final CapnpResult<B> Function(PointerBuilder builder, ByteData? defaultValue)
      getFromPointer;
}

typedef FromStructReader<R extends CapnpReader> = R Function(
  StructReader reader,
);
typedef FromStructBuilder<B extends CapnpBuilder<R>, R extends CapnpReader> = B
    Function(StructBuilder builder);
