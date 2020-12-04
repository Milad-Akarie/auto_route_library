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
  bool customRouteOpaque;
  bool customRouteBarrierDismissible;
  bool maintainState;
  ImportableType pageType;
  String className;
  ImportableType returnType;
  List<ParamConfig> parameters;
  ImportableType transitionBuilder;
  int durationInMilliseconds;
  int routeType = RouteType.material;
  List<ImportableType> guards = [];
  String cupertinoNavTitle;
  bool hasWrapper;
  RouterConfig routerConfig;

  bool hasConstConstructor = false;

  RouteConfig();

  String get argumentsHolderClassName {
    return '${className}Arguments';
  }

  String get templateName {
    return pathName.contains(":") ? '_$name' : name;
  }

  bool get isParent => routerConfig != null;

  List<ParamConfig> get argParams {
    return parameters?.where((p) => !p.isPathParam && !p.isQueryParam)?.toList() ?? [];
  }

  Iterable<ParamConfig> get requiredParams => parameters?.where((p) => p.isPositional && !p.isOptional) ?? [];

  Iterable<ParamConfig> get positionalParams => parameters?.where((p) => p.isPositional) ?? [];

  Iterable<ParamConfig> get optionalParams => parameters?.where((p) => p.isOptional) ?? [];

  String get routeName => capitalize(valueOr(name, '${className}Route'));

  String get pageTypeName {
    switch (routeType) {
      case RouteType.cupertino:
        return 'XCupertinoPage';
      case RouteType.custom:
        return 'CustomPage';
      case RouteType.adaptive:
        return 'AdaptivePage';
      default:
        return 'XMaterialPage';
    }
  }
}

class RouteType {
  static const int material = 0;
  static const int cupertino = 1;
  static const int adaptive = 2;
  static const int custom = 3;
}
