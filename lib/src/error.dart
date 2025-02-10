import 'private/arena.dart';

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
  const MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError();
}
