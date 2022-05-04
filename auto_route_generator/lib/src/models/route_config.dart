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
  final bool? fullscreenDialog;
  final bool? fullMatch;
  final bool? customRouteOpaque;
  final bool? customRouteBarrierDismissible;
  final String? customRouteBarrierLabel;
  final int? customRouteBarrierColor;
  final bool? maintainState;
  final ResolvedType? pageType;
  final String className;
  final ResolvedType? returnType;
  final List<ParamConfig> parameters;
  final ResolvedType? transitionBuilder;
  final ResolvedType? customRouteBuilder;
  final String? redirectTo;
  final bool? hasWrappedRoute;
  final int? reverseDurationInMilliseconds;
  final int? durationInMilliseconds;
  final int routeType;
  final List<ResolvedType> guards;
  final String? cupertinoNavTitle;
  final String? replacementInRouteName;
  final RouterConfig? childRouterConfig;
  final bool hasConstConstructor;
  final bool usesPathAsKey;
  final List<MetaEntry> meta;

  RouteConfig({
    this.name,
    required this.pathName,
    this.pathParams = const [],
    this.initial = false,
    this.fullscreenDialog,
    this.fullMatch,
    this.customRouteOpaque,
    this.customRouteBarrierDismissible,
    this.customRouteBarrierLabel,
    this.maintainState,
    this.pageType,
    required this.className,
    this.parameters = const [],
    this.transitionBuilder,
    this.customRouteBuilder,
    this.redirectTo,
    this.hasWrappedRoute,
    this.durationInMilliseconds,
    this.reverseDurationInMilliseconds,
    this.returnType,
    this.routeType = RouteType.material,
    this.guards = const [],
    this.cupertinoNavTitle,
    this.replacementInRouteName,
    this.childRouterConfig,
    this.hasConstConstructor = false,
    this.usesPathAsKey = false,
    this.customRouteBarrierColor,
    this.meta = const [],
  });

  RouteConfig copyWith({
    String? name,
    String? pathName,
    List<PathParamConfig>? pathParams,
    bool? initial,
    bool? fullscreenDialog,
    bool? fullMatch,
    bool? customRouteOpaque,
    bool? customRouteBarrierDismissible,
    int? customRouteBarrierColor,
    String? customRouteBarrierLabel,
    bool? maintainState,
    ResolvedType? pageType,
    String? className,
    ResolvedType? returnType,
    List<ParamConfig>? parameters,
    ResolvedType? transitionBuilder,
    ResolvedType? customRouteBuilder,
    String? redirectTo,
    bool? usesTabsRouter,
    int? reverseDurationInMilliseconds,
    int? durationInMilliseconds,
    int? routeType,
    List<ResolvedType>? guards,
    String? cupertinoNavTitle,
    String? replacementInRouteName,
    RouterConfig? childRouterConfig,
    bool? hasConstConstructor,
    bool? usesPathAsKey,
    List<MetaEntry>? meta,
  }) {
    if ((name == null || identical(name, this.name)) &&
        (pathName == null || identical(pathName, this.pathName)) &&
        (usesPathAsKey == null ||
            identical(usesPathAsKey, this.usesPathAsKey)) &&
        (pathParams == null || identical(pathParams, this.pathParams)) &&
        (initial == null || identical(initial, this.initial)) &&
        (fullscreenDialog == null ||
            identical(fullscreenDialog, this.fullscreenDialog)) &&
        (fullMatch == null || identical(fullMatch, this.fullMatch)) &&
        (customRouteOpaque == null ||
            identical(customRouteOpaque, this.customRouteOpaque)) &&
        (customRouteBarrierDismissible == null ||
            identical(customRouteBarrierDismissible,
                this.customRouteBarrierDismissible)) &&
        (customRouteBarrierLabel == null ||
            identical(customRouteBarrierLabel, this.customRouteBarrierLabel)) &&
        (maintainState == null ||
            identical(maintainState, this.maintainState)) &&
        (pageType == null || identical(pageType, this.pageType)) &&
        (className == null || identical(className, this.className)) &&
        (returnType == null || identical(returnType, this.returnType)) &&
        (parameters == null || identical(parameters, this.parameters)) &&
        (transitionBuilder == null ||
            identical(transitionBuilder, this.transitionBuilder)) &&
        (customRouteBuilder == null ||
            identical(customRouteBuilder, this.customRouteBuilder)) &&
        (redirectTo == null || identical(redirectTo, this.redirectTo)) &&
        (usesTabsRouter == null ||
            identical(usesTabsRouter, this.hasWrappedRoute)) &&
        (reverseDurationInMilliseconds == null ||
            identical(reverseDurationInMilliseconds,
                this.reverseDurationInMilliseconds)) &&
        (durationInMilliseconds == null ||
            identical(durationInMilliseconds, this.durationInMilliseconds)) &&
        (routeType == null || identical(routeType, this.routeType)) &&
        (guards == null || identical(guards, this.guards)) &&
        (cupertinoNavTitle == null ||
            identical(cupertinoNavTitle, this.cupertinoNavTitle)) &&
        (replacementInRouteName == null ||
            identical(replacementInRouteName, this.replacementInRouteName)) &&
        (childRouterConfig == null ||
            identical(childRouterConfig, this.childRouterConfig)) &&
        (hasConstConstructor == null ||
            identical(hasConstConstructor, this.hasConstConstructor))) {
      return this;
    }

    return RouteConfig(
      name: name ?? this.name,
      pathName: pathName ?? this.pathName,
      pathParams: pathParams ?? this.pathParams,
      initial: initial ?? this.initial,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      fullMatch: fullMatch ?? this.fullMatch,
      customRouteOpaque: customRouteOpaque ?? this.customRouteOpaque,
      customRouteBarrierDismissible:
          customRouteBarrierDismissible ?? this.customRouteBarrierDismissible,
      customRouteBarrierLabel:
          customRouteBarrierLabel ?? this.customRouteBarrierLabel,
      maintainState: maintainState ?? this.maintainState,
      pageType: pageType ?? this.pageType,
      className: className ?? this.className,
      returnType: returnType ?? this.returnType,
      parameters: parameters ?? this.parameters,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
      customRouteBuilder: customRouteBuilder ?? this.customRouteBuilder,
      redirectTo: redirectTo ?? this.redirectTo,
      hasWrappedRoute: usesTabsRouter ?? this.hasWrappedRoute,
      reverseDurationInMilliseconds:
          reverseDurationInMilliseconds ?? this.reverseDurationInMilliseconds,
      durationInMilliseconds:
          durationInMilliseconds ?? this.durationInMilliseconds,
      routeType: routeType ?? this.routeType,
      guards: guards ?? this.guards,
      cupertinoNavTitle: cupertinoNavTitle ?? this.cupertinoNavTitle,
      replacementInRouteName:
          replacementInRouteName ?? this.replacementInRouteName,
      childRouterConfig: childRouterConfig ?? this.childRouterConfig,
      hasConstConstructor: hasConstConstructor ?? this.hasConstConstructor,
      usesPathAsKey: usesPathAsKey ?? this.usesPathAsKey,
      meta: meta ?? this.meta,
      customRouteBarrierColor:
          customRouteBarrierColor ?? this.customRouteBarrierColor,
    );
  }

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  String get templateName {
    final routeName = name ?? "${toLowerCamelCase(className)}Route";
    return pathName.contains(":") ? '_$routeName' : routeName;
  }

  bool get isParent => childRouterConfig != null;

  List<ParamConfig> get argParams {
    return parameters.where((p) => !p.isPathParam && !p.isQueryParam).toList();
  }

  List<ParamConfig> get pathQueryParams {
    return parameters.where((p) => p.isPathParam || p.isQueryParam).toList();
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

  String get pageTypeName {
    switch (routeType) {
      case RouteType.cupertino:
        return 'CupertinoPageX';
      case RouteType.custom:
        return 'CustomPage';
      case RouteType.adaptive:
        return 'AdaptivePage';
      default:
        return 'MaterialPageX';
    }
  }

  bool get hasUnparsableRequiredArgs => parameters.any((p) =>
      (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);
}

class MetaEntry<T> {
  MetaEntry({
    required this.type,
    required this.key,
    required this.value,
  });

  final String type;
  final T value;
  final String key;
}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int adaptive = 2;
  static const int custom = 3;
  static const int redirect = 4;
}
