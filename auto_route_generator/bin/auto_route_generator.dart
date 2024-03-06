import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import 'ast_extensions.dart';
import 'lookup_utils.dart';
import 'package_file_resolver.dart';

final _configFile = File('auto_route_config.txt');

void main() async {
  print('Starting... auto_route_generator');
  final resolvedTypes = <String, Set<String>>{};
  final stopWatch = Stopwatch()..start();
  late final packageResolver = PackageFileResolver.forCurrentRoot();
  print('resolved packages in ${stopWatch.elapsedMilliseconds}ms');
  final lastConfig = _configFile.existsSync() ? int.parse(_configFile.readAsStringSync()) : 0;
  final glob = Glob('lib/playground**.dart');
  final assets = glob.listSync(root: Directory.current.path).whereType<File>();

  for (final asset in assets) {
    // if (asset.lastModifiedSync().millisecondsSinceEpoch < lastConfig) continue;
    print('Processing: ${asset.path}');
    await _processFile(asset, packageResolver, resolvedTypes);
  }

  print('Time taken: ${stopWatch.elapsedMilliseconds}ms');
  _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
  stopWatch.stop();

  Directory.current.watch(events: FileSystemEvent.all, recursive: true).listen((event) async {
    final stopWatch = Stopwatch()..start();
    if (glob.matches(event.path)) {
      final asset = File(event.path);
      await _processFile(asset, packageResolver, resolvedTypes);
      print('Watched file took: ${stopWatch.elapsedMilliseconds}ms');
      _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
    }
  });
}

Future<void> _processFile(
    File asset, PackageFileResolver packageResolver, Map<String, Set<String>> resolvedTypes) async {
  final bytes = asset.readAsBytesSync();
  if (!hasRouteAnnotation(bytes)) return;
  final assetContent = utf8.decode(bytes);
  final unit = parseString(content: assetContent, throwIfDiagnostics: false).unit;
  final classDeclarations = unit.declarations.whereType<ClassDeclaration>();

  final routePage = classDeclarations.firstWhereOrNull((e) => e.metadata.any((e) => e.name.name == 'RoutePage'));
  if (routePage == null) return;

  final imports = unit.directives
      .whereType<ImportDirective>()
      .where((e) => e.uri.stringValue != null && !e.uri.stringValue!.startsWith('dart:'))
      .map((e) => Uri.parse(e.uri.stringValue!))
      .map((e) => packageResolver.resolve(e, relativeTo: asset.uri))
      .toSet();
  final parameters = routePage.constructors.first.parametersList;
  final firstParamName = parameters[1].paramType;

  DefaultFormalParameter;
  SimpleFormalParameter;
  final alreadyResolved =
      resolvedTypes.values.fold(<String>{}, (previousValue, element) => previousValue..addAll(element));

  final fieldsToLookUp = routePage.fields
      .where((e) => !e.type!.isDartCoreType)
      .map((e) => e.typeName)
      .whereNotNull()
      .where((e) => alreadyResolved.contains(e))
      .toSet();
  if (fieldsToLookUp.isNotEmpty) {
    final result = await locateTopLevelDeclarations(imports, [
      for (final type in fieldsToLookUp) ...[
        MatchSequence(type, 'class ${type}'),
        MatchSequence(type, 'typedef ${type}'),
      ],
    ]);
    if (result.isNotEmpty) {
      resolvedTypes[asset.path] = result.keys.toSet();
      for (final entry in result.entries) {
        print('Found: ${result.values} in ${entry.key}');
      }
    }
  }
}

