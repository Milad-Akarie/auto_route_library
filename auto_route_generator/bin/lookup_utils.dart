import 'dart:io';

Future<Map<String, List<SequenceMatchResult>>> locateTopLevelDeclarations(
    Set<Uri> imports, List<MatchSequence> sequences) async {
  if (sequences.isEmpty) return {};
  final results = <String, List<SequenceMatchResult>>{};
  final targetTotal = sequences.map((e) => e.identifier).toSet();
  final foundUnique = <String>{};
  for (final source in imports) {
    final content = File.fromUri(source).readAsBytesSync();
    final matches = findTopLevelSequences(content, sequences);
    if (matches.isNotEmpty) {
      results[source.path] = matches;
      foundUnique.addAll(matches.map((e) => e.identifier));
    }
    if (foundUnique.length >= targetTotal.length) {
      break;
    }
  }
  return results;
}

class SequenceMatchResult {
  final String identifier;
  final int start;
  final int end;

  const SequenceMatchResult(this.identifier, this.start, this.end);

  @override
  String toString() {
    return identifier;
  }
}

class MatchSequence {
  final String identifier;
  final String pattern;

  const MatchSequence(this.identifier, this.pattern);

  int matches(List<int> byteArray, int startIndex) {
    final chars = pattern.trim().codeUnits; // Trim the pattern to remove extra spaces
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
    return lastConsumedIndex;
  }
}

const scopes = {
  0x7B: 0x7D, // {}
  0x28: 0x29, // ()
  0x5B: 0x5D, // []
  0x22: 0x22, // ""
  0x27: 0x27, // ''
  0x60: 0x60, // ``
};

List<SequenceMatchResult> findTopLevelSequences(List<int> byteArray, List<MatchSequence> matchSequences) {
  List<SequenceMatchResult> results = [];
  List<int> enteredScopes = [];

  for (int i = 0; i < byteArray.length; i++) {
    if (byteArray[i] == 0x2F && i < byteArray.length - 1 && byteArray[i + 1] == 0x2F) {
      i += 2;
      while (i < byteArray.length && byteArray[i] != 0x0A) {
        i++;
      }
      continue;
    }

    if (byteArray[i] == 0x2F && i < byteArray.length - 1 && byteArray[i + 1] == 0x2A) {
      i += 2;
      while (i < byteArray.length && byteArray[i] != 0x2A && byteArray[i + 1] != 0x2F) {
        i++;
      }
      i += 2;
      continue;
    }

    if (enteredScopes.isNotEmpty) {
      if (byteArray[i] == scopes[enteredScopes.last]) {
        enteredScopes.removeLast();
      }
      continue;
    }

    if (scopes.containsKey(byteArray[i])) {
      enteredScopes.add(byteArray[i]);
      continue;
    }

    for (MatchSequence matchSequence in matchSequences) {
      final sequenceEnd = matchSequence.matches(byteArray, i);
      if (sequenceEnd != -1) {
        final sequenceStart = i;
        i = sequenceEnd;
        results.add(SequenceMatchResult(matchSequence.identifier, sequenceStart, sequenceEnd));
        break;
      }
    }
  }

  return results;
}

bool hasRouteAnnotation(List<int> byteArray) {
  List<int> targetSequence = [0x40, 0x52, 0x6F, 0x75, 0x74, 0x65]; // ASCII values for '@Route'
  for (int i = 0; i < byteArray.length; i++) {
    if (byteArray[i] == targetSequence[0]) {
      for (int j = 1; j < targetSequence.length; j++) {
        if (byteArray[i + j] != targetSequence[j]) {
          break;
        }
        if (j == targetSequence.length - 1) {
          return true;
        }
      }
    }
  }
  return false;
}
