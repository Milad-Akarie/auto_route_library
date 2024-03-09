import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import 'ast_extensions.dart';
import 'ast_type_resolver.dart';
import 'package_file_resolver.dart';
import 'sdt_out_utils.dart';
import 'sequence_matcher/sequence.dart';
import 'sequence_matcher/sequence_matcher.dart';
import 'sequence_matcher/utils.dart';
import 'utils.dart';

final _configFile = File('auto_route_config.txt');

void main() async {
  printBlue('Looking for route pages...');
  final stopWatch = Stopwatch()..start();
  late final matcher = SequenceMatcher(PackageFileResolver.forCurrentRoot());
  final lastGenerate = _configFile.existsSync() ? int.parse(_configFile.readAsStringSync()) : 0;
  final glob = Glob('**.dart');
  final libDir = Directory.fromUri(Directory.current.uri.resolve('lib'));
  final assets = glob.listSync(root: libDir.path, followLinks: true).whereType<File>();
  final routesResult =
      await Future.wait([for (final asset in assets) _processFile(asset, () => matcher, lastGenerate)]);
  final routes = routesResult.whereNotNull();
  for (final route in routes) {
    print(route.className);
  }

  printGreen('Build finished in: ${stopWatch.elapsedMilliseconds}ms');

  _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
  stopWatch.stop();
  printYellow('Watching for changes inside: lib | ${glob.pattern}');
  libDir.watch(events: FileSystemEvent.all, recursive: true).listen((event) async {
    if (glob.matches(event.path)) {
      final stopWatch = Stopwatch()..start();
      final asset = File(event.path);
      await _processFile(asset, () => matcher, lastGenerate);
      printGreen('Watched file took: ${stopWatch.elapsedMilliseconds}ms');
      _configFile.writeAsStringSync((DateTime.timestamp().millisecondsSinceEpoch).toString());
    }
  });
}

Future<RouteConfig?> _processFile(File asset, SequenceMatcher Function() matcher, int lastGenerate) async {
  // if (asset.lastModifiedSync().millisecondsSinceEpoch < lastGenerate) return;
  final bytes = asset.readAsBytesSync();
  if (!hasRouteAnnotation(bytes)) return null;

  final assetContent = utf8.decode(bytes);
  final unit = parseString(content: assetContent, throwIfDiagnostics: false).unit;
  final classDeclarations = unit.declarations.whereType<ClassDeclaration>();
  final routePage = classDeclarations.firstWhereOrNull((e) => e.hasRoutePageAnnotation);
  if (routePage == null || !routePage.hasDefaultConstructor) return null;
  final annotation = routePage.routePageAnnotation;
  final className = routePage.name.lexeme;

  printBlue('Processing: ${className}');

  late final imports = unit.directives
      .whereType<ImportDirective>()
      .where((e) => e.uri.stringValue != null)
      .map((e) => Uri.parse(e.uri.stringValue!))
      .sortedBy<num>((e) => !e.hasScheme || e.pathSegments.first == rootPackageName ? 0 : 1)
      .toSet();

  final params = routePage.defaultConstructorParams;

  final identifiersToLookUp = {
    ...annotation.returnIdentifiers,
    for (final param in params) ...?param.type?.identifiers,
  }.whereNot(dartCoreTypeNames.contains);

  final resolvedParams = <ParamConfig>[];
  final resolvedLibs = {
    asset.uri.path: {className},
  };
  if (identifiersToLookUp.isNotEmpty) {
    final result = await matcher().locateTopLevelDeclarations(
      asset.uri,
      imports,
      [
        for (final type in identifiersToLookUp) ...[
          Sequence(type, 'class ${type}'),
          Sequence(type, 'typedef ${type}'),
        ],
      ],
    );
    resolvedLibs.addAll({
      for (final entry in result.entries) entry.key: entry.value.map((e) => e.identifier).toSet(),
    });
  }
  final typeResolver = AstTypeResolver(resolvedLibs, matcher().fileResolver);
  print(typeResolver.resolveImport(className));
  return RouteConfig(
    className: className,
    pageType: ResolvedType(
      name: className,
      import: typeResolver.resolveImport(className),
    ),
  );
}
