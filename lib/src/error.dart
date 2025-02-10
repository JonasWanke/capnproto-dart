import 'package:oxidized/oxidized.dart';

import 'serialize.dart';

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

class PrematureEndOfFileCapnpError extends CapnpError {
  const PrematureEndOfFileCapnpError();
}

class InvalidNumberOfSegmentsCapnpError extends CapnpError {
  const InvalidNumberOfSegmentsCapnpError(this.segmentCount);

  final int segmentCount;
}

class MessageTooLargeCapnpError extends CapnpError {
  const MessageTooLargeCapnpError(this.totalWords);

  final int totalWords;
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

// Struct

class MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError
    extends CapnpError {
  // ignore: lines_longer_than_80_chars
  const MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError();
}

// List

class NestingLimitExceededCapnpError extends CapnpError {
  const NestingLimitExceededCapnpError();
}

class MessageContainsNonListPointerWhereListPointerWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsNonListPointerWhereListPointerWasExpectedCapnpError();
}

class InlineCompositeListsOfNonStructTypeAreNotSupportedCapnpError
    extends CapnpError {
  const InlineCompositeListsOfNonStructTypeAreNotSupportedCapnpError();
}

class InlineCompositeListsElementsOverrunItsWordCountCapnpError
    extends CapnpError {
  const InlineCompositeListsElementsOverrunItsWordCountCapnpError();
}

class FoundStructListWhereBitListWasExpectedCapnpError extends CapnpError {
  const FoundStructListWhereBitListWasExpectedCapnpError();
}

class ExpectedAPrimitiveListButGotAListOfPointerOnlyStructsCapnpError
    extends CapnpError {
  const ExpectedAPrimitiveListButGotAListOfPointerOnlyStructsCapnpError();
}

class ExpectedAPointerListButGotAListOfDataOnlyStructsCapnpError
    extends CapnpError {
  const ExpectedAPointerListButGotAListOfDataOnlyStructsCapnpError();
}

class FoundBitListWhereStructListWasExpectedCapnpError extends CapnpError {
  const FoundBitListWhereStructListWasExpectedCapnpError();
}

class MessageContainsListWithIncompatibleElementTypeCapnpError
    extends CapnpError {
  const MessageContainsListWithIncompatibleElementTypeCapnpError();
}

// Text

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

// Data

class MessageContainsNonListPointerWhereDataWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsNonListPointerWhereDataWasExpectedCapnpError();
}

class MessageContainsListPointerOfNonBytesWhereDataWasExpectedCapnpError
    extends CapnpError {
  const MessageContainsListPointerOfNonBytesWhereDataWasExpectedCapnpError();
}
