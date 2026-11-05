part of 'routing_controller.dart';

/// Signature for a function that builds [DeepLink]
/// [deepLink] is the pre-resolved link coming from platform window
typedef DeepLinkBuilder = FutureOr<DeepLink> Function(PlatformDeepLink deepLink);

/// Signature for a function that transform the incoming [Uri]
/// [uri] is the pre-resolved uri coming from platform window
/// This is call before the [DeepLinkBuilder] to allow to transform the [Uri]
typedef DeepLinkTransformer = Future<Uri> Function(Uri uri);

/// An auto_route implementation for [RouterDelegate]
class AutoRouterDelegate extends RouterDelegate<UrlState> with ChangeNotifier {
  /// Default constructor
  AutoRouterDelegate(
    this.controller, {
    this.placeholder,
    this.navRestorationScopeId,
    this.navigatorObservers = defaultNavigatorObserversBuilder,
    this.deepLinkBuilder,
    this.rebuildStackOnDeepLink = false,
    this.reevaluateListenable,
    this.clipBehavior = Clip.hardEdge,
    this.routeTraversalEdgeBehavior,
  }) {
    _navigatorObservers = navigatorObservers();
    controller.navigationHistory.addListener(_handleRebuild);
    reevaluateListenable?.addListener(controller.reevaluateGuards);
    if (!kIsWeb) {
      // Pages can change without the url changing; the Router saves them
      // through currentConfiguration.
      controller.addListener(notifyListeners);
    } else {
      // A deep link's url is set before its page is in, while
      // currentConfiguration is still null; the Router hears of it here.
      controller.addListener(_reportFirstPage);
    }
  }

  /// An object that provides pages stack to [Navigator.pages]
  /// and wraps a navigator key to handle stack navigation actions
  final StackRouter controller;

  /// Clients can use this to intercept deep-links
  /// coming from platform and validate, abort or override it.
  final DeepLinkBuilder? deepLinkBuilder;

  /// Passed to [Navigator.restorationScopeId]
  final String? navRestorationScopeId;

  /// A builder function that returns a list of observes
  ///
  /// Why isn't this a list of navigatorObservers?
  /// The reason for that is a [NavigatorObserver] instance can only
  /// be used by a single [Navigator], so unless you're using a one
  /// single router or you don't want your nested routers to inherit
  /// observers make sure navigatorObservers builder always returns
  /// fresh observer instances.
  final NavigatorObserversBuilder navigatorObservers;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with `Theme.scaffoldBackgroundColor`.
  final WidgetBuilder? placeholder;

  /// if set to true the new stack
  /// will replace the old one on
  /// deep-links coming from the platform
  ///
  /// pops all previous routes
  /// and pushes the new ones
  ///
  /// this is used after a deep-link is
  /// resolved by [deepLinkBuilder] if provided
  ///
  /// defaults to false
  final bool rebuildStackOnDeepLink;

  /// A listenable that triggers a re-evaluation of the guards
  final Listenable? reevaluateListenable;

  /// The clip behavior of the navigator
  final Clip clipBehavior;

  /// The traversal edge behavior of the navigator
  final TraversalEdgeBehavior? routeTraversalEdgeBehavior;

  /// Builds an empty observers list
  static List<NavigatorObserver> defaultNavigatorObserversBuilder() => const [];

