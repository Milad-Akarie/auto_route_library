part of 'routing_controller.dart';

/// Signature for on navigation function used by [AutoRouteGuard]
typedef OnNavigation = FutureOr<void> Function(NavigationResolver resolver, StackRouter router);

/// A middleware for stacked routes where clients
/// can either resume or abort the navigation event
abstract class AutoRouteGuard {
  /// Default constructor
  const new();

  /// Builds a simple instance that takes in the [OnNavigation] callback
  factory simple(OnNavigation onNavigation, {String? debugLabel}) = AutoRouteGuardCallback;

  /// Builds a simple instance that returns either a redirect-to route or null for no redirect
  factory redirect(PageRouteInfo? Function(NavigationResolver resolver) redirect) = _AutoRouteGuardRedirectCallback;

  /// Builds a simple instance that returns either a redirect-to path or null for no redirect
  factory redirectPath(String? Function(NavigationResolver resolver) redirect) = _AutoRouteGuardRedirectPathCallback;

  /// clients will call [NavigationResolver.next] to continue
  /// navigation or [NavigationResolver.reject] to abort navigation
  /// example
  /*
  class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
     if (isAuthenticated) {
       resolver.next();
     } else {
       resolver.reject();
     }
  }
}
   */
  FutureOr<void> onNavigation(NavigationResolver resolver, StackRouter router);
}

class _AutoRouteGuardRedirectCallback extends AutoRouteGuard {
  const new(this.redirect);
  final PageRouteInfo? Function(NavigationResolver resolver) redirect;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final redirectTo = redirect(resolver);
    if (redirectTo != null) {
      final scope = router._findStackScope(redirectTo);
      unawaited(scope._push(redirectTo, onMatch: (match) => _redirectingResolvers[match.id] = resolver));
    }
    if (redirectTo == null) {
      resolver.next();
    } else {
      resolver.reject();
    }
  }
}

class _AutoRouteGuardRedirectPathCallback extends AutoRouteGuard {
  const new(this.redirect);
  final String? Function(NavigationResolver resolver) redirect;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final redirectTo = redirect(resolver);
    if (redirectTo != null) {
      final scope = router._findPathScopeOrReportFailure<StackRouter>(redirectTo);
      if (scope != null) {
        for (final match in scope.matches) {
          _redirectingResolvers[match.id] = resolver;
        }
        unawaited(scope.router._pushAllGuarded(scope.matches));
      }
    }
    if (redirectTo == null) {
      resolver.next();
    } else {
      resolver.reject();
    }
  }
}

/// Abstraction for an Adapter that converts
/// different listenable types e.g (streams) to a ChangeNotifier

abstract class ReevaluateListenable extends ChangeNotifier {
  /// Default constructor
  new();

  /// Builds [ReevaluateListenable] from a stream
  factory stream(Stream<Object?> stream) = _StreamReevaluateListenable;
}

class _StreamReevaluateListenable extends ReevaluateListenable {
  new(Stream<Object?> stream) {
    _streamSub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<Object?> _streamSub;

  @override
  void dispose() {
    unawaited(_streamSub.cancel());
    super.dispose();
  }
}

/// A simple implementation of [AutoRouteGuard] that
/// calls the provided [OnNavigation] function
///
/// use if there's no need to implement your own
class AutoRouteGuardCallback extends AutoRouteGuard {
  /// Default constructor
  const new(this.onNavigate, {this.debugLabel});

  /// The callback called by [AutoRouteGuard.onNavigation]
  final OnNavigation onNavigate;

  /// An optional debug name for easier identification
  final String? debugLabel;

  // Returns the callback's future, so a guard re-check can wait for an async callback.
  @override
  FutureOr<void> onNavigation(NavigationResolver resolver, StackRouter router) => onNavigate(resolver, router);

  @override
  String toString() => 'AutoRouteGuardCallback(${debugLabel ?? hashCode})';
}

/// Holds how a guard resolved: [NavigationResolver.next], [NavigationResolver.reject] or
/// [NavigationResolver.overrideNext]
class ResolverResult {
  /// Default constructor
  const new({required this.continueNavigation, required this.reevaluateNext, required this.route});

  /// Whether to resume the navigation event or abort it
  final bool continueNavigation;

  /// Whether to re-push pending routes on [StackRouter.reevaluateGuards]
  final bool reevaluateNext;

  /// Holds the route to be used in the navigation event
  final RouteMatch<Object?> route;

  //// clones this instance with the provided values
  ResolverResult copyWith({bool? continueNavigation, bool? reevaluateNext, RouteMatch<Object?>? route}) {
    return ResolverResult(
      continueNavigation: continueNavigation ?? this.continueNavigation,
      reevaluateNext: reevaluateNext ?? this.reevaluateNext,
      route: route ?? this.route,
    );
  }
}

// The resolver whose redirect opened a route, by the route's match id: the
// redirectUntil() or the AutoRouteGuard.redirect() of the guard that sent the user there.
final _redirectingResolvers = Expando<NavigationResolver>('redirectingResolvers');

/// Represents a guarded navigation event
/// which can be either continued or aborted
/// used in [AutoRouteGuard.onNavigation]
class NavigationResolver {
  /// default constructor
  new(this._router, this._completer, this.route, {this.pendingRoutes = const [], this._isReevaluating = false});
  final StackRouter _router;
  final Completer<ResolverResult> _completer;

