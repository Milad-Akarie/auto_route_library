import 'dart:io';

import 'export_statement.dart';
import 'package_file_resolver.dart';

Map<String, Iterable<SequenceMatchResult>> locateTopLevelDeclarations(
  final Uri file,
  Set<Uri> sources,
  Iterable<MatchSequence> sequences,
  PackageFileResolver resolver, [
  int level = 0,
]) {
  if (sequences.isEmpty) return {};
  final results = <String, Iterable<SequenceMatchResult>>{};
  final targetTotal = sequences.map((e) => e.identifier).toSet();
  final foundUnique = <String>{};
  final exportsFound = <Uri, Iterable<ExportStatement>>{};
  for (final source in sources) {
    final resolvedUri = resolver.resolve(source, relativeTo: file);
    final content = File.fromUri(resolvedUri).readAsBytesSync();
    final matches = findTopLevelSequences(content, [
      MatchSequence('export', 'export', terminator: 0x3B),
      ...sequences,
    ]);

    final nonExportMatches = matches.where((e) => e.identifier != 'export');
    if (nonExportMatches.isNotEmpty) {
      foundUnique.addAll(nonExportMatches.map((e) => e.identifier));
      results[resolvedUri.path] = nonExportMatches;
    }
    if (foundUnique.length >= targetTotal.length) {
      break;
    }

    final exportMatches = matches.where((e) => e.identifier == 'export');
    if (exportMatches.isNotEmpty) {
      final notFoundIdentifiers = targetTotal.difference(foundUnique);
      final exportStatements = exportMatches
          .where((e) => !e.source.contains('dart:'))
          .map((e) => ExportStatement.parse(e.source))
          .whereType<ExportStatement>()
          .toList();

      for (final identifier in notFoundIdentifiers) {
        for (final exportStatement in exportStatements) {
          bool showsSome = false;
          if (exportStatement.shows(identifier)) {
            foundUnique.add(identifier);
            showsSome = true;
          }
          if (showsSome) {
            exportStatements.remove(exportStatement);
          }
        }
      }
      if (foundUnique.length >= targetTotal.length) {
        break;
      }
      if (exportStatements.isNotEmpty) {
        exportsFound[resolvedUri] = exportStatements;
      }
    }
  }
  if (foundUnique.length < targetTotal.length && exportsFound.isNotEmpty) {
    final notFoundIdentifiers = sequences.where((e) => !foundUnique.contains(e.identifier));
    for (final entry in exportsFound.entries) {
      final exportSources = entry.value.map((e) => e.uri);
      final subResults =
          locateTopLevelDeclarations(entry.key, exportSources.toSet(), notFoundIdentifiers, resolver, level++);
      final foundIdentifiers = subResults.values.expand((e) => e);
      foundUnique.addAll(foundIdentifiers.map((e) => e.identifier));
      results[entry.key.path] = foundIdentifiers;
      if (foundUnique.length >= targetTotal.length) {
        break;
      }
    }
  }

  return results;
}

class SequenceMatchResult {
  final String identifier;
  final int start;
  final int end;
  final String source;

  const SequenceMatchResult(this.identifier, this.start, this.end, this.source);

  @override
  String toString() {
    return identifier;
  }
}

class MatchSequence {
  final String identifier;
  final String pattern;
  final int? terminator;

  const MatchSequence(this.identifier, this.pattern, {this.terminator});

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
        results.add(
          SequenceMatchResult(
            matchSequence.identifier,
            sequenceStart,
            sequenceEnd,
            String.fromCharCodes(
              byteArray.sublist(sequenceStart, sequenceEnd),
            ),
          ),
        );
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