  /// Looks up and casts the scoped [Router] to [AutoRouterDelegate]
  static AutoRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is AutoRouterDelegate, 'The nearest Router does not use an AutoRouterDelegate.');
    return delegate as AutoRouterDelegate;
  }

  /// Forces a url update
  static void reportUrlChanged(BuildContext context, String url) {
    Router.of(context).routeInformationProvider
        ?.routerReportsNewRouteInformation(RouteInformation(uri: Uri.parse(url)), type: .navigate);
  }

  @override
  Future<bool> popRoute() async => controller.maybePopTop();

  late List<NavigatorObserver> _navigatorObservers;

  void _reportFirstPage() {
    if (!controller.hasEntries) return;
    controller.removeListener(_reportFirstPage);
    _handleRebuild();
  }

  /// Helper to access current urlState
  UrlState get urlState => controller.navigationHistory.urlState;

  /// The current [urlState]; off the web it also holds the pages of every
  /// router, and the route the platform started the app at, which the
  /// [Router] saves for state restoration.
  ///
  /// Null until the first navigation has put a page in the root router: the
  /// [Router] reports nothing for null, while the empty [urlState] would
  /// reach the browser as '/' before the deep link the app opens.
  @override
  UrlState? get currentConfiguration {
    // Only before the first page: later the stack can be empty for a moment,
    // as in pushAndPopUntil, and the url must still be reported.
    _hadPage = _hadPage || controller.hasEntries;
    if (!_hadPage) return null;
    if (kIsWeb) return urlState;
    return urlState.copyWith(savedRoutes: {_routesKey: controller._savedRoutes(), _launchLinkKey: _launchLink});
  }

  // The keys of what currentConfiguration saves for state restoration.
  static const _routesKey = 'routes';
  static const _launchLinkKey = 'launchLink';

  // The route the platform started this process at: a link, or '/'.
  static String get _launchLink => WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  var _hadPage = false;

  @override
  Future<void> setInitialRoutePath(UrlState configuration) async {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.hasEntries) {
      return SynchronousFuture(null);
    }
    final platformDeepLink = PlatformDeepLink._(configuration, true);
    if (deepLinkBuilder != null) {
      return _handleDeepLink(await deepLinkBuilder!(platformDeepLink));
    } else if (platformDeepLink.isValid) {
      return _handleDeepLink(platformDeepLink);
    }
    throw FlutterError(_unresolvedMessage(platformDeepLink));
  }

  Future<void> _handleDeepLink(DeepLink deepLink) {
    if (deepLink is _IgnoredDeepLink) return SynchronousFuture(null);

    throwIf(!deepLink.isValid, _unresolvedMessage(deepLink));
    return controller.root._openLink(() => _openDeepLink(deepLink));
  }

  Future<void> _openDeepLink(DeepLink deepLink) {
    if (deepLink is PlatformDeepLink) {
      _onNewUrlState(deepLink.configuration);
      return controller.navigateAll(deepLink.matches);
    } else if (deepLink is _PathDeepLink) {
      if (deepLink.navigate) {
        return controller.navigatePath(deepLink.path, includePrefixMatches: deepLink.includePrefixMatches);
      }
      return controller.pushPath(deepLink.path, includePrefixMatches: deepLink.includePrefixMatches);
    } else if (deepLink is _RoutesDeepLink) {
      if (deepLink.navigate) {
        return controller._navigateAllRoutes(deepLink.routes);
      }
      return controller.pushAll(deepLink.routes);
    }
    throw FlutterError('Unsupported DeepLink ${deepLink.runtimeType}');
  }

  /// Rebuilds the pages of every router from [UrlState.savedRoutes] when the
  /// app is restored, guards included; without them, opens the restored url.
  ///
  /// A page that can't be built without the args it was opened with is left
  /// out, since args aren't saved.
  ///
  /// A link the platform started the restored app with then opens over the
  /// restored pages, as it does in the running app. A link that also started
  /// the app that was saved is not opened again: Android restarts an app from
  /// its recent apps with the link that first opened it.
  @override
  Future<void> setRestoredRoutePath(UrlState configuration) {
    final saved = configuration.savedRoutes;
    if (_launchLink != Navigator.defaultRouteName && (saved is! Map || saved[_launchLinkKey] != _launchLink)) {
      _openLaunchLinkAfterRestore();
    }
    // Saved before the launch link was, the routes alone.
    final routes = _restoredRoutes(saved is Map ? saved[_routesKey] : saved);
    final matches = routes == null || routes.isEmpty || controller.hasEntries
        ? null
        : controller._matchAllOrReportFailure(routes, (_) {});
    final buildable = matches == null ? const <RouteMatch<dynamic>>[] : _buildableMatches(matches, controller);
    if (buildable.isEmpty) {
      return setNewRoutePath(configuration);
    }
    return controller.navigateAll(buildable);
  }

  // Hands the launch link to the Router's route information provider once the
  // restored pages are built, the way the platform hands a link to the
  // running app, so the parser and deepLinkBuilder see it too.
  void _openLaunchLinkAfterRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = controller.navigatorKey.currentContext;
      // Typed as Object so the check below makes it an observer.
      final Object? provider = context == null ? null : Router.maybeOf(context)?.routeInformationProvider;
      if (provider is WidgetsBindingObserver) {
        unawaited(provider.didPushRouteInformation(RouteInformation(uri: Uri.parse(_launchLink))));
      }
    }, debugLabel: 'AutoRouterDelegate.openLaunchLinkAfterRestore');
  }

  // Names the link no route matched, which on a phone can come from another
  // app, so the error says what to look for.
  String _unresolvedMessage(DeepLink deepLink) {
    if (deepLink is! PlatformDeepLink) return 'Can not resolve initial route';
    return 'Can not resolve initial route: no route matches "${deepLink.uri}". '
        "Add RedirectRoute(path: '*', redirectTo: '/') last in your routes to open "
        'links no route matches on your initial page. The routes of the app, by full path:\n'
        '${controller.routeCollection.toTreeString()}';
  }

  @override
  Future<void> setNewRoutePath(UrlState configuration) async {
    final history = controller.navigationHistory;
    if (history.consumeOwnBrowserMove(configuration)) {
      return SynchronousFuture(null);
    }
    if (history.isBrowserBehindApp && await _topRouteRefusesPop()) {
      history.returnBrowserToApp();
      return;
    }
    final topMost = controller.topMostRouter();
    if (topMost is StackRouter && topMost.hasPagelessTopRoute) {
      topMost.popUntil((route) => route.settings is Page);
    }

    final pageToPush = history.pageToPushForBrowserEntry(configuration);
    if (pageToPush != null) {
      final (stack, page) = pageToPush;
      // The future completes when the page is popped.
      unawaited(stack._pushAllGuarded([page]));
    } else if (configuration.hasSegments) {
      final entryRoutes = controller.navigationHistory.routesOfBrowserEntry(configuration);
      if (entryRoutes != null && entryRoutes.isEmpty) {
        notifyListeners();
        return SynchronousFuture(null);
      }
      final platLink = PlatformDeepLink._(
        entryRoutes == null ? configuration : configuration.copyWith(segments: entryRoutes),
        false,
      );
      final resolvedLink = deepLinkBuilder == null ? platLink : await deepLinkBuilder!(platLink);
      if (rebuildStackOnDeepLink) {
        controller.popUntil((route) => false);
      }
      await _handleDeepLink(resolvedLink);
    }

    notifyListeners();
    return SynchronousFuture(null);
  }

  // Whether the route on top of the top-most navigator refuses to be popped,
  // through a PopScope or a WillPopScope; asks it the way Navigator.maybePop
  // does, so it hears of the attempt.
  Future<bool> _topRouteRefusesPop() async {
    final topMost = controller.topMostRouter();
    if (topMost is! StackRouter) return false;
    Route<Object?>? topRoute;
    // The predicate stops at the first route it's given, the top one, so nothing is popped.
    topMost.navigatorKey.currentState?.popUntil((route) {
      topRoute = route;
      return true;
    });
    final route = topRoute;
    if (route == null) return false;
    // WillPopScope answers only through the deprecated willPop.
    // ignore: deprecated_member_use
    if (await route.willPop() == .doNotPop) return true;
    if (route.popDisposition == .doNotPop) {
      route.onPopInvokedWithResult(false, null);
      return true;
    }
    return false;
  }

  void _onNewUrlState(UrlState state) {
    final pathInBrowser = state.uri.path;
    var matchedUrlState = state.flatten;
    final matchedPath = Uri.encodeFull(matchedUrlState.path);
    if (pathInBrowser != matchedPath) {
      matchedUrlState = matchedUrlState.copyWith(shouldReplace: true);
    }
    controller.navigationHistory.onNewUrlState(matchedUrlState);
  }

  @override
  Widget build(BuildContext context) => _AutoRootRouter(
    router: controller,
    navigatorObservers: _navigatorObservers,
    navigatorObserversBuilder: navigatorObservers,
    navRestorationScopeId: navRestorationScopeId,
    placeholder: placeholder,
    clipBehavior: clipBehavior,
    routeTraversalEdgeBehavior: routeTraversalEdgeBehavior,
  );

  void _handleRebuild() {
    final context = controller.navigatorKey.currentContext;
    if (urlState.shouldReplace && context != null) {
      // Flutter's default route information provider ignores
      // AutoRouteInformation.replace; it replaces the browser entry only when
      // the router reports the change as neglected.
      Router.neglect(context, notifyListeners);
    } else if (controller.navigationHistory.addsEntryWithSameUrl && context != null) {
      // The router reports a url equal to the browser's as a replace of its
      // entry unless told the change is a navigation.
      Router.navigate(context, notifyListeners);
    } else {
      notifyListeners();
    }
  }

  // Disposing the root router disposes this delegate, and this delegate
  // disposes the root router; the second call returns at once.
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
    controller.navigationHistory.removeListener(_handleRebuild);
    reevaluateListenable?.removeListener(controller.reevaluateGuards);
    controller.removeListener(notifyListeners);
    controller.removeListener(_reportFirstPage);
    controller.dispose();
  }

  /// Force this delegate to rebuild
  void notifyUrlChanged() => _handleRebuild();

  // Reports the current url over the browser entry the Router wrote last,
  // without rebuilding the pages, as a notification would.
  void _reportUrlInPlace() {
    final context = controller.navigatorKey.currentContext;
    final router = context == null ? null : Router.maybeOf(context);
    final routeInformation = router?.routeInformationParser?.restoreRouteInformation(currentConfiguration);
    if (routeInformation == null) return;
    router!.routeInformationProvider?.routerReportsNewRouteInformation(routeInformation, type: .neglect);
  }
}