  /// Whether the navigation event is triggered
  /// by [StackRouter.reevaluateGuards]
  bool get isReevaluating => _isReevaluating;

  bool _isReevaluating = false;

  /// The route being processing by the guard
  final RouteMatch<Object?> route;

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
  /// when we process  Rout2 next pending routes will contain `Route3` only
  final List<RouteMatch<Object?>> pendingRoutes;

  /// returns the navigator context
  ///
  /// Be-aware build context can be null if the navigator is not yet mounted
  /// this happens if you're guarding the first route in the app
  BuildContext get context {
    final context = _router.globalRouterKey.currentContext;
    assert(context != null, 'Router is not mounted');
    return context!;
  }

  /// Lets the navigation continue to [route].
  ///
  /// Call this, [reject] or [overrideNext] once per navigation. Passing false
  /// is the deprecated way to reject it.
  void next([
    // The old way to reject, kept so existing guards compile until it is removed in 13.0.0.
    // ignore: avoid_positional_boolean_parameters
    @Deprecated('Call next() to continue or reject() to stop') bool continueNavigation = true,
  ]) => _resolve(continueNavigation: continueNavigation, reevaluateNext: true);

  /// Stops the navigation: [route] is not opened.
  ///
  /// With [goBack], the router also goes back, which reverts the url when the
  /// navigation came from it, such as a link opened in the browser.
  ///
  /// With [reevaluateNext] false, the routes pending after [route] are not
  /// pushed again when `RoutingController.reevaluateGuards` runs this guard.
  void reject({bool goBack = false, bool reevaluateNext = true}) {
    _resolve(continueNavigation: false, reevaluateNext: reevaluateNext);
    if (goBack) {
      _router.back();
    }
  }

  /// Completes [_completer] with either true to continue navigation
  /// or false to abort navigation
  ///
  /// if [reevaluateNext] is set to true pending routes will also be re-pushed
  /// to stack on `RoutingController.reevaluateGuards`
  // Deprecated in 12.0.0, removed in 13.0.0.
  @Deprecated(
    'Call next() or reject(reevaluateNext: false), or overrideNext(reevaluateNext: false) to continue without '
    'pushing the pending routes again',
  )
  // The deprecated signature, kept so existing guards compile until it is removed.
  // ignore: avoid_positional_boolean_parameters
  void resolveNext(bool continueNavigation, {bool reevaluateNext = true}) =>
      _resolve(continueNavigation: continueNavigation, reevaluateNext: reevaluateNext);

  void _resolve({required bool continueNavigation, required bool reevaluateNext}) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    _complete(ResolverResult(continueNavigation: continueNavigation, reevaluateNext: reevaluateNext, route: route));
  }

  // The result the guard resolved with, known at once, before [future]
  // completes, so a tab change a guard decides at once stays synchronous.
  ResolverResult? _result;

  void _complete(ResolverResult result) {
    _result = result;
    _completer.complete(result);
  }

