part of 'routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class RootStackRouter extends StackRouter {
  RootStackRouter([GlobalKey<NavigatorState>? navigatorKey])
      : super(
          key: const ValueKey('Root'),
          navigatorKey: navigatorKey,
        ) {
    _navigationHistory = NavigationHistory.create(this);
  }

  @override
  RouteData get routeData => RouteData(
        router: this,
        route: const RouteMatch(
          name: 'Root',
          segments: [''],
          path: '',
          stringMatch: '',
          isBranch: true,
          key: ValueKey('Root'),
        ),
        pendingChildren: [],
      );

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  // ignore: prefer_final_fields
  bool _managedByWidget = false;
  late final NavigationHistory _navigationHistory;

  @override
  bool get managedByWidget => _managedByWidget;

  AutoRouteInformationProvider? _lazyInformationProvider;

  AutoRouteInformationProvider routeInfoProvider({
    RouteInformation? initialRouteInformation,
    bool Function(String? location)? neglectWhen,
  }) {
    return _lazyInformationProvider ??= AutoRouteInformationProvider(
      initialRouteInformation: initialRouteInformation,
      neglectWhen: neglectWhen,
    );
  }

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  AutoRouterDelegate? _lazyRootDelegate;

  AutoRouterDelegate declarativeDelegate({
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    RoutePopCallBack? onPopRoute,
    String? initialDeepLink,
    OnNavigateCallBack? onNavigate,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate.declarative(
      this,
      routes: routes,
      onNavigate: onNavigate,
      initialDeepLink: initialDeepLink,
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
  void updateRouteData(RouteData data) {
    throw FlutterError('Root RouteData should not update');
  }

  @override
  late final RouteMatcher matcher = RouteMatcher(routeCollection);

  @override
  NavigationHistory get navigationHistory => _navigationHistory;

  @override
  late final RouteCollection routeCollection = RouteCollection.from(routes);
}
