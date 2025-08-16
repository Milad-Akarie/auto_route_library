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
    assert(delegate is AutoRouterDelegate);
    return delegate as AutoRouterDelegate;
  }

  /// Forces a url update
  static void reportUrlChanged(BuildContext context, String url) {
    Router.of(context).routeInformationProvider?.routerReportsNewRouteInformation(
          RouteInformation(uri: Uri.parse(url)),
          type: RouteInformationReportingType.navigate,
        );
  }

  @override
  Future<bool> popRoute() async => controller.maybePopTop();

  late List<NavigatorObserver> _navigatorObservers;

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
  }

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
    final platformDeepLink = PlatformDeepLink._(configuration, true);
    if (deepLinkBuilder != null) {
      return _handleDeepLink(await deepLinkBuilder!(platformDeepLink));
    } else if (platformDeepLink.isValid) {
      return _handleDeepLink(platformDeepLink);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  Future<void> _handleDeepLink(DeepLink deepLink) {
    if (deepLink is _IgnoredDeepLink) return SynchronousFuture(null);

    throwIf(!deepLink.isValid, 'Can not resolve initial route');
    if (deepLink is PlatformDeepLink) {
      _onNewUrlState(deepLink.configuration);
      return controller.navigateAll(deepLink.matches);
    } else if (deepLink is _PathDeepLink) {
      if (deepLink.navigate) {
        return controller.navigatePath(
          deepLink.path,
          includePrefixMatches: deepLink.includePrefixMatches,
        );
      } else {
        return controller.pushPath(
          deepLink.path,
          includePrefixMatches: deepLink.includePrefixMatches,
        );
      }
    } else if (deepLink is _RoutesDeepLink) {
      if (deepLink.navigate) {
        return controller._navigateAllRoutes(deepLink.routes);
      } else {
        return controller.pushAll(deepLink.routes);
      }
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
      final platLink = PlatformDeepLink._(configuration, false);
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    removeListener(_handleRebuild);
    reevaluateListenable?.removeListener(controller.reevaluateGuards);
    controller.dispose();
  }

  /// Force this delegate to rebuild
  void notifyUrlChanged() => _handleRebuild();
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
  /// an empty page with [Theme.scaffoldBackgroundColor].
  final WidgetBuilder? placeholder;

  final TraversalEdgeBehavior? routeTraversalEdgeBehavior;

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
  const DeepLink._();

  /// Whether this link is navigable
  ///
  /// e.g PathDeepLink.path.isNotEmpty;
  bool get isValid;

  /// Builds a deep-link from a list of [PageRouteInf]s
  const factory DeepLink(List<PageRouteInfo> routes, {bool navigate}) = _RoutesDeepLink;

  /// Builds a deep-link from a single [PageRouteInf]
  factory DeepLink.single(PageRouteInfo route, {bool navigate = true}) {
    return _RoutesDeepLink([route], navigate: navigate);
  }

  /// Builds a deep-link form string path
  const factory DeepLink.path(String path, {bool includePrefixMatches, bool navigate}) = _PathDeepLink;

  /// Builds a deep link with initial path
  static const DeepLink defaultPath = DeepLink.path(Navigator.defaultRouteName);

  /// Builds an ignored deep link instance
  static const DeepLink none = _IgnoredDeepLink();

  /// Helper function to remove the prefix path of a [Uri]
  /// You can use this method to remove the prefix of a path
  /// the prefix should start with a [/]
  ///
  /// If not able to parse the resulting Uri, return the original
  static DeepLinkTransformer prefixStripper(String prefix) {
    return (Uri uri) {
      if (!uri.path.startsWith(prefix)) {
        return SynchronousFuture(uri); // No change if prefix not found
      }
      return SynchronousFuture(
        Uri.tryParse(uri.toString().replaceFirst(prefix, '')) ?? uri,
      );
    };
  }
}

class _PathDeepLink extends DeepLink {
  final String path;
  final bool includePrefixMatches;

  /// if false the path will be pushed instead of navigated
  final bool navigate;

  const _PathDeepLink(
    this.path, {
    this.includePrefixMatches = true,
    this.navigate = true,
  }) : super._();

  @override
  bool get isValid => path.isNotEmpty;
}

class _RoutesDeepLink extends DeepLink {
  final List<PageRouteInfo> routes;

  /// if false the routes will be pushed instead of navigated
  final bool navigate;

  const _RoutesDeepLink(
    this.routes, {
    this.navigate = true,
  }) : super._();

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
  /// The initial url state parsed from initial raw path
  final UrlState configuration;

  /// The raw deep-link as String
  String get path => configuration.path;

  /// The parsed uri from the raw path
  Uri get uri => configuration.uri;

  /// Whether this is the initial deep-link
  final bool initial;

  /// The pre-matched routes from the row path
  List<RouteMatch> get matches => configuration.segments;

  const PlatformDeepLink._(this.configuration, this.initial) : super._();

  @override
  bool get isValid => configuration.hasSegments;
}
