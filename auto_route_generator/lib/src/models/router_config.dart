import 'importable_type.dart';

class RouterConfig {
  final String routerClassName;
  final String? replaceInRouteName;
  final bool deferredLoading;
  final bool usesPartBuilder;
  final String path;
  final int? cacheHash;
  final List<String> generateForDir;
  final bool isMicroPackage;
  final List<ResolvedType> microRoutes;

  const RouterConfig({
    required this.routerClassName,
    this.replaceInRouteName,
    this.deferredLoading = false,
    this.usesPartBuilder = false,
    required this.path,
    required this.cacheHash,
    required this.generateForDir,
    this.isMicroPackage = false,
    this.microRoutes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'routerClassName': this.routerClassName,
      'replaceInRouteName': this.replaceInRouteName,
      'deferredLoading': this.deferredLoading,
      'usesPartBuilder': this.usesPartBuilder,
      'path': this.path,
      'cacheHash': this.cacheHash,
      'generateForDir': this.generateForDir,
      'isMicroPackage': this.isMicroPackage,
      'microRoutes': this.microRoutes,
    };
  }

  factory RouterConfig.fromJson(Map<String, dynamic> map) {
    return RouterConfig(
      routerClassName: map['routerClassName'] as String,
      replaceInRouteName: map['replaceInRouteName'] as String?,
      deferredLoading: map['deferredLoading'] as bool,
      usesPartBuilder: map['usesPartBuilder'] as bool,
      path: map['path'] as String,
      cacheHash: map['cacheHash'] as int?,
      generateForDir: (map['generateForDir'] as List<dynamic>).cast<String>(),
      isMicroPackage: map['isMicroPackage'] as bool,
      microRoutes: (map['microRoutes'] as List<dynamic>)
          .map((e) => ResolvedType.fromJson(e))
          .toList(),
    );
  }
}
