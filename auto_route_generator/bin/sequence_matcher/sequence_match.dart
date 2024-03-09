class SequenceMatch {
  final String identifier;
  final int start;
  final int end;
  final String source;

  const SequenceMatch(this.identifier, this.start, this.end, this.source);

  @override
  String toString() {
    return identifier;
  }
}
