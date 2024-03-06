import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import 'lookup_utils.dart';
import 'package_file_resolver.dart';
import 'utils.dart';

const _dartCoreTypeNames = <String>{
  'bool',
  'int',
  'double',
  'num',
  'String',
  'List',
  'Map',
  'Set',
  'Iterable',
  'void',
  'dynamic',
  'Object',
  'Function',
  'Null',
  'Type',
  'Symbol',
};
final _configFile = File('auto_route_config.txt');

void main() async {
  print('Starting... auto_route_generator');
  final resolvedTypes = <String, Set<String>>{};
  final stopWatch = Stopwatch()..start();
  late final packageResolver = PackageFileResolver.forCurrentRoot();
  print('resolved packages in ${stopWatch.elapsedMilliseconds}ms');
  final lastConfig = _configFile.existsSync() ? int.parse(_configFile.readAsStringSync()) : 0;
  final glob = Glob('lib/**.dart');
  final assets = glob.listSync(root: Directory.current.path).whereType<File>();

  for (final asset in assets) {
    if (asset.lastModifiedSync().millisecondsSinceEpoch < lastConfig) continue;
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

  // final assetImports = imports.map((e) => e.assetId(asset.$2)).toSet();

  // print(imports.map((e) => Uri.parse(e.uri.stringValue!)).map((e) => packageResolver.resolve(e, relativeTo: asset.$2.uri)));
  // print(assetImports.map((e) => AssetId.resolve(e.uri, from: asset.$2)));

  final alreadyResolved =
      resolvedTypes.values.fold(<String>{}, (previousValue, element) => previousValue..addAll(element));

  final fieldsToLookUp = routePage.fields
      .map((e) => e.typeName)
      .whereNotNull()
      .where((e) => !_dartCoreTypeNames.contains(e) && !alreadyResolved.contains(e))
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

extension ClassDeclarationX on ClassDeclaration {
  Iterable<FieldDeclaration> get fields => members.whereType<FieldDeclaration>();

  Iterable<MethodDeclaration> get methods => members.whereType<MethodDeclaration>();

  Iterable<ConstructorDeclaration> get constructors => members.whereType<ConstructorDeclaration>();

  Iterable<MethodDeclaration> get getters => members.whereType<MethodDeclaration>().where((e) => e.isGetter);

  Iterable<MethodDeclaration> get setters => members.whereType<MethodDeclaration>().where((e) => e.isSetter);
}

extension FieldDeclarationX on FieldDeclaration {
  String get name => fields.variables.first.name.lexeme;

  TypeAnnotation? get type => fields.type;

  String? get typeName => type?.toSource();
}

extension DirectiveX on ImportDirective {
  AssetId assetId(AssetId? from) {
    final normalized = normalizeUrl(Uri.parse(uri.stringValue!));

    return AssetId.resolve(normalized, from: from);
  }
}
