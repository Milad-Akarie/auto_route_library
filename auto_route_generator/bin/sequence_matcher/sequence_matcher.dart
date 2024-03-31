import 'dart:io';

import 'package:collection/collection.dart';

import '../auto_route.dart';
import '../resolvers/package_file_resolver.dart';
import '../sdt_out_utils.dart';
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
  final resolvedIdentifiers = Map.of(commonNameSpaces);
  final PackageFileResolver fileResolver;

  SequenceMatcher(this.fileResolver);

  Future<Map<String, Set<SequenceMatch>>> locateTopLevelDeclarations(
    final Uri file,
    List<Uri> sources,
    Iterable<Sequence> _sequences, {
    int depth = 0,
    final Uri? root,
  }) async {
    if (depth == 0) {
      checkedExports.clear();
    }
    if (_sequences.isEmpty) return {};
    Iterable<Sequence> sequences = _sequences;
    final results = <String, Set<SequenceMatch>>{};
    final targetTotal = sequences.map((e) => e.identifier).toSet();

    final foundUnique = <String>{};

    for (final source in sources) {
      final resolvedUri = fileResolver.resolve(source, relativeTo: file);
      final rootUri = root ?? resolvedUri;

      try {
        final notFoundIdentifiers = sequences.map((e) => e.identifier).where((e) => !foundUnique.contains(e)).toSet();
        for (final identifier in notFoundIdentifiers) {
          // print(resolvedIdentifiers.keys);
          // print(resolvedUri.toString());
          // print(notFoundIdentifiers);
          if (resolvedIdentifiers[source.toString()]?.contains(identifier) == true ||
              resolvedIdentifiers[rootUri.toString()]?.contains(identifier) == true) {
            foundUnique.add(identifier);
            if (source != rootUri) {
              resolvedIdentifiers[rootUri.toString()] = {...?resolvedIdentifiers[rootUri.toString()], identifier};
            }
            printRed('resolved: ($identifier) in ${rootUri.toString()}');
            results[rootUri.toString()] = {
              ...?results[rootUri.toString()],
              SequenceMatch(identifier, 0, 0, identifier)
            };

            sequences = sequences.where((e) => e.identifier != identifier);
            print('sequences: ${sequences.map((e) => e.identifier)}');
          }
        }

        if (sequences.isEmpty) break;
        final content = File.fromUri(resolvedUri).readAsBytesSync();
        final matches = findTopLevelSequences(content, [
          Sequence('export', 'export', takeUntil: 0x3B),
          Sequence('export', 'part', takeUntil: 0x3B),
          ...sequences,
        ]);

        // if(sequences.any((e) => e.identifier == 'Key')){
        //   print('Looking For key in ${resolvedUri.toString()}');
        // }

        final identifierMatches = matches.where((e) => e.identifier != 'export');
        if (identifierMatches.isNotEmpty) {
          resolvedIdentifiers[rootUri.toString()] = {
            ...?resolvedIdentifiers[rootUri.toString()],
            ...identifierMatches.map((e) => e.identifier).toSet()
          };
          foundUnique.addAll(identifierMatches.map((e) => e.identifier));
          printRed('found: ${identifierMatches.map((e) => e.identifier)} in ${resolvedUri.toString()}');
          results[rootUri.path] = {...?results[rootUri.path], ...identifierMatches};
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
            if (foundUnique.length < targetTotal.length) {
              final notFoundIdentifiers = sequences.where((e) => !foundUnique.contains(e.identifier));
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
                results[resolvedUri.path] = {...?results[resolvedUri.path], ...foundIdentifiers};
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
