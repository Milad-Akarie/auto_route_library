class RouterConfig {
  final String routerClassName;
  final String? replaceInRouteName;
  final bool deferredLoading;
  final bool usesPartBuilder;
  final String path;
  final int? cacheHash;
  final List<String> generateForDir;

  const RouterConfig({
    required this.routerClassName,
    this.replaceInRouteName,
    this.deferredLoading = false,
    this.usesPartBuilder = false,
    required this.path,
    required this.cacheHash,
    required this.generateForDir,
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
    );
  }
}
