import '../../utils.dart';
import 'importable_type.dart';
import 'route_parameter_config.dart';
import 'router_config.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

class RouteConfig {
  final String? name;
  final String pathName;
  final List<PathParamConfig> pathParams;
  final bool initial;
  final bool? fullMatch;
  final ResolvedType? pageType;
  final String className;
  final ResolvedType? returnType;
  final List<ParamConfig> parameters;
  final String? redirectTo;
  final bool? hasWrappedRoute;
  final String? replacementInRouteName;
  final bool hasConstConstructor;
  final bool? deferredLoading;

  RouteConfig({
    this.name,
    required this.pathName,
    this.pathParams = const [],
    this.initial = false,
    this.fullMatch,
    this.pageType,
    required this.className,
    this.parameters = const [],
    this.redirectTo,
    this.hasWrappedRoute,
    this.returnType,
    this.replacementInRouteName,
    this.hasConstConstructor = false,
    this.deferredLoading,
  });







  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  String get templateName {
    final routeName = name ?? "${toLowerCamelCase(className)}Route";
    return pathName.contains(":") ? '_$routeName' : routeName;
  }

  List<ParamConfig> get argParams {
    return parameters.where((p) => !p.isPathParam && !p.isQueryParam).toList();
  }

  List<ParamConfig> get pathQueryParams {
    return parameters
        .where(
            (p) => (p.isPathParam || p.isQueryParam) && !p.isInheritedPathParam)
        .toList();
  }

  Iterable<ParamConfig> get requiredParams =>
      parameters.where((p) => p.isPositional && !p.isOptional);

  Iterable<ParamConfig> get positionalParams =>
      parameters.where((p) => p.isPositional);

  Iterable<ParamConfig> get namedParams => parameters.where((p) => p.isNamed);

  String get routeName {
    var nameToUse;
    if (name != null) {
      nameToUse = name;
    } else if (replacementInRouteName != null &&
        replacementInRouteName!.split(',').length == 2) {
      var parts = replacementInRouteName!.split(',');
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
      pathName: pathName ?? this.pathName,
      pathParams: pathParams ?? this.pathParams,
      initial: initial ?? this.initial,
      fullMatch: fullMatch ?? this.fullMatch,
      pageType: pageType ?? this.pageType,
      className: className ?? this.className,
      returnType: returnType ?? this.returnType,
      parameters: parameters ?? this.parameters,
      redirectTo: redirectTo ?? this.redirectTo,
      hasWrappedRoute: hasWrappedRoute ?? this.hasWrappedRoute,
      replacementInRouteName: replacementInRouteName ?? this.replacementInRouteName,
      hasConstConstructor: hasConstConstructor ?? this.hasConstConstructor,
      deferredLoading: deferredLoading ?? this.deferredLoading,
    );
  }
}

