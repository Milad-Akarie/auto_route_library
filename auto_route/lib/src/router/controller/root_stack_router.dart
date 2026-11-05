part of 'routing_controller.dart';

/// Signature for a function uses `pagesMap` to build an [AutoRoutePage]
typedef PageBuilder = AutoRoutePage<Object?> Function(RouteData<Object?> data);

const ValueKey<String> _kRootKey = ValueKey('%__Root__%');

/// An Implementation of [StackRouter] used by [AutoRouterDelegate]
abstract class RootStackRouter extends StackRouter {
  /// Default constructor
  new({super.navigatorKey}) : super(key: _kRootKey, matchId: _kRootKey) {
    _navigationHistory = NavigationHistory.create(this);
  }

  /// Builds a new instance of [RootStackRouter]
  /// with the provided parameters
  factory build({
    required List<AutoRoute> routes,
    List<AutoRouteGuard> guards,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteType defaultRouteType,
  }) = _RootStackRouterImpl;

  final _rootBackButtonDispatcher = RootBackButtonDispatcher();

  // Counts the links the delegate opened. A navigation a link starts keeps
  // the count it started with, and stops at its next guard once a later link
  // has started: a slow guard of the link the app started at must not open
  // its page over the pages of a link that came after it.
  int _linkCount = 0;

  // The count of the link whose navigation is starting, while it starts.
  int? _startingLink;

  // Runs [open], which starts the navigation of a new link, as that link's.
  // The navigation starts before [open] returns, up to its first guard.
  Future<void> _openLink(Future<void> Function() open) {
    _startingLink = ++_linkCount;
    final Future<void> navigation;
    try {
      navigation = open();
    } finally {
      _startingLink = null;
    }
    return navigation;
  }

  /// Returns a [RouterConfig] instead to be passed
  /// to [MaterialApp.router]
  RouterConfig<UrlState> config({
    DeepLinkTransformer? deepLinkTransformer,
    DeepLinkBuilder? deepLinkBuilder,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    bool includePrefixMatches = !kIsWeb,
    bool Function(String? location)? neglectWhen,
    bool rebuildStackOnDeepLink = false,
    Listenable? reevaluateListenable,
    Clip clipBehavior = .hardEdge,
  }) {
    return RouterConfig(
      routeInformationParser: defaultRouteParser(
        includePrefixMatches: includePrefixMatches,
        deepLinkTransformer: deepLinkTransformer,
      ),
      routeInformationProvider: routeInfoProvider(neglectWhen: neglectWhen),
      backButtonDispatcher: _rootBackButtonDispatcher,
      routerDelegate: delegate(
        reevaluateListenable: reevaluateListenable,
        rebuildStackOnDeepLink: rebuildStackOnDeepLink,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
        placeholder: placeholder,
        deepLinkBuilder: deepLinkBuilder,
        clipBehavior: clipBehavior,
      ),
    );
  }

  @override
  RouteData<Object?> get routeData => .new(
    router: this,
    type: const RouteType.material(),
    stackKey: _stackKey,
    route: RouteMatch(
      config: DummyRootRoute(path: ''),
      segments: const [''],
      stringMatch: '',
      key: const ValueKey('Root'),
    ),
    pendingChildren: const [],
  );

  /// The list of route entries to match against
  List<AutoRoute> get routes;

  /// A List of Root router guards
  List<AutoRouteGuard> get guards => const [];

  /// The default animation
  RouteType get defaultRouteType => const .material();

  late final NavigationHistory _navigationHistory;

  @override
  bool get managedByWidget => false;

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

  AutoRouterDelegate? _lazyRootDelegate;

  /// Builds a lazy instance of [AutoRouterDelegate]
  /// _lazyRootDelegate is only built one time
  AutoRouterDelegate delegate({
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    DeepLinkBuilder? deepLinkBuilder,
    bool rebuildStackOnDeepLink = false,
    Listenable? reevaluateListenable,
    Clip clipBehavior = .hardEdge,
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate(
      this,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
      placeholder: placeholder,
      rebuildStackOnDeepLink: rebuildStackOnDeepLink,
      deepLinkBuilder: deepLinkBuilder,
      reevaluateListenable: reevaluateListenable,
      clipBehavior: clipBehavior,
    );
  }

  /// Builds a lazy instance of [DefaultRouteParser]
  DefaultRouteParser defaultRouteParser({
    bool includePrefixMatches = !kIsWeb,
    DeepLinkTransformer? deepLinkTransformer,
  }) => .new(
    matcher,
    includePrefixMatches: includePrefixMatches,
    // A DeepLinkTransformer returns a Future, and a SynchronousFuture would change timing.
    // ignore: avoid-unnecessary-futures
    deepLinkTransformer: deepLinkTransformer ?? (uri) async => uri,
  );

  @override
  void updateRouteData(RouteData<Object?> data) {
    throw FlutterError('Root RouteData should not update');
  }

  // Reads routeCollection on every match, so the parsers made before a hot
  // reload match the reloaded routes.
  @override
  late final RouteMatcher matcher = _RootRouteMatcher(this);

  @override
  NavigationHistory get navigationHistory => _navigationHistory;

  /// Disposes this router with the navigation history, the url provider and
  /// the delegate it created, which also disposes the delegate's own
  /// listeners. Disposing that delegate disposes this router too.
  @override
  void dispose() {
    if (_disposed) return;
    super.dispose();
    _navigationHistory.dispose();
    _lazyInformationProvider?.dispose();
    _lazyRootDelegate?.dispose();
  }

  RouteCollection? _routeCollection;

  @override
  RouteCollection get routeCollection =>
      _routeCollection ??= .fromList(routes, root: true, onGeneratePath: onGeneratePath);

  // A hot reload may have changed what [routes] returns.
  @override
  void _reassemble() {
    _routeCollection = null;
    super._reassemble();
  }

  /// Generates a path for a route with the provided `name`
  ///
  /// routes with defined path will use the defined path
  /// and will not use this method
  ///
  /// routes marked with `initial` will use either '/' or an empty string
  /// for such routes
  ///
  /// use [isRoot] to determine if the route needs to start with '/'
  String onGeneratePath(AutoRoute route) {
    return RouteCollection.defaultPathGenerator(route);
  }
}

class _RootStackRouterImpl extends RootStackRouter {
  new({
    required this.routes,
    this.guards = const [],
    super.navigatorKey,
    this.defaultRouteType = const RouteType.material(),
    OnGeneratePath? onGeneratePath,
  }) : _onGeneratePath = onGeneratePath ?? RouteCollection.defaultPathGenerator;
  @override
  final List<AutoRoute> routes;

  @override
  final List<AutoRouteGuard> guards;

  @override
  final RouteType defaultRouteType;

  final OnGeneratePath _onGeneratePath;

  @override
  String onGeneratePath(AutoRoute route) {
    return _onGeneratePath(route);
  }
}

class _RootRouteMatcher extends RouteMatcher {
  new(this._router) : super(_router.routeCollection);

  final RootStackRouter _router;

  // The collection passed to super is the one of the moment; a hot reload
  // replaces it.
  @override
  // ignore: avoid-suspicious-super-overrides
  RouteCollection get collection => _router.routeCollection;
}
