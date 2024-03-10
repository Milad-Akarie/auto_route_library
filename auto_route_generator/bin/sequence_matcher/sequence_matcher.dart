import 'dart:io';

import '../resolvers/package_file_resolver.dart';
import 'common_namespaces.dart';
import 'export_statement.dart';
import 'sequence.dart';
import 'sequence_match.dart';

const _scopes = {
  0x7B: 0x7D, // {}
  0x28: 0x29, // ()
  0x5B: 0x5D, // []
};

class SequenceMatcher {
  final checkedExports = <Uri>{};
  final resolvedTypes = Map.of(commonNameSpaces);
  final PackageFileResolver fileResolver;

  SequenceMatcher(this.fileResolver);

  Future<Map<String, Set<SequenceMatch>>> locateTopLevelDeclarations(
    final Uri file,
    Set<Uri> sources,
    Iterable<Sequence> _sequences, [
    int depth = 0,
  ]) async {
    if (depth == 0) {
      checkedExports.clear();
    }
    if (_sequences.isEmpty) return {};

    Iterable<Sequence> sequences = _sequences;
    final results = <String, Set<SequenceMatch>>{};
    final targetTotal = sequences.map((e) => e.identifier).toSet();

    final foundUnique = <String>{};
    final exportsFound = <Uri, Iterable<ExportStatement>>{};

    for (final source in sources) {
      final resolvedUri = fileResolver.resolve(source, relativeTo: file);

      try {
        final notFoundIdentifiers = sequences.map((e) => e.identifier).where((e) => !foundUnique.contains(e)).toSet();
        print(notFoundIdentifiers);
        for (final identifier in notFoundIdentifiers) {
          if (resolvedTypes[source.toString()]?.contains(identifier) == true) {
            foundUnique.add(identifier);
            results[resolvedUri.path] = {...?results[resolvedUri.path], SequenceMatch(identifier, 0, 0, identifier)};
            sequences = sequences.where((e) => e.identifier != identifier);
          }
        }

        if (sequences.isEmpty) break;
        final content = File.fromUri(resolvedUri).readAsBytesSync();
        final matches = findTopLevelSequences(content, [
          Sequence('export', 'export', terminator: 0x3B),
          Sequence('export', 'part', terminator: 0x3B),
          ...sequences,
        ]);

        final identifierMatches = matches.where((e) => e.identifier != 'export');
        if (identifierMatches.isNotEmpty) {
          resolvedTypes[resolvedUri.toString()] = identifierMatches.map((e) => e.identifier).toSet();
          foundUnique.addAll(identifierMatches.map((e) => e.identifier));
          results[resolvedUri.path] = {...?results[resolvedUri.path], ...identifierMatches};
          sequences = sequences.where((e) => !foundUnique.contains(e.identifier));
        }
        if (foundUnique.length >= targetTotal.length) {
          break;
        }
        final exportMatches = matches.where((e) => e.identifier == 'export');
        if (exportMatches.isNotEmpty) {
          final notFoundIdentifiers = targetTotal.difference(foundUnique);
          final exportStatements = exportMatches
              .map((e) => ExportStatement.parse(e.source))
              .whereType<ExportStatement>()
              .where((e) => !checkedExports.contains(e.uri))
              .toList();

          checkedExports.addAll(exportStatements.map((e) => e.uri));
          for (final identifier in notFoundIdentifiers) {
            for (var i = 0; i < exportStatements.length; i++) {
              final exportStatement = exportStatements[i];
              if (exportStatement.show.isEmpty || exportStatement.hides(identifier)) {
                continue;
              }
              if (exportStatement.shows(identifier)) {
                foundUnique.add(identifier);
                sequences = sequences.where((e) => e.identifier != identifier);
                results[resolvedUri.path] = {
                  ...?results[resolvedUri.path],
                  SequenceMatch(identifier, 0, 0, identifier)
                };
              }
              exportStatements.removeAt(i);
            }
          }
          if (foundUnique.length >= targetTotal.length) {
            break;
          }
          if (exportStatements.isNotEmpty) {
            exportsFound[resolvedUri] = exportStatements;
          }
        }
      } catch (e) {
        // print(e);
      }
    }

    if (foundUnique.length < targetTotal.length && exportsFound.isNotEmpty) {
      final notFoundIdentifiers = sequences.where((e) => !foundUnique.contains(e.identifier));
      for (final entry in exportsFound.entries) {
        final exportSources = entry.value.map((e) => e.uri).toSet();
        final subResults = await locateTopLevelDeclarations(entry.key, exportSources, notFoundIdentifiers, depth + 1);
        final foundIdentifiers = subResults.values.expand((e) => e);
        foundUnique.addAll(foundIdentifiers.map((e) => e.identifier));
        results[entry.key.path] = {...?results[entry.key.path], ...foundIdentifiers};
        if (foundUnique.length >= targetTotal.length) {
          break;
        }
      }
    }

    return results;
  }

  List<SequenceMatch> findTopLevelSequences(List<int> byteArray, List<Sequence> sequences) {
    List<SequenceMatch> results = [];
    List<int> enteredScopes = [];

    for (int i = 0; i < byteArray.length; i++) {
      /// if found ',", or ''' skip until the next one
      if (byteArray[i] == 0x22 || byteArray[i] == 0x27 || byteArray[i] == 0x60) {
        final start = byteArray[i];
        i++;
        while (i < byteArray.length && byteArray[i] != start) {
          i++;
        }
        continue;
      }

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
        if (byteArray[i] == _scopes[enteredScopes.last]) {
          enteredScopes.removeLast();
        }
        continue;
      }

      if (_scopes.containsKey(byteArray[i])) {
        enteredScopes.add(byteArray[i]);
        continue;
      }

      for (final matchSequence in sequences) {
        final sequenceEnd = matchSequence.matches(byteArray, i);
        if (sequenceEnd != -1) {
          final sequenceStart = i;
          i = sequenceEnd;
          results.add(
            SequenceMatch(
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
}
