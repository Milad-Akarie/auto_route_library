import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:auto_route_generator/src/code_builder/library_builder.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/router_config.dart';
import 'package:auto_route_generator/src/models/routes_tracker.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import 'ast_extensions.dart';
import 'resolvers/ast_parameter_resolver.dart';
import 'resolvers/ast_type_resolver.dart';
import 'resolvers/package_file_resolver.dart';
import 'sdt_out_utils.dart';
import 'sequence_matcher/sequence.dart';
import 'sequence_matcher/sequence_matcher.dart';
import 'sequence_matcher/utils.dart';
import 'utils.dart';

late final rootPackage = rootPackageName;

void main() async {
  printBlue('AutoRoute Builder Started...');
  final stopWatch = Stopwatch()..start();
  final root = Directory.current.uri;
  // final root = Uri.parse('/Users/milad/AndroidStudioProjects/$rootPackage');
  late final fileResolver = PackageFileResolver.forRoot(root.path);
  late final matcher = SequenceMatcher(fileResolver);
  final tracker = RoutesTracker.load();
  final glob = Glob('**screen.dart');

  final libDir = Directory.fromUri(Uri.parse(p.join(root.path, 'lib')));
  final assets = glob.listSync(root: libDir.path, followLinks: true).whereType<File>();
  printYellow('Assets collected in ${stopWatch.elapsedMilliseconds}ms');
  final stopWatch2 = Stopwatch()..start();

  // final routesResult = await Future.wait([
  //   for (final asset in assets) _processFile(asset, () => matcher, lastGenerate),
  // ]);
  // final port = ReceivePort();
  // await Isolate.spawn((message) { }, port.sendPort);
  // port.toList();

  //

  for (final asset in assets) {
    await _processFile(asset, () => matcher, tracker);
  }
  printYellow('Processing took ${stopWatch2.elapsedMilliseconds}ms');

  if (tracker.routes.isNotEmpty) {
    _generateRouterIfNeeded(tracker);
  }
  printGreen('Build finished in: ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.stop();
  printYellow('Watching for changes inside: lib | ${glob.pattern}');
  libDir.watch(events: FileSystemEvent.all, recursive: true).listen((event) async {
    if (glob.matches(event.path)) {
      final stopWatch = Stopwatch()..start();
      final asset = File(event.path);
      await _processFile(asset, () => matcher, tracker);
      printGreen('Watched file took: ${stopWatch.elapsedMilliseconds}ms');
      _generateRouterIfNeeded(tracker);
    }
  });
}

void _generateRouterIfNeeded(RoutesTracker tracker) {
  final routerConfig = RouterConfig(
    routerClassName: 'AstRouterTest',
    path: '/lib/router.dart',
    cacheHash: 0,
    generateForDir: ['lib'],
  );
  if (tracker.hasChanges) {
    File('router.dart').writeAsStringSync(
      generateLibrary(routerConfig, routes: tracker.routes),
    );
    printYellow('Generating router file');
    tracker.presist();
  }
}

Future<void> _processFile(File asset, SequenceMatcher Function() matcher, RoutesTracker tracker) async {
  if (asset.lastModifiedSync().millisecondsSinceEpoch < tracker.generatedTimeStamp) {
    return;
  }
  ;
  final bytes = await asset.readAsBytesSync();

  if (!hasRouteAnnotation(bytes)) {
    tracker.removeBySource(asset.uri.path);
    return;
  }
  ;

  final assetContent = utf8.decode(bytes);
  final unit = parseString(content: assetContent, throwIfDiagnostics: false).unit;

  final classes = unit.classes;
  final routePage = classes.firstWhereOrNull((e) => e.hasRoutePageAnnotation);
  if (routePage == null || !routePage.hasDefaultConstructor) return null;

  final snapshotHash = unit.calculateUpdatableHash();

  final className = routePage.name.lexeme;
  final existingRoute = tracker.routeByIdentity(asset.uri.path, className);

  if (existingRoute?.hash == snapshotHash) {
    printGreen('No Changes Detected in: ${className}');
    return;
  }
  ;
  printBlue('Processing: ${className}');

  late final imports = unit.importUris(rootPackage);
  final params = routePage.defaultConstructorParams;
  final identifiersToLookUp = routePage.nonCoreIdentifiers;

  final resolvedLibs = {
    asset.uri.path: {for (final declaration in unit.declarations) declaration.name},
  };

  final stopWatch = Stopwatch()..start();

  if (identifiersToLookUp.isNotEmpty) {
    final result = await matcher().locateTopLevelDeclarations(
      asset.uri,
      imports,
      [
        for (final type in identifiersToLookUp) ...[
          Sequence(type, 'class ${type}', terminators: [32, 0x3C]),
          Sequence(type, 'typedef ${type}', terminators: [32, 0x3C]),
        ],
      ],
    );
    if (result.isNotEmpty) {
      resolvedLibs.addAll({
        for (final entry in result.entries) entry.key: entry.value.map((e) => e.identifier).toSet(),
      });
    }
  }
  final typeResolver = AstTypeResolver(resolvedLibs, matcher().fileResolver);
  final paramResolver = AstParameterResolver(typeResolver);
  tracker.upsert(
    RouteConfig(
      className: className,
      source: asset.uri.path,
      name: className,
      hash: snapshotHash,
      pageType: ResolvedType(
        name: className,
        import: typeResolver.resolveImport(className),
      ),
      parameters: [
        for (final param in params) paramResolver.resolve(param),
      ],
    ),
  );
}
