import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../matcher/route_matcher.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(StackEntryItem entry);
typedef PageFactory = Page<dynamic> Function(StackEntryItem entry);

abstract class RootStackRouter implements BranchEntry {
  RootStackRouter() : super();

  @override
  RouteCollection get routeCollection => RouteCollection.from(routes);

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  late RootRouterDelegate _lazyRootDelegate;

  // _lazyRootDelegate is only built one time
  RootRouterDelegate delegate({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    Color? backgroundColor,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return _lazyRootDelegate = RootRouterDelegate(
      this,
      initialDeepLink: initialDeepLink,
      initialRoutes: initialRoutes,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
      navigatorKey: navigatorKey,
      backgroundColor: backgroundColor,
    );
  }

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = false}) =>
      DefaultRouteParser(matcher, includePrefixMatches: includePrefixMatches);

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  AutoRoutePage _pageBuilder(StackEntryItem entry) {
    var builder = pagesMap[entry.routeData?.name];
    assert(builder != null);
    return builder!(entry) as AutoRoutePage;
  }
}