class _AutoRootRouter extends StatefulWidget {
  const _AutoRootRouter({
    required this.router,
    this.navRestorationScopeId,
    this.navigatorObservers = const [],
    required this.navigatorObserversBuilder,
    this.placeholder,
    this.clipBehavior = Clip.hardEdge,
    this.routeTraversalEdgeBehavior,
  });

  final Clip clipBehavior;
  final StackRouter router;
  final String? navRestorationScopeId;
  final List<NavigatorObserver> navigatorObservers;
  final NavigatorObserversBuilder navigatorObserversBuilder;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with `Theme.scaffoldBackgroundColor`.
  final WidgetBuilder? placeholder;

  final TraversalEdgeBehavior? routeTraversalEdgeBehavior;

  @override
  _AutoRootRouterState createState() => .new();
}

class _AutoRootRouterState extends State<_AutoRootRouter> {
  StackRouter get router => widget.router;

  @override
  void initState() {
    super.initState();
    router.addListener(_handleRebuild);
  }

  @override
  void dispose() {
    router.removeListener(_handleRebuild);
    super.dispose();
  }

  // A hot reload may have changed the routes the router was built from.
  @override
  void reassemble() {
    super.reassemble();
    router._reassemble();
  }

  void _handleRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  // Flutter tells Android whether the app takes back from the root
  // navigator's stack alone; while it says no, Android closes the app
  // itself. A tabs router away from its home tab, or with tabs in its
  // history, takes back too: it shows another tab (TabsRouter.maybePop). So this corrects the value, and sends
  // it again after a tab switch, which the navigator never reports.
  bool? _reportedCanHandlePop;
  bool _tabsTookBack = false;
  bool _reportScheduled = false;

