/// RouterConfig
class RouterConfig {
  /// Default constructor
  const new({
    required this.routerClassName,
    this.replaceInRouteName,
    this.deferredLoading = false,
    this.isPartOfLibrary = false,
    required this.path,
    required this.cacheHash,
    required this.generateForDir,
    this.argsEquality = false,
  });

  /// Deserializes a map to an instance of [RouterConfig]
  factory fromJson(Map<String, dynamic> map) {
    return RouterConfig(
      routerClassName: map['routerClassName'] as String,
      replaceInRouteName: map['replaceInRouteName'] as String?,
      deferredLoading: map['deferredLoading'] as bool,
      isPartOfLibrary: map['usesPartBuilder'] as bool,
      path: map['path'] as String,
      cacheHash: map['cacheHash'] as int?,
      generateForDir: (map['generateForDir'] as List<Object?>).cast(),
      argsEquality: map['argsEquality'] as bool,
    );
  }

  /// The name of the router class
  final String routerClassName;

  /// The string to replace in route names
  final String? replaceInRouteName;

  /// Whether the router should use deferred loading
  final bool deferredLoading;

  /// Whether the router should use part builder
  final bool isPartOfLibrary;

  /// The path to the router file
  final String path;

  /// The cache hash of the router properties
  final int? cacheHash;

  /// The list of directories to generate for
  final List<String> generateForDir;

  /// Whether to generate equality operator and hashCode for route args
  final bool argsEquality;

  /// Serializes this instance to a map
  Map<String, dynamic> toJson() {
    return {
      'routerClassName': routerClassName,
      'replaceInRouteName': replaceInRouteName,
      'deferredLoading': deferredLoading,
      'usesPartBuilder': isPartOfLibrary,
      'path': path,
      'cacheHash': cacheHash,
      'generateForDir': generateForDir,
      'argsEquality': argsEquality,
    };
  }
}
