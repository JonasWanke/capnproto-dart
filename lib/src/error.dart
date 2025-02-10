import 'package:oxidized/oxidized.dart';

import 'private/arena.dart';

/// An enum value or union discriminant that was not found among those defined
/// in a schema.
class NotInSchemaError {
  const NotInSchemaError(this.value);

  final int value;

  @override
  String toString() =>
      'Enum value or union discriminant $value was not present in the schema';
}

typedef CapnpResult<T> = Result<T, CapnpError>;

sealed class CapnpError {
  const CapnpError();
}

class InvalidSegmentIdCapnpError extends CapnpError {
  const InvalidSegmentIdCapnpError(this.id);

  final SegmentId id;
}

class TriedToReadFromNullArenaCapnpError extends CapnpError {
  const TriedToReadFromNullArenaCapnpError();
}

class MessageContainsOutOfBoundsPointerCapnpError extends CapnpError {
  const MessageContainsOutOfBoundsPointerCapnpError();
}

class ReadLimitExceededCapnpError extends CapnpError {
  const ReadLimitExceededCapnpError();
}

class MessageIsTooDeeplyNestedOrContainsCyclesCapnpError extends CapnpError {
  const MessageIsTooDeeplyNestedOrContainsCyclesCapnpError();
}

class MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError
    extends CapnpError {
  // ignore: lines_longer_than_80_chars
  const MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError();
}

class MessageContainsNonListPointerWhereTextWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsNonListPointerWhereTextWasExpectedCapnpError();
}

class MessageContainsListPointerOfNonBytesWhereTextWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsListPointerOfNonBytesWhereTextWasExpectedCapnpError();
}

class MessageContainsTextThatIsNotNULTerminatedCapnpError extends CapnpError {
  const MessageContainsTextThatIsNotNULTerminatedCapnpError();
}

class MessageContainsNonListPointerWhereDataWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsNonListPointerWhereDataWasExpectedCapnpError();
}

class MessageContainsListPointerOfNonBytesWhereDataWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsListPointerOfNonBytesWhereDataWasExpectedCapnpError();
}
