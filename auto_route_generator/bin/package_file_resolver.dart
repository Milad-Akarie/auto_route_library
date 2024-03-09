import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const packageConfigPath = '.dart_tool/package_config.json';
const _skyEnginePackage = 'sky_engine';

class PackageFileResolver {
  static Uri packageConfigUri = Uri.file(p.join(Directory.current.path, packageConfigPath));
  final Map<String, String> packageToPath;

  PackageFileResolver(this.packageToPath);

  factory PackageFileResolver.forCurrentRoot() {
    final packageConfig = File.fromUri(packageConfigUri);
    final packageConfigJson = jsonDecode(packageConfig.readAsStringSync())['packages'] as List<dynamic>;
    final packageToPath = <String, String>{};
    for (var entry in packageConfigJson) {
      final name = entry['name'] as String;
      if (name[0] == '_') continue;
      final packageUri = Uri.parse(entry['rootUri'] as String);
      final resolvedUri = packageUri.hasScheme
          ? packageUri
          : Directory.current.uri.resolveUri(
              packageUri.replace(
                pathSegments: packageUri.pathSegments.skip(1),
              ),
            );
      packageToPath[name] = resolvedUri.toString();
    }
    return PackageFileResolver(packageToPath);
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
    final segments = uri.pathSegments;
    final libIndex = segments.indexOf('lib');
    if (libIndex > 1) {
      return 'package:${segments[libIndex - 1]}/${segments.sublist(libIndex + 1).join('/')}';
    }
    return uri.toString();
  }
}
