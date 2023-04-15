part of 'routing_controller.dart';

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

/// Represents a guarded navigation event
/// which can be either continued or aborted
/// used in [AutoRouteGuard.onNavigation]
class NavigationResolver {
  final StackRouter _router;
  final Completer<bool> _completer;

  /// The route being processing by the guard
  final RouteMatch route;

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

  /// default constructor
  NavigationResolver(
    this._router,
    this._completer,
    this.route, {
    this.pendingRoutes = const [],
  });

  /// Completes [_completer] with either true to continue navigation
  /// or false to abort navigation
  void next([bool continueNavigation = true]) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    _completer.complete(continueNavigation);
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
}

/// An abstraction for auto-redirect route guards
///
/// This type of guards can reevaluate any route guarded by it
/// and takes an action if [canNavigate] resolves to false
abstract class AutoRedirectGuardBase extends AutoRouteGuard with ChangeNotifier {
  late ReevaluationStrategy _strategy;

  /// Whether this route navigation is allowed
  Future<bool> canNavigate(RouteMatch route);

  /// The reevaluation strategy this guard should use
  ReevaluationStrategy get strategy => _strategy;

  /// reevaluate the routes allowed by this guard
  /// when evaluation logic changes
  ///
  /// e.g when the user is no longer authenticated
  /// and there are auth-protected routes in the stack
  void reevaluate({
    ReevaluationStrategy strategy = const ReevaluationStrategy.rePushFirstGuardedRoute(),
  }) {
    _strategy = strategy;
    notifyListeners();
  }

  Future<void> _reevaluate(StackRouter stackRouter) async {
    final stack = stackRouter.stackData;
    final firstGuardedRoute = stack.firstWhereOrNull(
      (r) => r._match.guards.contains(this),
    );
    if (firstGuardedRoute != null) {
      if (await canNavigate(firstGuardedRoute._match)) {
        return;
      }
    }
    _strategy.reevaluate(this, stackRouter);
  }
}

/// An Implementation of [AutoRedirectGuardBase]
abstract class AutoRedirectGuard extends AutoRedirectGuardBase {
  NavigationResolver? _redirectResolver;

  /// Pushes the given route to stack and removes it once
  /// resolver is completed
  @protected
  void redirect(PageRouteInfo route, {required NavigationResolver resolver}) async {
    if (_redirectResolver == resolver) return;
    _redirectResolver = resolver;
    assert(!resolver.isResolved, 'Resolver is already completed');
    final router = resolver._router._findStackScope(route);
    router.push(route).then((_) {
      if (!resolver.isResolved) {
        resolver.next(false);
      }
      _redirectResolver = null;
    });
    await resolver._completer.future;
    if (router.current.name == route.routeName) {
      router.markUrlStateForReplace();
    }
    router.removeWhere((r) => r.name == route.routeName, notify: false);
    _redirectResolver = null;
  }

  @override
  Future<void> _reevaluate(StackRouter stackRouter) async {
    if (_redirectResolver != null) {
      onNavigation(_redirectResolver!, stackRouter);
    } else {
      super._reevaluate(stackRouter);
    }
  }
}

/// An abstraction of the strategy used by [AutoRedirectGuardBase]
/// to decide the after evaluation action
abstract class ReevaluationStrategy {
  const ReevaluationStrategy._();

  /// Re-Calls [AutoRedirectGuardBase.onNavigation] if [AutoRedirectGuardBase.canNavigate]
  /// resolves to false
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router);

  /// Builds a [_RePushAllStrategy]
  const factory ReevaluationStrategy.rePushAllRoutes() = _RePushAllStrategy;

  /// Builds a [_RePushFirstGuarded] which re-pushes the very first guarded
  /// route by this guard if [AutoRedirectGuardBase.canNavigate] resolves to false
  /// on reevaluate
  const factory ReevaluationStrategy.rePushFirstGuardedRoute() = _RePushFirstGuarded;

  /// Builds a [_RePushFirstGuardedAndUp] which re-pushes the very first guarded route by this guard
  /// and every route above it in the stack  if [AutoRedirectGuardBase.canNavigate] resolves to false
  /// on reevaluate
  const factory ReevaluationStrategy.rePushFirstGuardedRouteAndUp() = _RePushFirstGuardedAndUp;

  /// Builds a [_RemoveFirstGuardedAndUp] which removes the very first guarded route by this guard
  /// and every route above it in the stack  if [AutoRedirectGuardBase.canNavigate] resolves to false
  /// on reevaluate
  const factory ReevaluationStrategy.removeFirstGuardedRouteAndUp() = _RemoveFirstGuardedAndUp;

  /// Builds a [_RemoveAllAndPush] which removes all the routes in the stack
  /// and pushes the given route if [AutoRedirectGuardBase.canNavigate] resolves to false
  /// on reevaluate
  const factory ReevaluationStrategy.removeAllAndPush(PageRouteInfo route) = _RemoveAllAndPush;
}

/// Re-pushes all the routes of stack
/// if [AutoRedirectGuardBase.canNavigate] resolves to false on reevaluate
class _RePushAllStrategy extends ReevaluationStrategy {
  const _RePushAllStrategy() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final stackData = router.stackData;
    final routesToRemove = List<RouteMatch>.unmodifiable(stackData.map((e) => e._match));
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }

    final routesToPush = <RouteMatch>[];
    for (final existingMatch in stackData.map((e) => e.route)) {
      final routeToPush = router.matcher.matchByRoute(
        existingMatch.toPageRouteInfo(),
      );
      if (routeToPush != null) {
        routesToPush.add(routeToPush);
      }
    }
    router._pushAllGuarded(routesToPush);
  }
}

class _RePushFirstGuarded extends ReevaluationStrategy {
  const _RePushFirstGuarded() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex = routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;

    final routesToRemove = routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }
    // resolve initial child routes if there are any
    final routeToPush = router.matcher.matchByRoute(
      routes[firstGuardedRouteIndex].toPageRouteInfo(),
    );
    if (routeToPush != null) {
      router._pushAllGuarded([routeToPush]);
    }
  }
}

class _RePushFirstGuardedAndUp extends ReevaluationStrategy {
  const _RePushFirstGuardedAndUp() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex = routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;
    final routesToRemove = routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }

    final routesToPush = <RouteMatch>[];
    for (final existingMatch in routes.sublist(
      firstGuardedRouteIndex,
      routes.length,
    )) {
      final routeToPush = router.matcher.matchByRoute(
        existingMatch.toPageRouteInfo(),
      );
      if (routeToPush != null) {
        routesToPush.add(routeToPush);
      }
    }
    router._pushAllGuarded(routesToPush);
  }
}

class _RemoveFirstGuardedAndUp extends ReevaluationStrategy {
  const _RemoveFirstGuardedAndUp() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex = routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;
    final routesToRemove = routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(
        route,
        notify: route == routesToRemove.last,
      );
    }
  }
}

class _RemoveAllAndPush extends ReevaluationStrategy {
  final PageRouteInfo route;

  const _RemoveAllAndPush(this.route) : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    router._reset();
    router.push(route);
  }
}
