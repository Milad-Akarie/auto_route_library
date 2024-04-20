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

const _deferrablePackageNames = ['flutter', 'framework', 'auto_route'];

class SequenceMatcher {
  final resolvedIdentifiers = Map<String, Set<String>>.of(commonNameSpaces);
  final PackageFileResolver fileResolver;

  SequenceMatcher(this.fileResolver);

  Future<ResolveResult?> locateAll(Uri file, List<Uri> sources, List<Sequence> sequences) {
    return locateTopLevelDeclarations(file, sources, sequences, depth: 0, checkedExports: {});
  }

  Future<ResolveResult?> locateTopLevelDeclarations(
    Uri file,
    List<Uri> sources,
    List<Sequence> sequences, {
    required Set<ExportStatement> checkedExports,
    int depth = 0,
    Uri? root,
    bool isDeferred = false,
  }) async {
    if (sequences.isEmpty) return null;
    final results = <String, Set<String>>{};
    final subResults = <ResolveResult>[];
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
          results.upsert(rootUri.toString(), identifier);
          sequences.removeWhere((e) => e.identifier == identifier);
          print(sequences.map((e) => e.identifier));
        }
      }
    }
    if (didResolveAll()) return ResolveResult(identifiers: results, file: file);

    final exports = <Uri, List<ExportStatement>>{};
    final deferredSources = <Uri, List<Uri>>{};
    for (final source in sources) {
      if (!isDeferred && _deferrablePackageNames.contains(source.pathSegments.first)) {
        deferredSources.upsert(root ?? source, source);
        continue;
      }
      final resolvedUri = fileResolver.resolve(source, relativeTo: file);
      print('checking: ${resolvedUri} $depth');
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
          printRed('found: ${identifierMatches.map((e) => e.identifier)}');
          resolvedIdentifiers.upsertAll(rootUri.toString(), identifierMatches.map((e) => e.identifier));
          foundUnique.addAll(identifierMatches.map((e) => e.identifier));
          results.upsertAll(rootUri.toString(), identifierMatches.map((e) => e.identifier));
          sequences.removeWhere((e) => foundUnique.contains(e.identifier));
        }

        if (didResolveAll()) break;
        final exportMatches = matches.where((e) => e.identifier == 'export');
        if (exportMatches.isNotEmpty) {
          final remainingIdentifiers = targetTotal.difference(foundUnique);
          final exportStatements = exportMatches
              .map((e) => ExportStatement.parse(e.source))
              .whereType<ExportStatement>()
              .whereNot(checkedExports.contains)
              .toList()
              .sortedBy<num>((e) {
            final package = e.uri.pathSegments.first;
            if (package == 'flutter') return 1;
            return !e.uri.hasScheme || package == rootPackage ? -1 : 0;
          });

          checkedExports.addAll(exportStatements);

          for (var i = 0; i < exportStatements.length; i++) {
            bool showsSome = false;
            final exportStatement = exportStatements[i];
            if (exportStatement.show.isEmpty && exportStatement.hide.isEmpty) {
              continue;
            }
            for (final identifier in remainingIdentifiers) {
              if (exportStatement.hides(identifier)) {
                continue;
              }

              if (exportStatement.shows(identifier)) {
                showsSome = true;
                foundUnique.add(identifier);
                sequences.removeWhere((e) => e.identifier == identifier);
                results.upsert(resolvedUri.path, identifier);
              }
              if (didResolveAll()) break;
            }
            if (exportStatement.show.isNotEmpty && !showsSome) {
              exportStatements.removeAt(i);
            }
            ;
            if (didResolveAll()) break;
          }
          if (didResolveAll()) break;
          exports[resolvedUri] = exportStatements;
        }
      } catch (e) {
        // print(e);
      }
    }

    /// Handle export statements
    for (final entry in exports.entries) {
      final exportStatements = entry.value;
      if (exportStatements.isNotEmpty) {
        if (foundUnique.length < targetTotal.length) {
          final exportSources = exportStatements.map((e) => e.uri).toList();
          final subResult = await locateTopLevelDeclarations(
            entry.key,
            exportSources,
            sequences,
            depth: depth + 1,
            root: root ?? entry.key,
            checkedExports: checkedExports,
            isDeferred: isDeferred,
          );
          if (subResult != null) {
            subResults.add(subResult);
            final foundIdentifiers = subResult.identifiers.values.expand((e) => e);
            foundUnique.addAll(foundIdentifiers);
            if (foundIdentifiers.isNotEmpty) {
              results.upsertAll(entry.key.path, foundIdentifiers);
            }
          }
        }
        if (didResolveAll()) break;
      }
    }

    /// handle deferred sources
    if (depth == 0 && !didResolveAll()) {
      printRed('Trying deferred sources ${sequences.map((e) => e.identifier)}');
      for (final result in [
        for (final entry in deferredSources.entries) ResolveResult(file: entry.key, deferredSources: entry.value),
        ...subResults.where((e) => e.hasDeferredSources)
      ]) {
        final identifiers = await handleDeferredResults(result, sequences);
        if (identifiers.isNotEmpty) {
          print(identifiers);
          foundUnique.addAll(identifiers.values.expand((e) => e));
          results.upsertAll(result.file.toString(), identifiers.values.expand((e) => e));
          if (didResolveAll()) break;
        }
      }
    }

    return ResolveResult(
      file: file,
      identifiers: results,
      deferredSources: deferredSources.values.expand((e) => e).toList(),
      subResults: subResults,
    );
  }

  Future<Map<String, Set<String>>> handleDeferredResults(ResolveResult unit, List<Sequence> sequences) async {
    final targetTotal = sequences.map((e) => e.identifier).toSet();
    final foundUnique = <String>{};
    final results = <String, Set<String>>{};
    bool didResolveAll() => foundUnique.length >= targetTotal.length;
    final resolvedResult = await locateTopLevelDeclarations(
      unit.file,
      unit.deferredSources,
      sequences,
      checkedExports: {},
      depth: 1,
      isDeferred: true,
    );
    if (resolvedResult != null) {
      final foundIdentifiers = resolvedResult.identifiers.values.expand((e) => e);
      foundUnique.addAll(foundIdentifiers);
      if (foundIdentifiers.isNotEmpty) {
        results.upsertAll(unit.file.toString(), foundIdentifiers);
      }
      if (didResolveAll()) return results;

      for (final subResult in unit.subResults.where((e) => e.hasDeferredSources)) {
        final subResults = await handleDeferredResults(subResult, sequences);
        if (subResults.isNotEmpty) {
          foundUnique.addAll(subResults.values.expand((e) => e));
          results.addAll(subResults);
          if (didResolveAll()) break;
        }
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

class ResolveResult {
  final Map<String, Set<String>> identifiers;
  final List<String> dependencies;
  final List<Uri> deferredSources;
  final List<ResolveResult> subResults;
  final Uri file;

  ResolveResult({
    this.identifiers = const {},
    this.dependencies = const [],
    this.deferredSources = const [],
    this.subResults = const [],
    required this.file,
  });

  bool get hasDeferredSources => deferredSources.isNotEmpty;
}

