import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../matcher/route_matcher.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class AutoRouterConfig {
  StackRouter root;
  RootRouterDelegate rootDelegate;

  @mustCallSuper
  AutoRouterConfig(
      {List<PageRouteInfo> initialRoutes, String initialDeepLink}) {
    assert(routes != null);
    assert(_pageBuilder != null);
    rootDelegate = RootRouterDelegate(
        root = TreeEntry(
          routeCollection: RouteCollection.from(routes),
          pageBuilder: _pageBuilder,
        ),
        initialDeepLink: initialDeepLink,
        initialRoutes: initialRoutes);
  }

  Map<Type, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = true}) =>
      DefaultRouteParser(root.matcher,
          includePrefixMatches: includePrefixMatches);

  AutoRoutePage _pageBuilder(RouteData data) {
    var builder = pagesMap[data.config.page];
    assert(builder != null);
    return builder(data);
  }
}
