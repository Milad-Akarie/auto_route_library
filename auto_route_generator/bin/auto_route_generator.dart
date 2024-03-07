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
import 'utils.dart';

final _configFile = File('auto_route_config.txt');

void main() async {
  print('Starting... auto_route_generator');
  final stopWatch = Stopwatch()..start();
  late final packageResolver = PackageFileResolver.forCurrentRoot();
  print('resolved packages in ${stopWatch.elapsedMilliseconds}ms');
  final lastConfig = _configFile.existsSync() ? int.parse(_configFile.readAsStringSync()) : 0;
  final glob = Glob('lib/playground**.dart');
  final assets = glob.listSync(root: Directory.current.path).whereType<File>();

  for (final asset in assets) {
    // if (asset.lastModifiedSync().millisecondsSinceEpoch < lastConfig) continue;
    await _processFile(asset, packageResolver);
  }

  print('Time taken: ${stopWatch.elapsedMilliseconds}ms');
  _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
  stopWatch.stop();

  Directory.current.watch(events: FileSystemEvent.all, recursive: true).listen((event) async {
    final stopWatch = Stopwatch()..start();
    if (glob.matches(event.path)) {
      final asset = File(event.path);
      await _processFile(asset, packageResolver);
      print('Watched file took: ${stopWatch.elapsedMilliseconds}ms');
      _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
    }
  });
}

Future<void> _processFile(File asset, PackageFileResolver packageResolver) async {
  final bytes = asset.readAsBytesSync();
  if (!hasRouteAnnotation(bytes)) return;
  final assetContent = utf8.decode(bytes);
  final unit = parseString(content: assetContent, throwIfDiagnostics: false).unit;
  final classDeclarations = unit.declarations.whereType<ClassDeclaration>();

  final routePage = classDeclarations.firstWhereOrNull((e) => e.metadata.any((e) => e.name.name == 'RoutePage'));
  if (routePage == null) return;

  late final imports = unit.directives
      .whereType<ImportDirective>()
      .where((e) => e.uri.stringValue != null && !e.uri.stringValue!.startsWith('dart:'))
      .map((e) => Uri.parse(e.uri.stringValue!))
      .sortedBy<num>((e) => !e.isScheme('package') || e.pathSegments.first == rootPackageName ? 0 : 1)
      .toSet();

  final constructors = routePage.constructors;
  if (constructors.isEmpty) return;
  final parameters = routePage.constructors.first.parametersList;


  final fieldsToLookUp = routePage.fields
      .where((e) => !e.type!.isDartCoreType)
      .map((e) => e.typeName)
      .whereNotNull()
      .toSet();

  if (fieldsToLookUp.isNotEmpty) {
    final result = locateTopLevelDeclarations(
      asset.uri,
      imports,
      [
        for (final type in fieldsToLookUp) ...[
          MatchSequence(type, 'class ${type}'),
          MatchSequence(type, 'typedef ${type}'),
        ],
      ],
      packageResolver,
    );
    if (result.isNotEmpty) {
      for (final entry in result.entries) {
        for (final result in entry.value.where((e) => e.identifier != 'export')) {
          print('Found: ${result.identifier} : ${entry.key}');
        }
        // print('Found: ${result.values} in ${entry.key}');
      }
    }
  }
}
