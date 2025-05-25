part of 'routing_controller.dart';

// ignore_for_file: deprecated_member_use_from_same_package
/// Signature for on navigation function used by [AutoRouteGuard]
typedef OnNavigation = Function(NavigationResolver resolver, StackRouter router);

/// A middleware for stacked routes where clients
/// can either resume or abort the navigation event
abstract class AutoRouteGuard {
  /// Default constructor
  const AutoRouteGuard();

  /// clients will call [resolver.next(true --> default)] to continue
  /// navigation or [resolver.next(false)] to abort navigation
  /// example
  /*
  class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
     /// resolver.next(true) == we're good, continue navigation
     resolver.next(isAuthenticated)
  }
}
   */
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  );

  /// Builds a simple instance that takes in the [OnNavigation] callback
  factory AutoRouteGuard.simple(OnNavigation onNavigation) = AutoRouteGuardCallback;

  /// Builds a simple instance that returns either a redirect-to route or null for no redirect
  factory AutoRouteGuard.redirect(PageRouteInfo? Function(NavigationResolver resolver) redirect) =
      _AutoRouteGuardRedirectCallback;

  /// Builds a simple instance that returns either a redirect-to path or null for no redirect
  factory AutoRouteGuard.redirectPath(String? Function(NavigationResolver resolver) redirect) =
      _AutoRouteGuardRedirectPathCallback;
}

class _AutoRouteGuardRedirectCallback extends AutoRouteGuard {
  final PageRouteInfo? Function(NavigationResolver resolver) redirect;

  const _AutoRouteGuardRedirectCallback(this.redirect);

  @override
  void onNavigation(NavigationResolver resolver, router) {
    final redirectTo = redirect(resolver);
    if (redirectTo != null) {
      router.push(redirectTo);
    }
    resolver.next(redirectTo == null);
  }
}

class _AutoRouteGuardRedirectPathCallback extends AutoRouteGuard {
  final String? Function(NavigationResolver resolver) redirect;

  const _AutoRouteGuardRedirectPathCallback(this.redirect);

  @override
  void onNavigation(NavigationResolver resolver, router) {
    final redirectTo = redirect(resolver);
    if (redirectTo != null) {
      router.pushNamed(redirectTo);
    }
    resolver.next(redirectTo == null);
  }
}

/// Abstraction for an Adapter that converts
/// different listenable types e.g (streams) to a ChangeNotifier

abstract class ReevaluateListenable extends ChangeNotifier {
  /// Default constructor
  ReevaluateListenable();

  /// Builds [ReevaluateListenable] from a stream
  factory ReevaluateListenable.stream(Stream stream) = _StreamReevaluateListenable;
}

class _StreamReevaluateListenable extends ReevaluateListenable {
  late final StreamSubscription _streamSub;

  _StreamReevaluateListenable(Stream stream) {
    _streamSub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _streamSub.cancel();
    super.dispose();
  }
}

/// A simple implementation of [AutoRouteGuard] that
/// calls the provided [OnNavigation] function
///
/// use if there's no need to implement your own
class AutoRouteGuardCallback extends AutoRouteGuard {
  /// The callback called by [AutoRouteGuard.onNavigation]
  final OnNavigation onNavigate;

  /// Default constructor
  const AutoRouteGuardCallback(this.onNavigate);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    onNavigate(resolver, router);
  }
}

/// Holds [NavigationResolver.resolveNext] values
class ResolverResult {
  /// Whether to resume the navigation event or abort it
  final bool continueNavigation;

  /// Whether to re-push pending routes on [StackRouter.reevaluateGuards]
  final bool reevaluateNext;

  /// Holds the route to be used in the navigation event
  final RouteMatch route;

  /// Default constructor
  const ResolverResult({
    required this.continueNavigation,
    required this.reevaluateNext,
    required this.route,
  });

  //// clones this instance with the provided values
  ResolverResult copyWith({
    bool? continueNavigation,
    bool? reevaluateNext,
    RouteMatch? route,
  }) {
    return ResolverResult(
      continueNavigation: continueNavigation ?? this.continueNavigation,
      reevaluateNext: reevaluateNext ?? this.reevaluateNext,
      route: route ?? this.route,
    );
  }
}

/// Represents a guarded navigation event
/// which can be either continued or aborted
/// used in [AutoRouteGuard.onNavigation]
class NavigationResolver {
  final StackRouter _router;
  final Completer<ResolverResult> _completer;

  /// Whether the navigation event is triggered
  /// by [StackRouter.reevaluateGuards]
  bool get isReevaluating => _isReevaluating;

  bool _isReevaluating = false;

  /// The route being processing by the guard
  final RouteMatch route;

  /// Helper to get [RouteMatch.name]
  String get routeName => route.name;

  /// If there are more that one route in
  /// the navigation even pending routes will
  /// be the routes that's waiting to be processed by guard
  ///
  /// e.g if we pushAll[Route1,Route2,Route3]
  /// the first route to be processed is Route1 and that's assigned to [route]
  /// and pending routes will contain [Route2, Route3]
  ///
  /// when we process  Rout2 next pending routes will contain [Route3] only
  final List<RouteMatch> pendingRoutes;

