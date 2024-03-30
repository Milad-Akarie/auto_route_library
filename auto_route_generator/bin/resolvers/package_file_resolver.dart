import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const packageConfigPath = '.dart_tool/package_config.json';
const _skyEnginePackage = 'sky_engine';

class PackageFileResolver {
  final Map<String, String> packageToPath;
  final Map<String, String> pathToPackage;

  PackageFileResolver(this.packageToPath, this.pathToPackage);

  factory PackageFileResolver.forCurrentRoot() {
    return PackageFileResolver.forRoot(Directory.current.path);
  }

  factory PackageFileResolver.forRoot(String path) {
    final packageConfig = File.fromUri(Uri.file(p.join(path, packageConfigPath)));
    final packageConfigJson = jsonDecode(packageConfig.readAsStringSync())['packages'] as List<dynamic>;
    final packageToPath = <String, String>{};
    final pathToPackage = <String, String>{};
    for (var entry in packageConfigJson) {
      final name = entry['name'] as String;
      if (name[0] == '_') continue;
      final packageUri = Uri.parse(entry['rootUri'] as String);
      final absoluteUri = packageUri.hasScheme
          ? packageUri
          : Directory.current.uri.resolve(
              packageUri.pathSegments.skip(1).join('/'),
            );
      final resolvedPath = absoluteUri.replace(path: p.canonicalize(absoluteUri.path)).toString();
      packageToPath[name] = resolvedPath;
      pathToPackage[resolvedPath] = name;
    }
    return PackageFileResolver(packageToPath, pathToPackage);
  }

  Uri resolve(Uri uri, {Uri? relativeTo}) {
    if (uri.isScheme('package')) {
      final package = uri.pathSegments.first;
      final packagePath = packageToPath[package];
      if (packagePath != null) {
        return Uri.parse(p.joinAll([packagePath, 'lib', ...uri.pathSegments.skip(1)]));
      }
    } else if (uri.isScheme('dart')) {
      final packagePath = packageToPath[_skyEnginePackage];
      final dir = uri.path;
      if (packagePath != null) {
        return Uri.parse(p.joinAll([packagePath, 'lib', dir, '${dir}.dart']));
      }
    } else if (!uri.hasScheme) {
      assert(relativeTo != null);
      return relativeTo!.resolveUri(uri);
    }
    return uri;
  }

  String uriToPackage(Uri uri) {
    final splits = uri.replace(scheme: 'file').toString().split('/lib/');
    final package = pathToPackage[splits.firstOrNull];
    if (package == null) return uri.toString();
    return 'package:${package}/${splits.last}';
  }
}
