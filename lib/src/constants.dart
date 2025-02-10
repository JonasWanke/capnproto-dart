abstract final class CapnpConstants {
  static const bytesPerWord = 8;
  static const bitsPerWord = bytesPerWord * bitsPerByte;

  static const bitsPerByte = 8;

  static const wordsPerPointer = 1;
  static const bytesPerPointer = wordsPerPointer * bytesPerWord;
}
