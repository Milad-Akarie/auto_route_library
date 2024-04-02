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
  printBlue('AutoRoute Builder Started');
  var milliSecondsTaken = 0;
  final processWatch = Stopwatch()..start();
  final root = Directory.current.uri;
  // final root = Uri.parse('/Users/milad/AndroidStudioProjects/$rootPackage');
  late final fileResolver = PackageFileResolver.forRoot(root.path);
  late final matcher = SequenceMatcher(fileResolver);
  final glob = Glob('**screen.dart');

  final libDir = Directory.fromUri(Uri.parse(p.join(root.path, 'lib')));
  final assets = glob.listSync(root: libDir.path, followLinks: true).whereType<File>();
  final tracker = RoutesTracker.load(Set.of(assets.map((e) => e.path)));
  printYellow('Assets collected in ${processWatch.elapsedMilliseconds}ms');
  milliSecondsTaken += processWatch.elapsedMilliseconds;
  processWatch.reset();

  for (final asset in assets) {
    await _processFile(asset, () => matcher, tracker);
  }
  if (tracker.hasChanges) {
    printYellow('Processing took: ${processWatch.elapsedMilliseconds}ms');
  } else {
    printYellow('Detecting changes took: ${processWatch.elapsedMilliseconds}ms');
  }
  milliSecondsTaken += processWatch.elapsedMilliseconds;
  processWatch.reset();
  if (tracker.routes.isNotEmpty) {
    _generateRouterIfNeeded(tracker);
  }
  printGreen('Build finished in: ${milliSecondsTaken}ms');

  processWatch.stop();
  // printTeal('Watching for changes inside: lib | ${glob.pattern}');
  // libDir.watch(events: FileSystemEvent.all, recursive: true).listen((event) async {
  //   if (glob.matches(event.path)) {
  //     final stopWatch = Stopwatch()..start();
  //     final asset = File(event.path);
  //     await _processFile(asset, () => matcher, tracker);
  //     if (tracker.hasChanges) {
  //       printYellow('Processing took: ${stopWatch.elapsedMilliseconds}ms');
  //     } else {
  //       printYellow('Detecting changes took: ${stopWatch.elapsedMilliseconds}ms');
  //     }
  //     _generateRouterIfNeeded(tracker);
  //   }
  // });
}

void _generateRouterIfNeeded(RoutesTracker tracker) {
  if (tracker.hasChanges) {
    final routerConfig = RouterConfig(
      routerClassName: 'AstRouterTest',
      path: '/lib/router.dart',
      replaceInRouteName: 'Screen,Route',
      cacheHash: 0,
      generateForDir: ['lib'],
    );
    File('router.dart').writeAsStringSync(
      generateLibrary(routerConfig, routes: tracker.routes),
    );
    printPurple('Generating router file');
    tracker.presist();
  }
}

Future<void> _processFile(File asset, SequenceMatcher Function() matcher, RoutesTracker tracker) async {
  if (!tracker.shouldUpdate(asset)) {
    return;
  }

  final bytes = await asset.readAsBytesSync();

  if (!hasRouteAnnotation(bytes)) {
    tracker.removeBySource(asset.uri.path);
    return;
  }

  final assetContent = utf8.decode(bytes);
  final unit = parseString(content: assetContent, throwIfDiagnostics: false).unit;

  final classes = unit.classes;
  final routePage = classes.firstWhereOrNull((e) => e.hasRoutePageAnnotation);
  if (routePage == null || !routePage.hasDefaultConstructor) return null;
  final annotation = routePage.routePageAnnotation;

  final snapshotHash = unit.calculateUpdatableHash();

  final className = routePage.name.lexeme;
  final existingRoute = tracker.routeByIdentity(asset.uri.path, className);

  if (existingRoute?.hash == snapshotHash) {
    // printGreen('No Changes Detected in: ${className}');
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

  if (identifiersToLookUp.isNotEmpty) {
    final result = await matcher().locateTopLevelDeclarations(
      asset.uri,
      imports,
      [
        for (final type in identifiersToLookUp) ...[
          Sequence(type, 'class ${type}', terminators: [32, 0x3C]),
          Sequence(type, 'typedef ${type}', terminators: [32, 0x3C]),
          Sequence(type, 'enum ${type}', terminators: [32]),
          Sequence(type, 'mixin ${type}', terminators: [32, 0x3C]),
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
      name: annotation.getNamedString('name'),
      deferredLoading: annotation.getNamedBool('deferredLoading'),
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
