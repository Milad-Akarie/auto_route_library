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
          name: 'Root',
          segments: const [''],
          path: '',
          stringMatch: '',
          isBranch: true,
          key: const ValueKey('Root'),
        ),
        pendingChildren: [],
      );

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  bool _managedByWidget = false;

  @override
  bool get managedByWidget => _managedByWidget;

  AutoRouteInformationProvider? _lazyInformationProvider;

  AutoRouteInformationProvider routeInfoProvider(
      {RouteInformation? initialRouteInformation}) {
    return _lazyInformationProvider ??= AutoRouteInformationProvider(
      initialRouteInformation: initialRouteInformation,
    );
  }

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  AutoRouterDelegate? _lazyRootDelegate;

  AutoRouterDelegate declarativeDelegate({
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    RoutePopCallBack? onPopRoute,
    OnNavigateCallBack? onNavigate,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate.declarative(
      this,
      routes: routes,
      onNavigate: onNavigate,
      onPopRoute: onPopRoute,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
    );
  }

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
  late final RouteMatcher matcher = RouteMatcher(routeCollection);

  @override
  late final RouteCollection routeCollection = RouteCollection.from(routes);
}
