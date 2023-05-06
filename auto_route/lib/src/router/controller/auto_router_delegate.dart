part of 'routing_controller.dart';

/// Signature for a function that builds [DeepLink]
/// [deepLink] is the pre-resolved link coming from platform window
typedef DeepLinkBuilder = FutureOr<DeepLink> Function(PlatformDeepLink deepLink);

/// An auto_route implementation for [RouterDelegate]
class AutoRouterDelegate extends RouterDelegate<UrlState> with ChangeNotifier {
  /// This initial list of routes
  /// overrides default-initial paths e.g => AutoRoute(path:'/')
  /// overrides initial paths coming from platform e.g browser's address bar
  ///
  /// Using this is not recommended if your App uses deep-links
  /// unless you know what you're doing.
  @Deprecated('Use deepLinkBuilder:(_)=> DeepLink(routes) instead')
  final List<PageRouteInfo>? initialRoutes;

  /// This initial path
  /// overrides default-initial paths e.g => AutoRoute(path:'/')
  /// overrides initial paths coming from platform e.g browser's address bar
  ///
  /// (NOTE): Flutter reports platform deep-links directly now
  ///
  /// Using this is not recommended if your App uses deep-links
  /// unless you know what you're doing.
  @Deprecated('Use deepLinkBuilder:(_)=> DeepLink.path(path) instead')
  final String? initialDeepLink;

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
  /// an empty page with [Theme.scaffoldBackgroundColor].
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

  /// Builds an empty observers list
  static List<NavigatorObserver> defaultNavigatorObserversBuilder() => const [];