  /// returns the navigator context
  ///
  /// Be-aware build context can be null if the navigator is not yet mounted
  /// this happens if you're guarding the first route in the app
  BuildContext get context {
    final context = _router.globalRouterKey.currentContext;
    assert(context != null, 'Router is not mounted');
    return context!;
  }

  /// default constructor
  NavigationResolver(
    this._router,
    this._completer,
    this.route, {
    this.pendingRoutes = const [],
    bool isReevaluating = false,
  }) : _isReevaluating = isReevaluating;

  /// Completes [_completer] with either true to continue navigation
  /// or false to abort navigation
  void next([bool continueNavigation = true]) => resolveNext(continueNavigation);

  /// Completes [_completer] with either true to continue navigation
  /// or false to abort navigation
  ///
  /// if [reevaluateNext] is set to true pending routes will also be re-pushed
  /// to stack on [RoutingController.reevaluateGuards]
  void resolveNext(bool continueNavigation, {bool reevaluateNext = true}) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    _completer.complete(
      ResolverResult(
        continueNavigation: continueNavigation,
        reevaluateNext: reevaluateNext,
        route: route,
      ),
    );
  }

  /// Overrides the current route with the provided values
  ///
  /// overridden routes will not be processed by the same guard again
  /// in the same navigation event
  void overrideNext({
    List<PageRouteInfo>? children,
    Object? args,
    Map<String, dynamic>? queryParams,
    String? fragment,
    bool reevaluateNext = true,
  }) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    final overrides = RouteOverrides(
      children: children,
      args: args,
      queryParams: queryParams,
      fragment: fragment,
    );
    final overriddenRoute = overrides.override(route, _router.matcher);
    _completer.complete(
      ResolverResult(
        continueNavigation: true,
        reevaluateNext: reevaluateNext,
        route: overriddenRoute,
      ),
    );
  }

  bool _isRedirecting = false;

  /// Temporary redirect to another route until the [_completer] is resolved
  ///
  /// Calling resolver.next() or resolver.resolveNext()
  /// will remove the redirected route and mark it for replace
  /// in browser history
  ///
  /// This is typically used like follows
  ///
  /// onNavigation(resolver, router) {
  ///    if (isAuthenticated) {
  ///      resolver.next();
  ///    } else {
  ///      resolver.redirectUntil(LoginRoute());
  ///    }
  ///  }
  Future<T?> redirectUntil<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) async {
    if (_isRedirecting) return null;
    _isRedirecting = true;
    final result = await _router._redirect<T>(
      route,
      onFailure: onFailure,
      replace: replace,
      onMatch: (scope, match) async {
        await _completer.future;
        _isRedirecting = false;
        if (scope.stackData.any((e) => e.matchId == match.id)) {
          scope.markUrlStateForReplace();
          scope._removeRoute(match);
        }
      },
    );
    if (!_completer.isCompleted) {
      next(false);
    }
    return result;
  }

  /// Keeps track of the navigated-to route
  /// To be auto-removed when [completer] is resolved
  @Deprecated('Renamed to "redirectUntil" to avoid confusion')
  Future<T?> redirect<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) {
    return redirectUntil<T>(
      route,
      onFailure: onFailure,
      replace: replace,
    );
  }

  /// Helpful for when you want to revert to the previous
  /// url back can not navigate
  void nextOrBack([bool continueNavigation = true]) {
    next(continueNavigation);
    if (!continueNavigation) {
      _router.back();
    }
  }

  /// Whether [_completer] is completed
  /// see [Completer.isCompleted]
  bool get isResolved => _completer.isCompleted;

  /// The future that will be completed by [resolveNext]
  Future<ResolverResult> get future => _completer.future;
}

/// Holds overridable route values
class RouteOverrides {
  /// The override value of [PageRouteInfo.children]
  final List<PageRouteInfo>? children;

  /// The override value of [PageRouteInfo.args]
  ///
  /// it must be the same args type generated by the corresponding page's constructor
  final Object? args;

  /// The override value of [PageRouteInfo.queryParams]
  final Map<String, dynamic>? queryParams;

  /// The override value of [PageRouteInfo.fragment]
  final String? fragment;

  /// Default constructor
  const RouteOverrides({
    this.children,
    this.args,
    this.queryParams,
    this.fragment,
  });

  /// Builds a new [PageRouteInfo] with the provided overrides
  RouteMatch override(RouteMatch route, RouteMatcher matcher) {
    final matches = <RouteMatch>[];
    if (children != null) {
      final coll = matcher.collection.subCollectionOf(route.name);
      final subMatcher = RouteMatcher(coll);
      for (final child in children!) {
        final match = subMatcher.matchByRoute(child);
        if (match == null) {
          throw FlutterError(
            "Failed to navigate to overridden child ${child.routeName}.\nPlease make sure the route is declared as a child of ${route.name}",
          );
        }
        matches.add(match);
      }
    }
    return route.copyWith(
      args: args,
      queryParams: queryParams == null ? null : Parameters(queryParams),
      children: matches.isEmpty ? null : matches,
      fragment: fragment,
    );
  }
}
