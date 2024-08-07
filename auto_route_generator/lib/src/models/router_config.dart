/// RouterConfig
class RouterConfig {
  /// The name of the router class
  final String routerClassName;

  /// The string to replace in route names
  final String? replaceInRouteName;

  /// Whether the router should use deferred loading
  final bool deferredLoading;

  /// Whether the router should use part builder
  final bool usesPartBuilder;

  /// The path to the router file
  final String path;

  /// The cache hash of the router properties
  final int? cacheHash;

  /// The list of directories to generate for
  final List<String> generateForDir;

  /// Default constructor
  const RouterConfig({
    required this.routerClassName,
    this.replaceInRouteName,
    this.deferredLoading = false,
    this.usesPartBuilder = false,
    required this.path,
    required this.cacheHash,
    required this.generateForDir,
  });

  /// Serializes this instance to a map
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

  /// Deserializes a map to an instance of [RouterConfig]
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
