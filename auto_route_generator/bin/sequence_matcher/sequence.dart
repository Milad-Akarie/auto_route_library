class Sequence {
  final String identifier;
  final String pattern;
  final int? terminator;

  const Sequence(this.identifier, this.pattern, {this.terminator});

  int matches(List<int> byteArray, int startIndex) {
    final chars = pattern.codeUnits;
    int lastConsumedIndex = startIndex;
    for (int i = 0; i < chars.length; i++) {
      while (startIndex < byteArray.length && byteArray[startIndex] == 32) {
        startIndex++;
      }
      if (startIndex + i < byteArray.length) {
        if (byteArray[startIndex + i] == chars[i]) {
          lastConsumedIndex = startIndex + i;
        } else {
          return -1;
        }
      } else {
        return -1;
      }
    }

    if (terminator != null) {
      while (lastConsumedIndex < byteArray.length && byteArray[lastConsumedIndex] != terminator) {
        lastConsumedIndex++;
      }
      return lastConsumedIndex + 1;
    }
    return lastConsumedIndex;
  }
}
