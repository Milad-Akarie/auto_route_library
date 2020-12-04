import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../matcher/route_matcher.dart';
import '../route/page_route_info.dart';
import '../route/route_data.dart';
import '../route/route_def.dart';
import 'controller/routing_controller.dart';
import 'extended_page.dart';

typedef PageBuilder = ExtendedPage Function(RouteData data, RouteDef def);
typedef RouteDataPredicate = bool Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData config);

abstract class AutoRouterConfig {
  RoutesCollection routeCollection;
  RoutingController root;

  @mustCallSuper
  AutoRouterConfig({
    String initialDeepLink,
    List<PageRouteInfo> initialRoutes,
  }) : assert(initialDeepLink == null || initialRoutes == null) {
    assert(routes != null);
    routeCollection = RoutesCollection.from(routes);
    root = RouterNode(
      key: 'root',
      routeCollection: routeCollection,
      pageBuilder: _pageBuilder,
    );
  }

  Map<Type, PageFactory> get pagesMap;

  List<RouteDef> get routes;

  NativeRouteInfoParser get nativeRouteParser => NativeRouteInfoParser(routeCollection);

  WebRouteInfoParser get webRouteParser => WebRouteInfoParser(routeCollection);

  RouteInformationProvider defaultProvider(String initialPath) {
    return PlatformRouteInformationProvider(
      initialRouteInformation:
          RouteInformation(location: initialPath ?? '/' // WidgetsBinding.instance.window.defaultRouteName,
              ),
    );
  }

  ExtendedPage _pageBuilder(RouteData data, RouteDef def) {
    var builder = pagesMap[def.page];
    assert(builder != null);
    return builder(data);
  }
}
