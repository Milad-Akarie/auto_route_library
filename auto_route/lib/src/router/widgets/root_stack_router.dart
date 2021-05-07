part of 'auto_router_delegate.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class RootStackRouter extends StackRouter {
  RootStackRouter([GlobalKey<NavigatorState>? navigatorKey])
      : super(
          key: const ValueKey('Root'),
          navigatorKey: navigatorKey,
        );

  @override
  RouteData get routeData => RouteData(
        router: this,
        route: const RouteMatch(
          routeName: 'Root',
          segments: const [''],
          path: '',
          stringMatch: '',
          key: const ValueKey('Root'),
        ),
      );

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  bool _managedByWidget = false;

  @override
  bool get managedByWidget => _managedByWidget;

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  AutoRouterDelegate? _lazyRootDelegate;

  // _lazyRootDelegate is only built one time
  AutoRouterDelegate delegate({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate(
      this,
      initialDeepLink: initialDeepLink,
      initialRoutes: initialRoutes,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
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