  /// Looks up and casts the scoped [Router] to [AutoRouterDelegate]
  static AutoRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is AutoRouterDelegate);
    return delegate as AutoRouterDelegate;
  }

  /// Forces a url update
  static reportUrlChanged(BuildContext context, String url) {
    Router.of(context).routeInformationProvider?.routerReportsNewRouteInformation(
          RouteInformation(location: url),
          type: RouteInformationReportingType.navigate,
        );
  }

  @override
  Future<bool> popRoute() async => controller.popTop();

  late List<NavigatorObserver> _navigatorObservers;

  /// Default constructor
  AutoRouterDelegate(
    this.controller, {
    this.initialRoutes,
    this.placeholder,
    this.navRestorationScopeId,
    this.initialDeepLink,
    this.navigatorObservers = defaultNavigatorObserversBuilder,
    this.deepLinkBuilder,
    this.rebuildStackOnDeepLink = false,
  })  : assert(initialDeepLink == null || initialRoutes == null),
        assert((deepLinkBuilder == null || (initialDeepLink == null && initialRoutes == null)),
            'You can not use initialDeepLink or initialRoutes with deepLinkBuilder') {
    _navigatorObservers = navigatorObservers();
    controller.navigationHistory.addListener(_handleRebuild);
  }

  /// Builds a [_DeclarativeAutoRouterDelegate] which uses
  /// a declarative list of routes to update navigator stack
  factory AutoRouterDelegate.declarative(
    RootStackRouter controller, {
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    String? initialDeepLink,
    RoutePopCallBack? onPopRoute,
    OnNavigateCallBack? onNavigate,
    NavigatorObserversBuilder navigatorObservers,
    DeepLinkBuilder? deepLinkBuilder,
  }) = _DeclarativeAutoRouterDelegate;

  /// Helper to access current urlState
  UrlState get urlState => controller.navigationHistory.urlState;

  @override
  UrlState? get currentConfiguration => urlState;

  @override
  Future<void> setInitialRoutePath(UrlState configuration) async {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.hasEntries) {
      return SynchronousFuture(null);
    }

    /// Todo remove below deprecated code
    final platformDeepLink = PlatformDeepLink._(configuration);
    if (deepLinkBuilder != null) {
      return _handleDeepLink(await deepLinkBuilder!(platformDeepLink));
      // ignore: deprecated_member_use_from_same_package
    } else if (initialRoutes?.isNotEmpty == true) {
      // ignore: deprecated_member_use_from_same_package
      return _handleDeepLink(DeepLink(initialRoutes!));
      // ignore: deprecated_member_use_from_same_package
    } else if (initialDeepLink != null) {
      // ignore: deprecated_member_use_from_same_package
      return _handleDeepLink(DeepLink.path(initialDeepLink!, includePrefixMatches: true));
    } else if (configuration.hasSegments) {
      return _handleDeepLink(platformDeepLink);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  Future<void> _handleDeepLink(DeepLink deepLink) {
    throwIf(!deepLink.isValid, 'Can not resolve initial route');
    if (deepLink is PlatformDeepLink) {
      _onNewUrlState(deepLink.configuration);
      return controller.navigateAll(deepLink.matches);
    } else if (deepLink is _PathDeepLink) {
      return controller.pushNamed(
        deepLink.path,
        includePrefixMatches: deepLink.includePrefixMatches,
      );
    } else if (deepLink is _RoutesDeepLink) {
      return controller.pushAll(deepLink.routes);
    } else {
      throw FlutterError('Unsupported DeepLink ${deepLink.runtimeType}');
    }
  }

  @override
  Future<void> setNewRoutePath(UrlState configuration) async {
    final topMost = controller.topMostRouter();
    if (topMost is StackRouter && topMost.hasPagelessTopRoute) {
      topMost.popUntil((route) => route.settings is Page);
    }

    if (configuration.hasSegments) {
      final platLink = PlatformDeepLink._(configuration);
      final resolvedLink = deepLinkBuilder == null ? platLink : await deepLinkBuilder!(platLink);
      if (rebuildStackOnDeepLink) {
        controller.popUntil((route) => false);
      }
      await _handleDeepLink(resolvedLink);
    }

    notifyListeners();
    return SynchronousFuture(null);
  }

  void _onNewUrlState(UrlState state) {
    final pathInBrowser = state.uri.path;
    var matchedUrlState = state.flatten;
    if (pathInBrowser != matchedUrlState.path) {
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
      );

  void _handleRebuild() {
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    removeListener(_handleRebuild);
    controller.dispose();
  }

  /// Force this delegate to rebuild
  void notifyUrlChanged() => _handleRebuild();
}

class _AutoRootRouter extends StatefulWidget {
  const _AutoRootRouter({
    Key? key,
    required this.router,
    this.navRestorationScopeId,
    this.navigatorObservers = const [],
    required this.navigatorObserversBuilder,
    this.placeholder,
  }) : super(key: key);
  final StackRouter router;
  final String? navRestorationScopeId;
  final List<NavigatorObserver> navigatorObservers;
  final NavigatorObserversBuilder navigatorObserversBuilder;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with [Theme.scaffoldBackgroundColor].
  final WidgetBuilder? placeholder;

  @override
  _AutoRootRouterState createState() => _AutoRootRouterState();
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
    super.dispose();
    router.removeListener(_handleRebuild);
  }

  void _handleRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateHash = router.stateHash;
    return RouterScope(
      controller: router,
      navigatorObservers: widget.navigatorObservers,
      inheritableObserversBuilder: widget.navigatorObserversBuilder,
      stateHash: stateHash,
      child: StackRouterScope(
        stateHash: stateHash,
        controller: router,
        child: AutoRouteNavigator(
          router: router,
          placeholder: widget.placeholder,
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: widget.navigatorObservers,
        ),
      ),
    );
  }
}

class _DeclarativeAutoRouterDelegate extends AutoRouterDelegate {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final OnNavigateCallBack? onNavigate;

  _DeclarativeAutoRouterDelegate(
    RootStackRouter router, {
    required this.routes,
    String? navRestorationScopeId,
    @Deprecated('Use deepLinkBuilder instead') String? initialDeepLink,
    super.deepLinkBuilder,
    this.onPopRoute,
    this.onNavigate,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
  })  : assert(deepLinkBuilder == null || initialDeepLink == null),
        super(
          router,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: navigatorObservers,
          initialDeepLink: initialDeepLink,
        ) {
    router._managedByWidget = true;
  }