  bool _tabsTakeBack() {
    for (RoutingController? r = router.topMostRouter(); r != null; r = r.parent()) {
      if (r is TabsRouter && r._takesBack) return true;
    }
    return false;
  }

  bool _handleNavigationNotification(NavigationNotification notification) {
    _tabsTookBack = _tabsTakeBack();
    if (notification.canHandlePop || !_tabsTookBack) {
      _reportedCanHandlePop = notification.canHandlePop;
      return false;
    }
    _report(true);
    return true;
  }

  void _report(bool canHandlePop) {
    _reportedCanHandlePop = canHandlePop;
    NavigationNotification(canHandlePop: canHandlePop).dispatch(context);
  }

  void _scheduleTabsReport() {
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      if (!mounted) return;
      final tabsTakeBack = _tabsTakeBack();
      if (tabsTakeBack == _tabsTookBack) return;
      _tabsTookBack = tabsTakeBack;
      final canHandlePop = tabsTakeBack || _rootNavigatorTakesBack();
      if (canHandlePop != _reportedCanHandlePop) _report(canHandlePop);
    }, debugLabel: 'AutoRootRouter.reportTabsBack');
  }

  // What the root navigator reports: whether it can pop, or its top route
  // refuses the pop.
  bool _rootNavigatorTakesBack() {
    final navigator = router.navigatorKey.currentState;
    if (navigator == null) return false;
    if (navigator.canPop()) return true;
    Route<Object?>? topRoute;
    // The predicate stops at the first route it's given, the top one, so nothing is popped.
    navigator.popUntil((route) {
      topRoute = route;
      return true;
    });
    return topRoute?.popDisposition == .doNotPop;
  }

  @override
  Widget build(BuildContext context) {
    _scheduleTabsReport();
    return NotificationListener<NavigationNotification>(
      onNotification: _handleNavigationNotification,
      // A widget class would add an element and move the state below it.
      // ignore: avoid-returning-widgets
      child: _buildRouterScope(),
    );
  }

  Widget _buildRouterScope() {
    final stateHash = router.stateHash;
    return RouterScope(
      key: router.globalRouterKey,
      controller: router,
      navigatorObservers: widget.navigatorObservers,
      inheritableObserversBuilder: widget.navigatorObserversBuilder,
      stateHash: stateHash,
      child: StackRouterScope(
        stateHash: stateHash,
        controller: router,
        child: AutoRouteNavigator(
          router: router,
          clipBehavior: widget.clipBehavior,
          key: GlobalObjectKey(widget.router.hashCode),
          placeholder: widget.placeholder,
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: widget.navigatorObservers,
          routeTraversalEdgeBehavior: widget.routeTraversalEdgeBehavior,
        ),
      ),
    );
  }
}

