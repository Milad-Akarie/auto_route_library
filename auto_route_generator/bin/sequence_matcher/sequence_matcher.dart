import 'dart:io';

import 'package:collection/collection.dart';

import '../auto_route.dart';
import '../resolvers/package_file_resolver.dart';
import '../sdt_out_utils.dart';
import 'common_namespaces.dart';
import 'export_statement.dart';
import 'sequence.dart';
import 'sequence_match.dart';
import 'utils.dart';

const _scopes = {
  0x7B: 0x7D, // {}
  0x28: 0x29, // ()
  0x5B: 0x5D, // []
};

class SequenceMatcher {
  final checkedExports = <Uri>{};
  final resolvedIdentifiers = Map.of(commonNameSpaces);
  final PackageFileResolver fileResolver;

  SequenceMatcher(this.fileResolver);

  Future<Map<String, Set<SequenceMatch>>> locateTopLevelDeclarations(Uri file,
    List<Uri> sources,
    Iterable<Sequence> _sequences, {
    int depth = 0,
    Uri? root,
  }) async {
    if (depth == 0) {
      checkedExports.clear();
    }
    if (_sequences.isEmpty) return {};
    Iterable<Sequence> sequences = _sequences;
    final results = <String, Set<SequenceMatch>>{};
    final targetTotal = sequences.map((e) => e.identifier).toSet();
    final foundUnique = <String>{};
    bool didResolveAll() => foundUnique.length >= targetTotal.length;

    for (final source in sources) {
      final resolvedUri = fileResolver.resolve(source, relativeTo: file);
      final rootUri = root ?? resolvedUri;
      final notFoundIdentifiers = sequences.difference(foundUnique);
      for (final identifier in notFoundIdentifiers) {
        if (resolvedIdentifiers[source.toString()]?.contains(identifier) == true ||
            resolvedIdentifiers[rootUri.toString()]?.contains(identifier) == true) {
          foundUnique.add(identifier);
          if (source != rootUri) {
            resolvedIdentifiers.upsert(rootUri.toString(), identifier);
          }
          printYellow('resolved: ($identifier)');
          results.upsert(rootUri.toString(), SequenceMatch.from(identifier));
          sequences = sequences.where((e) => e.identifier != identifier);
        }
      }
    }

    if (didResolveAll()) return results;

    for (final source in sources) {
      final resolvedUri = fileResolver.resolve(source, relativeTo: file);
      final rootUri = root ?? resolvedUri;
      try {
        final content = File.fromUri(resolvedUri).readAsBytesSync();
        final matches = findTopLevelSequences(content, [
          Sequence('export', 'export', takeUntil: 0x3B),
          Sequence('export', 'part', takeUntil: 0x3B),
          ...sequences,
        ]);

        final identifierMatches = matches.where((e) => e.identifier != 'export');
        if (identifierMatches.isNotEmpty) {
          resolvedIdentifiers.upsertAll(rootUri.toString(), identifierMatches.map((e) => e.identifier));
          foundUnique.addAll(identifierMatches.map((e) => e.identifier));
          printRed('found: ${identifierMatches.map((e) => e.identifier)}');
          results[rootUri.path] = {...?results[rootUri.path], ...identifierMatches};
          sequences = sequences.where((e) => !foundUnique.contains(e.identifier));
        }

        if (didResolveAll()) break;
        final exportMatches = matches.where((e) => e.identifier == 'export');
        if (exportMatches.isNotEmpty) {
          final notFoundIdentifiers = targetTotal.difference(foundUnique);
          final exportStatements = exportMatches
              .map((e) => ExportStatement.parse(e.source))
              .whereType<ExportStatement>()
              .where((e) => !checkedExports.contains(e.uri))
              .toList()
              .sortedBy<num>((e) {
            final package = e.uri.pathSegments.first;
            if (package == 'flutter') return 1;
            return !e.uri.hasScheme || package == rootPackage ? -1 : 0;
          });

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
                results.upsert(resolvedUri.path, SequenceMatch.from(identifier));
              }
              exportStatements.removeAt(i);
            }
          }
          if (didResolveAll()) break;
          if (exportStatements.isNotEmpty) {
            if (foundUnique.length < targetTotal.length) {
              final notFoundIdentifiers = sequences.notIn(foundUnique);
              final exportSources = exportStatements.map((e) => e.uri).toList();
              final subResults = await locateTopLevelDeclarations(
                resolvedUri,
                exportSources,
                notFoundIdentifiers,
                depth: depth + 1,
                root: rootUri,
              );
              final foundIdentifiers = subResults.values.expand((e) => e);
              if (foundIdentifiers.isNotEmpty) {
                foundUnique.addAll(foundIdentifiers.map((e) => e.identifier));
                results.upsertAll(resolvedUri.path, foundIdentifiers);
              }
            }
          }
        }
      } catch (e) {
        // print(e);
      }
    }

    return results;
  }

  List<SequenceMatch> findTopLevelSequences(List<int> byteArray, List<Sequence> sequences) {
    List<SequenceMatch> results = [];
    List<int> visitedScopes = [];

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

      /// if found // skip until the next line
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

      if (visitedScopes.isNotEmpty) {
        if (byteArray[i] == _scopes[visitedScopes.last]) {
          visitedScopes.removeLast();
        }
        continue;
      }

      if (_scopes.containsKey(byteArray[i])) {
        visitedScopes.add(byteArray[i]);
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
