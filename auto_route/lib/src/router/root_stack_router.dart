import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../matcher/route_matcher.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class RootStackRouter extends TreeEntry {
  // this is root
  @deprecated
  StackRouter get root => this;

  @override
  RouteCollection get routeCollection => RouteCollection.from(routes);

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  @deprecated
  final List<PageRouteInfo> initialRoutes;
  @deprecated
  final String initialDeepLink;

  RootRouterDelegate _lazyRootDelegate;

  RootStackRouter(
      {@deprecated this.initialRoutes, @deprecated this.initialDeepLink});

  @Deprecated("use delegate() builder instead")
  RootRouterDelegate get rootDelegate => delegate(
        initialRoutes: initialRoutes,
        initialDeepLink: initialDeepLink,
      );

  // _lazyRootDelegate is only built one time
  RootRouterDelegate delegate({
    List<PageRouteInfo> initialRoutes,
    String initialDeepLink,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return _lazyRootDelegate ??= RootRouterDelegate(
      this,
      initialDeepLink: initialDeepLink,
      initialRoutes: initialRoutes,
      navigatorObservers: navigatorObservers,
    );
  }

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = true}) =>
      DefaultRouteParser(matcher, includePrefixMatches: includePrefixMatches);

  Map<Type, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  AutoRoutePage _pageBuilder(RouteData data) {
    var builder = pagesMap[data.config.page];
    assert(builder != null);
    return builder(data);
  }
}