/// Holds deep-link information
abstract class DeepLink {
  /// Builds a deep-link from a list of `PageRouteInfo`s
  const factory DeepLink(List<PageRouteInfo> routes, {bool navigate}) = _RoutesDeepLink;

  /// Builds a deep-link from a single `PageRouteInfo`
  factory DeepLink.single(PageRouteInfo route, {bool navigate = true}) {
    return _RoutesDeepLink([route], navigate: navigate);
  }

  /// Builds a deep-link form string path
  const factory DeepLink.path(String path, {bool includePrefixMatches, bool navigate}) = _PathDeepLink;
  const DeepLink._();

  /// Whether this link is navigable
  ///
  /// e.g PathDeepLink.path.isNotEmpty;
  bool get isValid;

  /// Builds a deep link with initial path
  static const DeepLink defaultPath = DeepLink.path(Navigator.defaultRouteName);

  /// Builds an ignored deep link instance
  static const DeepLink none = _IgnoredDeepLink();

  /// Helper function to remove the prefix path of a [Uri]
  /// You can use this method to remove the prefix of a path
  /// the prefix should start with a `/`
  ///
  /// If not able to parse the resulting Uri, return the original
  static DeepLinkTransformer prefixStripper(String prefix) {
    return (Uri uri) {
      if (!uri.path.startsWith(prefix)) {
        return SynchronousFuture(uri); // No change if prefix not found
      }
      return SynchronousFuture(Uri.tryParse(uri.toString().replaceFirst(prefix, '')) ?? uri);
    };
  }
}

class _PathDeepLink extends DeepLink {
  const _PathDeepLink(this.path, {this.includePrefixMatches = true, this.navigate = true}) : super._();
  final String path;
  final bool includePrefixMatches;

  /// if false the path will be pushed instead of navigated
  final bool navigate;

  @override
  bool get isValid => path.isNotEmpty;
}

class _RoutesDeepLink extends DeepLink {
  const _RoutesDeepLink(this.routes, {this.navigate = true}) : super._();
  final List<PageRouteInfo> routes;

  /// if false the routes will be pushed instead of navigated
  final bool navigate;

  @override
  bool get isValid => routes.isNotEmpty;
}

class _IgnoredDeepLink extends DeepLink {
  const _IgnoredDeepLink() : super._();

  @override
  bool get isValid => false;
}

/// Holds information of the deep-link
/// coming from the platform window
class PlatformDeepLink extends DeepLink {
  const PlatformDeepLink._(this.configuration, this.initial) : super._();

  /// The initial url state parsed from initial raw path
  final UrlState configuration;

  /// The raw deep-link as String
  String get path => configuration.path;

  /// The parsed uri from the raw path
  Uri get uri => configuration.uri;

  /// Whether this is the initial deep-link
  final bool initial;

  /// The pre-matched routes from the row path
  List<RouteMatch<dynamic>> get matches => configuration.segments;

  @override
  bool get isValid => configuration.hasSegments;
}