  @override
  Future<void> setInitialRoutePath(UrlState configuration) async {
    final platformDeepLink = PlatformDeepLink._(configuration);
    if (deepLinkBuilder != null) {
      final deepLink = await deepLinkBuilder!(platformDeepLink);
      _handleDeclarativeDeepLink(deepLink);
    }

    /// Todo remove below deprecated code
    // ignore: deprecated_member_use_from_same_package
    else if (initialDeepLink != null) {
      // ignore: deprecated_member_use_from_same_package
      _handleDeclarativeDeepLink(DeepLink.path(initialDeepLink!));
    } else if (configuration.hasSegments) {
      _handleDeclarativeDeepLink(platformDeepLink);
    }
    return SynchronousFuture(null);
  }

  void _handleDeclarativeDeepLink(DeepLink deepLink) {
    List<PageRouteInfo>? routes;
    if (deepLink is PlatformDeepLink) {
      routes = deepLink.matches.map((e) => e.toPageRouteInfo()).toList();
    } else if (deepLink is _PathDeepLink) {
      routes = controller.buildPageRoutesStack(deepLink.path);
    } else if (deepLink is _RoutesDeepLink) {
      routes = deepLink.routes;
    }
    controller.pendingRoutesHandler._setPendingRoutes(routes);
  }

  @override
  Future<void> setNewRoutePath(UrlState tree) async {
    return _onNavigate(tree);
  }

  Future<void> _onNavigate(UrlState tree) {
    if (tree.hasSegments) {
      controller.navigateAll(tree.segments);
    }
    if (onNavigate != null) {
      onNavigate!(tree);
    }

    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    final stateHash = controller.stateHash;
    return RouterScope(
      controller: controller,
      inheritableObserversBuilder: navigatorObservers,
      stateHash: stateHash,
      navigatorObservers: _navigatorObservers,
      child: StackRouterScope(
        controller: controller,
        stateHash: stateHash,
        child: AutoRouteNavigator(
          router: controller,
          declarativeRoutesBuilder: routes,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          didPop: onPopRoute,
        ),
      ),
    );
  }
}

/// Holds deep-link information
abstract class DeepLink {
  const DeepLink._();

  /// Whether this link is navigable
  ///
  /// e.g PathDeepLink.path.isNotEmpty;
  bool get isValid;

  /// Builds a deep-link from a list of [PageRouteInf]s
  const factory DeepLink(List<PageRouteInfo> routes) = _RoutesDeepLink;

  /// Builds a deep-link from a single [PageRouteInf]
  factory DeepLink.single(PageRouteInfo route) => _RoutesDeepLink([route]);

  /// Builds a deep-link form string path
  const factory DeepLink.path(String path, {bool includePrefixMatches}) = _PathDeepLink;

  /// Builds a deep link with initial path
  static const DeepLink defaultPath = DeepLink.path(Navigator.defaultRouteName);
}

class _PathDeepLink extends DeepLink {
  final String path;
  final bool includePrefixMatches;

  const _PathDeepLink(this.path, {this.includePrefixMatches = true}) : super._();

  @override
  bool get isValid => path.isNotEmpty;
}

class _RoutesDeepLink extends DeepLink {
  final List<PageRouteInfo> routes;

  const _RoutesDeepLink(this.routes) : super._();

  @override
  bool get isValid => routes.isNotEmpty;
}

/// Holds information of the deep-link
/// coming from the platform window
class PlatformDeepLink extends DeepLink {
  /// The initial url state parsed from initial raw path
  final UrlState configuration;

  /// The raw deep-link as String
  String get path => configuration.path;

  /// The parsed uri from the raw path
  Uri get uri => configuration.uri;

  /// The pre-matched routes from the row path
  List<RouteMatch> get matches => configuration.segments;

  const PlatformDeepLink._(this.configuration) : super._();

  @override
  bool get isValid => configuration.hasSegments;
}