  /// Overrides the current route with the provided values
  ///
  /// overridden routes will not be processed by the same guard again
  /// in the same navigation event
  void overrideNext({
    List<PageRouteInfo>? children,
    Object? args,
    Map<String, Object?>? queryParams,
    String? fragment,
    bool reevaluateNext = true,
  }) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    final overrides = RouteOverrides(children: children, args: args, queryParams: queryParams, fragment: fragment);
    final overriddenRoute = overrides.override(route, _router.matcher);
    _complete(ResolverResult(continueNavigation: true, reevaluateNext: reevaluateNext, route: overriddenRoute));
  }

  bool _isRedirecting = false;

  /// Temporary redirect to another route until the [_completer] is resolved
  ///
  /// Calling resolver.next() or resolver.reject()
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
  ///
  /// The returned future completes once [route] is closed, whether by
  /// [next] or by a pop, and at once when a redirect is already running or
  /// [route] can't be opened.
  Future<void> redirectUntil(PageRouteInfo target, {OnNavigationFailure? onFailure, bool replace = false}) async {
    if (_isRedirecting) return;
    _isRedirecting = true;
    // keep the page being reevaluated under the redirect route so its state is preserved
    final reevaluatedRoute = route;
    if (reevaluatedRoute is ReevaluatableRouteMatch<Object?, Object?> &&
        !_router._pages.contains(reevaluatedRoute.currentPage)) {
      _router._pages.add(reevaluatedRoute.currentPage);
    }
    await _router._redirect(
      target,
      onFailure: onFailure,
      replace: replace,
      onMatch: (scope, match) => unawaited(_removeRedirectOnceResolved(scope, match)),
    );
    if (!_completer.isCompleted) {
      reject();
    }
  }

  // Once this resolver is resolved, the redirect route that [redirectUntil]
  // pushed leaves the stack.
  Future<void> _removeRedirectOnceResolved(StackRouter scope, RouteMatch<Object?> match) async {
    _redirectingResolvers[match.id] = this;
    await _completer.future;
    _isRedirecting = false;
    final routeData = scope.stackData.firstWhereOrNull((e) => e.matchId == match.id);
    if (routeData != null) {
      scope
        ..markUrlStateForReplace()
        .._removeRoute(match);
      // complete the pop completer with null result
      routeData.onPopInvoked(null);
    }
  }

  /// Helpful for when you want to revert to the previous
  /// url back can not navigate
  ///
  /// Without an argument it is the same as [next]; `reject(goBack: true)`
  /// replaces the deprecated `nextOrBack(false)`.
  void nextOrBack([
    // The old way to reject, kept so existing guards compile until it is removed in 13.0.0.
    // ignore: avoid_positional_boolean_parameters
    @Deprecated('Call nextOrBack() to continue or reject(goBack: true) to stop and go back')
    bool continueNavigation = true,
  ]) {
    if (continueNavigation) {
      next();
    } else {
      reject(goBack: true);
    }
  }

  // Rejects [route] when the guards that redirected the user here opened the
  // same route earlier in this chain of redirects, which would repeat without end.
  bool _reportRedirectLoop() {
    final chain = <RouteMatch<Object?>>[];
    for (var by = _redirectingResolvers[route.id]; by != null; by = _redirectingResolvers[by.route.id]) {
      chain.insert(0, by.route);
      final isSame = by.route.name == route.name && by.route.fullPath == route.fullPath;
      if (isSame) {
        _reportLoop([...chain, route]);
        reject();
        return true;
      }
      // A re-check starts its own chain; the redirects that once opened its route are over.
      if (by.isReevaluating) break;
    }
    return false;
  }

  void _reportLoop(List<RouteMatch<Object?>> loop) {
    final name = route.name;
    final names = loop.map((match) => match.name).join(' → ');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: FlutterError.fromParts([
          if (loop.length == 2)
            ErrorSummary('A guard redirected $name to itself.')
          else
            ErrorSummary('Guards redirected in a loop: $names.'),
          ErrorDescription(
            '$name was opened by the redirect of a guard, and guards redirected the user to $name again, which '
            'would repeat without end. $name is not opened.',
          ),
          ErrorHint(
            'A guard in RootStackRouter.guards runs for every route, including the one it redirects to. '
            'Let a route in the loop through, e.g. call resolver.next() when resolver.routeName is $name.',
          ),
        ]),
        library: 'auto_route',
      ),
    );
  }

  /// Whether [_completer] is completed
  /// see [Completer.isCompleted]
  bool get isResolved => _completer.isCompleted;

  /// The future that will be completed by [next], [reject] or [overrideNext]
  Future<ResolverResult> get future => _completer.future;

  Completer<void>? _waitingCompleter;

  /// Checks the provided [guard] and waits for it to complete
  ///
  /// If there's an ongoing guard check, it waits for it to complete first
  /// before checking the provided [guard]
  /// returns the [ResolverResult] of the guard check
  Future<ResolverResult> checkGuard(AutoRouteGuard guard, StackRouter router) async {
    if (_reportRedirectLoop()) return future;
    // Several reevaluations can wait for the same check; each takes its own turn.
    while (_waitingCompleter != null) {
      await _waitingCompleter!.future;
      if (isResolved) return future;
    }
    final waiting = _waitingCompleter = Completer<void>();
    try {
      await guard.onNavigation(this, router);
    } finally {
      _waitingCompleter = null;
      waiting.complete();
    }
    return future;
  }
}

/// Holds overridable route values
class RouteOverrides {
  /// Default constructor
  const new({this.children, this.args, this.queryParams, this.fragment});

  /// The override value of `PageRouteInfo.children`
  final List<PageRouteInfo>? children;

  /// The override value of [PageRouteInfo.args]
  ///
  /// it must be the same args type generated by the corresponding page's constructor
  final Object? args;

  /// The override value of [PageRouteInfo.queryParams]
  final Map<String, Object?>? queryParams;

  /// The override value of [PageRouteInfo.fragment]
  final String? fragment;

  /// Builds a new [PageRouteInfo] with the provided overrides
  RouteMatch<Object?> override(RouteMatch<Object?> route, RouteMatcher matcher) {
    final matches = <RouteMatch<Object?>>[];
    if (children != null) {
      final coll = matcher.collection.subCollectionOf(route.name);
      final subMatcher = RouteMatcher(coll);
      for (final child in children!) {
        final match = subMatcher.matchByRoute(child);
        if (match == null) {
          throw FlutterError(
            'Failed to navigate to overridden child ${child.routeName}.\nPlease make sure the route is declared as a child of ${route.name}',
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
