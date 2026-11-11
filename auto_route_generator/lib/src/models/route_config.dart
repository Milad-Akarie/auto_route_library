import 'package:auto_route_generator/src/models/param_config.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:code_builder/code_builder.dart' show TypeReference;

/// holds the extracted route configs
/// to be used in `RouterClassGenerator`
class RouteConfig {
  /// Default constructor
  const new({
    required this.className,
    required this.name,
    required this.pageType,
    required this.parameters,
    required this.hasWrappedRoute,
    required this.hasConstConstructor,
    required this.isDeferredLoading,
    required this.typeParameters,
    this._pathParams = const [],
  });

  /// Deserializes the route config from json
  factory fromJson(Map<String, dynamic> map) {
    final pathParams = <PathParamConfig>[];
    final pathParamsJson = (map['pathParams'] as List<Object?>?)
        ?.cast<Map<String, dynamic>>();
    if (pathParamsJson != null) {
      for (final arg in pathParamsJson) {
        pathParams.add(PathParamConfig.fromJson(arg));
      }
    }

    final parameters = <ParamConfig>[];
    final parametersJson = (map['parameters'] as List<Object?>?)
        ?.cast<Map<String, dynamic>>();
    if (parametersJson != null) {
      for (final arg in parametersJson) {
        parameters.add(ParamConfig.fromJson(arg));
      }
    }

    return RouteConfig(
      typeParameters: [
        for (final p in map['typeParameters'] as List<Object?>? ?? const [])
          RouteTypeParameter._fromJson(p as Map<String, dynamic>),
      ],
      name: map['name'] as String?,
      pathParams: pathParams,
      pageType: map['pageType'] == null
          ? null
          : ResolvedType.fromJson(map['pageType'] as Map<String, dynamic>),
      className: map['className'] as String,
      parameters: parameters,
      hasWrappedRoute: map['hasWrappedRoute'] as bool?,
      hasConstConstructor: map['hasConstConstructor'] as bool,
      isDeferredLoading: map['deferredLoading'] as bool?,
    );
  }

  /// the route name
  final String? name;

  /// the path parameters of the route
  final List<PathParamConfig> _pathParams;

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
  final bool? isDeferredLoading;

  /// The type parameters of the page class, which the route and its args
  /// class take too; empty for a page that has none.
  final List<RouteTypeParameter> typeParameters;

  /// Whether the page class has type parameters.
  bool get isGeneric => typeParameters.isNotEmpty;

  /// Returns all the path/query params
  List<ParamConfig> get pathQueryParams {
    return parameters.where((p) => p.isPathParam || p.isQueryParam).toList();
  }

  /// Returns all the optional params
  Iterable<ParamConfig> get positionalParams =>
      parameters.where((p) => p.isPositional);

  /// Returns all the named params
  Iterable<ParamConfig> get namedParams => parameters.where((p) => p.isNamed);

  /// Resolves the route name
  String getName(String? replacementInRouteName) {
    String nameToUse;
    if (name != null) {
      nameToUse = name!;
    } else if (replacementInRouteName
            ?.split(',')
            .map((part) => part.trim())
            .toList()
        case [final pattern, final replacement]) {
      nameToUse = className.replaceAll(RegExp(pattern), replacement);
    } else {
      nameToUse = '${className}Route';
    }
    return capitalize(nameToUse);
  }

  /// Whether this route has arguments that can't be parsed
  bool get hasUnparsableRequiredArgs => parameters.any(
    (p) =>
        (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam,
  );

  /// Clones the route config with its deferred loading set to [isDeferred]
  RouteConfig withDeferredLoading({required bool isDeferred}) {
    return RouteConfig(
      typeParameters: typeParameters,
      name: name,
      pathParams: _pathParams,
      pageType: pageType,
      className: className,
      parameters: parameters,
      hasWrappedRoute: hasWrappedRoute,
      hasConstConstructor: hasConstConstructor,
      isDeferredLoading: isDeferred,
    );
  }

  /// Serializes the route config to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'pathParams': _pathParams.map((e) => e.toJson()).toList(),
      'pageType': pageType?.toJson(),
      'className': className,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'hasWrappedRoute': hasWrappedRoute,
      'hasConstConstructor': hasConstConstructor,
      'deferredLoading': isDeferredLoading,
      if (isGeneric)
        'typeParameters': typeParameters.map((e) => e.toJson()).toList(),
    };
  }
}

/// A type parameter of a page class, such as `T extends Item` in
/// `PickerPage<T extends Item>`.
class RouteTypeParameter {
  /// Default constructor
  const new({required this.name, required this._bound});

  /// Deserializes the type parameter from json
  factory _fromJson(Map<String, dynamic> map) {
    final bound = map['bound'];
    return RouteTypeParameter(
      name: map['name'] as String,
      bound: bound == null
          ? null
          : ResolvedType.fromJson(bound as Map<String, dynamic>),
    );
  }

  /// The name of the type parameter, such as `T`.
  final String name;

  /// The type after `extends`, or `null` when there is none.
  final ResolvedType? _bound;

  /// The type parameter as it is declared, with its bound.
  TypeReference get declaration => .new(
    (b) => b
      ..symbol = name
      ..bound = _bound?.refer,
  );

  /// Serializes the type parameter to json
  Map<String, dynamic> toJson() => {'name': name, 'bound': ?_bound?.toJson()};
}
