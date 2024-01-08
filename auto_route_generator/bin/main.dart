import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'extenstions.dart';
import 'utils.dart';

void main() async {
  final reader = await PackageAssetReader.currentIsolate(rootPackage: rootPackageName);
  for (final asset in await reader.findAssets(Glob('**feature.dart')).toList()) {
    final unit = parseString(content: await reader.readAsString(asset)).unit;
    final stopWatch = Stopwatch()..start();
    final result = await findImports(
      unit,
      asset,
      reader,
      {'ResolvedType', 'Widget', 'int','String'},
      root: true,
    );
    print('took ${stopWatch.elapsedMilliseconds} ms');
    print(result);
  }

  // final asset = packageToAssetId('package:build_test/build_test.dart');
  //  final exportPath = '/Users/milad/StudioProjects/auto_route_library/auto_route_generator/lib/export_lib/exporte_1.dart';
  //  final exportFile = File(exportPath).readAsStringSync();
  // final buildTest = parseString(content: exportFile).unit;
  // for (final directive in buildTest.directives.where((d) => !d.isPackage)) {
  //   print(p.relative(exportPath, from: directive.path));
  //   print(File(p.relative(exportPath, from: directive.path)).existsSync());
  //   // print(p.relative(directive.path, from: 'build_test/lib'));
  // }

  // print(asset);
  // print(rootPackageName);

  // print(normalizeUrl(Uri(path: relativePath)));
  // final stopWatch = Stopwatch()..start();
  // final content =   file.readAsStringSync();
  // for(int i = 0; i < 5+00; i++) {
  //   parseString(content: content, throwIfDiagnostics: false);
  // }
  // print('took ${stopWatch.elapsedMilliseconds} ms');
}

final _checkedAssets = <AssetId>{};

Future<List<(AssetId, Set<String>)>> findImports(
  CompilationUnit unit,
  AssetId asset,
  PackageAssetReader reader,
  Set<String> namesToCheck, {
  bool root = false,
}) async {

  final exportedNames = unit.exportedNames;
  final checkedNames = <String>{};
  if (exportedNames.isNotEmpty) {
    for (final name in namesToCheck) {
      if (exportedNames.contains(name)) {
        checkedNames.add(name);
      }
    }
  }
  if (namesToCheck.length == checkedNames.length) {
    return [(asset, checkedNames)];
  }

  final results = <(AssetId, Set<String>)>[if (checkedNames.isNotEmpty) (asset, checkedNames)];
  final directives =
      unit.directives.where((d) => !d.isDart && ((root && d.isImport) || (!root && d.isExport))).toList();

  for (final directive in directives) {
    final checked = <String>{};
    final show = directive.show;
    if (show.isNotEmpty) {
      for (final name in namesToCheck) {
        if (show.contains(name)) {
          checked.add(name);
        }
      }
    }
    if (checked.isNotEmpty) {
      final assetId =  (directive.isPackage)
              ? packageToAssetId(directive.path)
              : AssetId.resolve(Uri(path: directive.path), from: asset);
      results.add((assetId, checked));
    }
  }

  final namesToExclude = results.expand((e) => e.$2).toSet();

  if (namesToExclude.length == namesToCheck.length) {
    return results;
  }

  final remaining = namesToCheck.difference(namesToExclude);
  for (final directive in directives.where((d) => d.show.isEmpty)) {
    final subAsset = (directive.isPackage)
        ? packageToAssetId(directive.path)
        : AssetId.resolve(Uri(path: directive.path), from: asset);
    if (subAsset == asset || _checkedAssets.contains(subAsset)) continue;
    _checkedAssets.add(subAsset);
    if (!await reader.canRead(subAsset)) continue;
    final subUnit = parseString(content: await reader.readAsString(subAsset)).unit;
    final subResult = await findImports(subUnit, subAsset, reader, remaining);
    if (subResult.isNotEmpty) {
      for(final rec in subResult){
        results.add((subAsset,rec.$2));
      }
      if (subResult.expand((e) => e.$2).length == remaining.length) {
        break;
      }
    }
  }
  return results;
}
