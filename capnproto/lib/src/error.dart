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

class PrematureEndOfInputCapnpError extends CapnpError {
  const PrematureEndOfInputCapnpError();
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

class MalformedDoubleFarPointerCapnpError extends CapnpError {
  const MalformedDoubleFarPointerCapnpError();
}

class UnknownPointerTypeCapnpError extends CapnpError {
  const UnknownPointerTypeCapnpError();
}

// Struct

class MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError
    extends CapnpError {
  // ignore: lines_longer_than_80_chars
  const MessageContainsNonStructPointerWhereStructPointerWasExpectedCapnpError();
}

class StructReaderHadBitwidthOtherThan1CapnpError extends CapnpError {
  const StructReaderHadBitwidthOtherThan1CapnpError();
}

class OnlyOneOfTheSectionPointersIsPointingToOurselfCapnpError
    extends CapnpError {
  const OnlyOneOfTheSectionPointersIsPointingToOurselfCapnpError();
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

class ExistingPointerIsNotAListCapnpError extends CapnpError {
  const ExistingPointerIsNotAListCapnpError();
}

class InlineCompositeListWithNonStructElementsNotSupportedCapnpError
    extends CapnpError {
  const InlineCompositeListWithNonStructElementsNotSupportedCapnpError();
}

class ExistingListValueIsIncompatibleWithExpectedTypeCapnpError
    extends CapnpError {
  const ExistingListValueIsIncompatibleWithExpectedTypeCapnpError();
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

class MessageContainsTextWithInvalidUtf8CapnpError extends CapnpError {
  const MessageContainsTextWithInvalidUtf8CapnpError(this.bytes);

  final List<int> bytes;
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

class ExistingListPointerIsNotByteSizedCapnpError extends CapnpError {
  const ExistingListPointerIsNotByteSizedCapnpError();
}

// Capability

class CannotCreateACanonicalMessageWithACapabilityCapnpError
    extends CapnpError {
  const CannotCreateACanonicalMessageWithACapabilityCapnpError();
}
