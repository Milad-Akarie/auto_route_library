part of 'routing_controller.dart';

/// Signature for a function uses [pagesMap] to build an [AutoRoutePage]
typedef PageBuilder = AutoRoutePage Function(RouteData data);

/// Signature for a function that builds an [AutoRoutePage]
/// Used by [RoutingController]
typedef PageFactory = Page<dynamic> Function(RouteData data);

/// An Implementation of [StackRouter] used by [AutoRouterDelegate]
abstract class RootStackRouter extends StackRouter {
  /// Default constructor
  RootStackRouter({GlobalKey<NavigatorState>? navigatorKey})
      : super(
          key: const ValueKey('Root'),
          navigatorKey: navigatorKey,
        ) {
    _navigationHistory = NavigationHistory.create(this);
  }

  /// Returns a [RouterConfig] instead to be passed
  /// to [MaterialApp.router]
  RouterConfig<UrlState> config({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    bool includePrefixMatches = false,
    bool Function(String? location)? neglectWhen,
  }) {
    return RouterConfig(
      routeInformationParser: defaultRouteParser(
        includePrefixMatches: includePrefixMatches,
      ),
      routeInformationProvider: routeInfoProvider(
        neglectWhen: neglectWhen,
      ),
      backButtonDispatcher: RootBackButtonDispatcher(),
      routerDelegate: delegate(
        initialDeepLink: initialDeepLink,
        initialRoutes: initialRoutes,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
        placeholder: placeholder,
      ),
    );
  }

  @override
  RouteData get routeData => RouteData(
        router: this,
        type: const RouteType.material(),
        route: RouteMatch(
          config: DummyRootRoute('Root', path: ''),
          segments: const [''],
          stringMatch: '',
          key: const ValueKey('Root'),
        ),
        pendingChildren: const [],
      );

  /// The map holding the page names and their factories
  Map<String, PageFactory> get pagesMap => throw UnimplementedError();

  /// The list of route entries to match against
  List<AutoRoute> get routes;

  /// The default animation
  RouteType get defaultRouteType => const RouteType.material();

  // ignore: prefer_final_fields
  bool _managedByWidget = false;
  late final NavigationHistory _navigationHistory;

  @override
  bool get managedByWidget => _managedByWidget;

  AutoRouteInformationProvider? _lazyInformationProvider;

  /// Builds a lazy instance of [AutoRouteInformationProvider]
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

  /// Builds a lazy instance of [AutoRouterDelegate.declarative]
  AutoRouterDelegate declarativeDelegate({
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    RoutePopCallBack? onPopRoute,
    String? initialDeepLink,
    OnNavigateCallBack? onNavigate,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
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

  /// Builds a lazy instance of [AutoRouterDelegate]
  /// _lazyRootDelegate is only built one time
  AutoRouterDelegate delegate({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
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

  /// Builds a lazy instance of [DefaultRouteParser]
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
  late final RouteCollection routeCollection = RouteCollection.fromList(routes, root: true);
}
