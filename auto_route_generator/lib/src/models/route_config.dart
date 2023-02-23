import '../../utils.dart';
import 'importable_type.dart';
import 'route_parameter_config.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

class RouteConfig {
  final String? name;
  final List<PathParamConfig> pathParams;
  final ResolvedType? pageType;
  final String className;
  final ResolvedType? returnType;
  final List<ParamConfig> parameters;
  final bool? hasWrappedRoute;
  final String? replacementInRouteName;
  final bool hasConstConstructor;
  final bool? deferredLoading;

  RouteConfig({
    this.name,
    this.pathParams = const [],
    this.pageType,
    required this.className,
    this.parameters = const [],
    this.hasWrappedRoute,
    this.returnType,
    this.replacementInRouteName,
    this.hasConstConstructor = false,
    this.deferredLoading,
  });

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  List<ParamConfig> get argParams {
    return parameters.where((p) => !p.isPathParam && !p.isQueryParam).toList();
  }

  List<ParamConfig> get pathQueryParams {
    return parameters.where((p) => (p.isPathParam || p.isQueryParam)).toList();
  }

  Iterable<ParamConfig> get requiredParams =>
      parameters.where((p) => p.isPositional && !p.isOptional);

  Iterable<ParamConfig> get positionalParams =>
      parameters.where((p) => p.isPositional);

  Iterable<ParamConfig> get namedParams => parameters.where((p) => p.isNamed);

  String getName([String? replacementInRouteName]) {
    var nameToUse;
    if (name != null) {
      nameToUse = name;
    } else if (replacementInRouteName != null &&
        replacementInRouteName.split(',').length == 2) {
      var parts = replacementInRouteName.split(',');
      nameToUse = className.replaceAll(RegExp(parts[0]), parts[1]);
    } else {
      nameToUse = "${className}Route";
    }
    return capitalize(nameToUse);
  }

  bool get hasUnparsableRequiredArgs => parameters.any((p) =>
      (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);

  RouteConfig copyWith({
    String? name,
    String? pathName,
    List<PathParamConfig>? pathParams,
    bool? initial,
    bool? fullMatch,
    ResolvedType? pageType,
    String? className,
    ResolvedType? returnType,
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
      returnType: returnType ?? this.returnType,
      parameters: parameters ?? this.parameters,
      hasWrappedRoute: hasWrappedRoute ?? this.hasWrappedRoute,
      replacementInRouteName:
          replacementInRouteName ?? this.replacementInRouteName,
      hasConstConstructor: hasConstConstructor ?? this.hasConstConstructor,
      deferredLoading: deferredLoading ?? this.deferredLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': this.name,
      'pathParams': this.pathParams.map((e) => e.toJson()).toList(),
      'pageType': this.pageType?.toJson(),
      'className': this.className,
      'returnType': this.returnType?.toJson(),
      'parameters': this.parameters.map((e) => e.toJson()).toList(),
      'hasWrappedRoute': this.hasWrappedRoute,
      'replacementInRouteName': this.replacementInRouteName,
      'hasConstConstructor': this.hasConstConstructor,
      'deferredLoading': this.deferredLoading,
    };
  }

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
      pageType: map['pageType'] == null
          ? null
          : ResolvedType.fromJson(map['pageType']),
      className: map['className'] as String,
      returnType: map['returnType'] == null
          ? null
          : ResolvedType.fromJson(map['returnType']),
      parameters: parameters,
      hasWrappedRoute: map['hasWrappedRoute'] as bool?,
      replacementInRouteName: map['replacementInRouteName'] as String?,
      hasConstConstructor: map['hasConstConstructor'] as bool,
      deferredLoading: map['deferredLoading'] as bool?,
    );
  }
}
