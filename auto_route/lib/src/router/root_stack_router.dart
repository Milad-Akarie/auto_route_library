import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class RootStackRouter extends StackRouter {
  RootStackRouter()
      : super(
          key: const ValueKey('Root'),
          routeData: RouteData(
              route: const PageRouteInfo('Root', path: ''),
              config: RouteConfig('Root', path: ''),
              key: const ValueKey('Root')),
        );

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  @override
  final CurrentConfigNotifier configNotifier = CurrentConfigNotifier();

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  AutoRouterDelegate? _lazyRootDelegate;

  // _lazyRootDelegate is only built one time
  AutoRouterDelegate delegate({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    GlobalKey<NavigatorState>? navigatorKey,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate(
      this,
      initialDeepLink: initialDeepLink,
      initialRoutes: initialRoutes,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
      navigatorKey: navigatorKey,
      placeholder: placeholder,
    );
  }

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = false}) =>
      DefaultRouteParser(matcher, includePrefixMatches: includePrefixMatches);

  AutoRoutePage _pageBuilder(RouteData data) {
    var builder = pagesMap[data.name];
    assert(builder != null);
    return builder!(data) as AutoRoutePage;
  }

  @override
  RouteMatcher get matcher => RouteMatcher(routeCollection);

  @override
  RouteCollection get routeCollection => RouteCollection.from(routes);
}
