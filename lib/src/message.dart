import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'any_pointer.dart';
import 'error.dart';
import 'private/arena.dart';
import 'private/layout.dart';

@immutable
class ReaderOptions {
  const ReaderOptions({
    this.traversalLimitInWords = 8 * 1024 * 1024,
    this.nestingLimit = 64,
  })  : assert(traversalLimitInWords == null || traversalLimitInWords > 0),
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
  final int? traversalLimitInWords;

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
        other.traversalLimitInWords == traversalLimitInWords &&
        other.nestingLimit == nestingLimit;
  }

  @override
  int get hashCode => Object.hash(traversalLimitInWords, nestingLimit);

  @override
  String toString() {
    return 'ReaderOptions(traversalLimitInWords: $traversalLimitInWords, '
        'nestingLimit: $nestingLimit)';
  }
}

/// A container used to read a message.
class Reader {
  Reader(
    List<ByteData> segments, {
    ReaderOptions options = const ReaderOptions(),
  }) : _arena = ReaderArenaImpl(segments, options);

  final ReaderArenaImpl _arena;

  /// Gets the root of the message, interpreting it as the given type.
  Result<T, CapnpError> getRoot<T>(FromPointerReader<T> fromPointer) =>
      _getRootInternal().andThen((it) => it.getAs(fromPointer));
  Result<AnyPointerReader, CapnpError> _getRootInternal() {
    return PointerReader.getRoot(
      _arena,
      SegmentId.zero,
      location: 0,
      nestingLimit: _arena.nestingLimit,
    ).map(AnyPointerReader.new);
  }
}

typedef FromPointerReader<T> = Result<T, CapnpError> Function(
  PointerReader reader,
  ByteData? defaultValue,
);
