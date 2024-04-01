class SequenceMatch {
  final String identifier;
  final int start;
  final int end;
  final String source;

  const SequenceMatch(this.identifier, this.start, this.end, this.source);

  const SequenceMatch.from(this.identifier)
      : start = 0,
        end = 0,
        source = identifier;

  @override
  String toString() {
    return identifier;
  }
}
