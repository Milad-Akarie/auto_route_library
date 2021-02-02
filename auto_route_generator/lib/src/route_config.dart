import 'package:auto_route_generator/import_resolver.dart';
import 'package:auto_route_generator/route_config_resolver.dart';

import '../utils.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

class RouteConfig {
  String name;
  String pathName;
  List<PathParamConfig> pathParams;
  bool initial;
  bool fullscreenDialog;
  bool fullMatch;
  bool customRouteOpaque;
  bool customRouteBarrierDismissible;
  String customRouteBarrierLabel;
  bool maintainState;
  ImportableType pageType;
  String className;
  ImportableType returnType;
  List<ParamConfig> parameters;
  ImportableType transitionBuilder;
  ImportableType customRouteBuilder;
  String redirectTo;
  bool usesTabsRouter;
  int durationInMilliseconds;
  int reverseDurationInMilliseconds;
  int routeType = RouteType.material;
  List<ImportableType> guards = [];
  String cupertinoNavTitle;
  bool hasWrapper;
  String replacementInRouteName;
  RouterConfig childRouterConfig;

  bool hasConstConstructor = false;

  RouteConfig();

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  String get templateName {
    final routeName = name ?? "${toLowerCamelCase(className)}Route";
    return pathName.contains(":") ? '_$routeName' : routeName;
  }

  bool get isParent => childRouterConfig != null;

  List<ParamConfig> get argParams {
    return parameters
            ?.where((p) => !p.isPathParam && !p.isQueryParam)
            ?.toList() ??
        [];
  }

  List<ParamConfig> get pathQueryParams {
    return parameters
            ?.where((p) => p.isPathParam || p.isQueryParam)
            ?.toList() ??
        [];
  }

  Iterable<ParamConfig> get requiredParams =>
      parameters?.where((p) => p.isPositional && !p.isOptional) ?? [];

  Iterable<ParamConfig> get positionalParams =>
      parameters?.where((p) => p.isPositional) ?? [];

  Iterable<ParamConfig> get namedParams =>
      parameters?.where((p) => p.isNamed) ?? [];

  String get routeName {
    var nameToUse;
    if (name != null) {
      nameToUse = name;
    } else if (replacementInRouteName != null &&
        replacementInRouteName.split(',').length == 2) {
      var parts = replacementInRouteName.split(',');
      nameToUse = className.replaceAll(parts[0], parts[1]);
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
}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int adaptive = 2;
  static const int custom = 3;
  static const int redirect = 4;
}
