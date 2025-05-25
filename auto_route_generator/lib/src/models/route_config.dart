import '../../utils.dart';
import 'resolved_type.dart';
import 'route_parameter_config.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]
class RouteConfig {
  /// the route name
  final String? name;

  /// the path parameters of the route
  final List<PathParamConfig> pathParams;

  /// the page type of the route
  final ResolvedType? pageType;

  /// the class name of the route
  final String className;

  /// the parameters of the route
  final List<ParamConfig> parameters;

  /// whether the route has a wrapped route
  final bool? hasWrappedRoute;

  /// whether the route has a const constructor
  final bool hasConstConstructor;

  /// whether the route is deferred
  final bool? deferredLoading;

  /// Default constructor
  RouteConfig({
    this.name,
    this.pathParams = const [],
    this.pageType,
    required this.className,
    this.parameters = const [],
    this.hasWrappedRoute,
    this.hasConstConstructor = false,
    this.deferredLoading,
  });

  /// The class name for ArgumentsHolder
  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  /// Returns all the non path/query params
  List<ParamConfig> get argParams {
    return parameters.where((p) => !p.isPathParam && !p.isQueryParam).toList();
  }

  /// Returns all the path/query params
  List<ParamConfig> get pathQueryParams {
    return parameters.where((p) => (p.isPathParam || p.isQueryParam)).toList();
  }

  /// Returns all the required params
  Iterable<ParamConfig> get requiredParams => parameters.where((p) => p.isPositional && !p.isOptional);

  /// Returns all the optional params
  Iterable<ParamConfig> get positionalParams => parameters.where((p) => p.isPositional);

  /// Returns all the named params
  Iterable<ParamConfig> get namedParams => parameters.where((p) => p.isNamed);

  /// Resolves the route name
  String getName([String? replacementInRouteName]) {
    String nameToUse;
    if (name != null) {
      nameToUse = name!;
    } else if (replacementInRouteName != null && replacementInRouteName.split(',').length == 2) {
      var parts = replacementInRouteName.split(',');
      nameToUse = className.replaceAll(RegExp(parts[0]), parts[1]);
    } else {
      nameToUse = "${className}Route";
    }
    return capitalize(nameToUse);
  }

  /// Whether this route has arguments that can't be parsed
  bool get hasUnparsableRequiredArgs =>
      parameters.any((p) => (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);

  /// Clones the route config with the given parameters
  RouteConfig copyWith({
    String? name,
    String? pathName,
    List<PathParamConfig>? pathParams,
    bool? initial,
    bool? fullMatch,
    ResolvedType? pageType,
    String? className,
    List<ParamConfig>? parameters,
    String? redirectTo,
    bool? hasWrappedRoute,
    String? replacementInRouteName,
    bool? hasConstConstructor,
    bool? deferredLoading,
  }) {
    return RouteConfig(
      name: name ?? this.name,
      pathParams: pathParams ?? this.pathParams,
      pageType: pageType ?? this.pageType,
      className: className ?? this.className,
      parameters: parameters ?? this.parameters,
      hasWrappedRoute: hasWrappedRoute ?? this.hasWrappedRoute,
      hasConstConstructor: hasConstConstructor ?? this.hasConstConstructor,
      deferredLoading: deferredLoading ?? this.deferredLoading,
    );
  }

  /// Serializes the route config to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pathParams': pathParams.map((e) => e.toJson()).toList(),
      'pageType': pageType?.toJson(),
      'className': className,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'hasWrappedRoute': hasWrappedRoute,
      'hasConstConstructor': hasConstConstructor,
      'deferredLoading': deferredLoading,
    };
  }

  /// Deserializes the route config from json
  factory RouteConfig.fromJson(Map<String, dynamic> map) {
    final pathParams = <PathParamConfig>[];
    if (map['pathParams'] != null) {
      for (final arg in map['pathParams']) {
        pathParams.add(PathParamConfig.fromJson(arg));
      }
    }

    final parameters = <ParamConfig>[];
    if (map['parameters'] != null) {
      for (final arg in map['parameters']) {
        parameters.add(ParamConfig.fromJson(arg));
      }
    }

    return RouteConfig(
      name: map['name'] as String?,
      pathParams: pathParams,
      pageType: map['pageType'] == null ? null : ResolvedType.fromJson(map['pageType']),
      className: map['className'] as String,
      parameters: parameters,
      hasWrappedRoute: map['hasWrappedRoute'] as bool?,
      hasConstConstructor: map['hasConstConstructor'] as bool,
      deferredLoading: map['deferredLoading'] as bool?,
    );
  }
}
