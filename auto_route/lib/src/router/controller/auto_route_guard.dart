part of 'routing_controller.dart';

abstract class AutoRouteGuard {
  /// clients will call [resolver.next(true --> default)] to continue
  /// navigation or [resolver.next(false)] to abort navigation
  /// example
  /*
  class AuthGuard extends AutoRouteGuard {
  @override
  void canNavigate(NavigationResolver resolver, StackRouter router) {
     /// resolver.next(true) == we're good, continue navigation
     resolver.next(isAuthenticated)
  }
}
   */
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  );
}

class NavigationResolver {
  final StackRouter _router;
  final Completer<bool> _completer;
  final RouteMatch route;
  final List<RouteMatch> pendingRoutes;

  NavigationResolver(
    this._router,
    this._completer,
    this.route, {
    this.pendingRoutes = const [],
  });

  void next([bool continueNavigation = true]) {
    assert(!isResolved, 'Make sure `resolver.next()` is only called once.');
    _completer.complete(continueNavigation);
  }

  bool get isResolved => _completer.isCompleted;
}

abstract class AutoRedirectGuardBase extends AutoRouteGuard
    with ChangeNotifier {
  late ReevaluationStrategy _strategy;

  ReevaluationStrategy get strategy => _strategy;

  // reevaluate the routes allowed by this guard
  // when evaluation logic changes
  //
  // e.g when the user is no longer authenticated
  // and there are auth-protected routes in the stack
  void reevaluate({
    ReevaluationStrategy strategy =
        const ReevaluationStrategy.rePushFirstGuardedRoute(),
  }) {
    _strategy = strategy;
    notifyListeners();
  }

  Future<void> _reevaluate(StackRouter stackRouter) async {
    _strategy.reevaluate(this, stackRouter);
  }
}

abstract class AutoRedirectGuard extends AutoRedirectGuardBase {
  NavigationResolver? _redirectResolver;
  @protected
  void redirect(PageRouteInfo route,
      {required NavigationResolver resolver}) async {
    if (_redirectResolver != null) return;

    _redirectResolver = resolver;
    assert(!resolver.isResolved, 'Resolver is already completed');
    final router = resolver._router._findStackScope(route);
    router.push(route).then((_) => _redirectResolver = null);
    await resolver._completer.future;
    if (router.current.name == route.routeName) {
      router._removeLast(notify: false);
      router.markUrlStateForReplace();
    }
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

abstract class ReevaluationStrategy {
  const ReevaluationStrategy._();

  void reevaluate(AutoRedirectGuardBase guard, StackRouter router);

  const factory ReevaluationStrategy.rePushAllRoutes() = RePushAllStrategy;

  const factory ReevaluationStrategy.rePushFirstGuardedRoute() =
      RePushFirstGuarded;

  const factory ReevaluationStrategy.rePushFirstGuardedRouteAndUp() =
      RePushFirstGuardedAndUp;

  const factory ReevaluationStrategy.removeFirstGuardedRouteAndUp() =
      _removeFirstGuardedAndUp;
}

class RePushAllStrategy extends ReevaluationStrategy {
  const RePushAllStrategy() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final stackData = router.stackData;
    final routesToRemove =
        List<RouteMatch>.unmodifiable(stackData.map((e) => e._match));
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }

    router._pushAllGuarded(List.of(stackData.map((e) => e.route)));
  }
}

class RePushFirstGuarded extends ReevaluationStrategy {
  const RePushFirstGuarded() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex =
        routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;

    final routesToRemove =
        routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }
    router._pushAllGuarded([routes[firstGuardedRouteIndex]]);
  }
}

class RePushFirstGuardedAndUp extends ReevaluationStrategy {
  const RePushFirstGuardedAndUp() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex =
        routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;
    final routesToRemove =
        routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(route, notify: false);
    }
    router._pushAllGuarded(routes.sublist(
      firstGuardedRouteIndex,
      routes.length,
    ));
  }
}

class _removeFirstGuardedAndUp extends ReevaluationStrategy {
  const _removeFirstGuardedAndUp() : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    final routes = router.stackData.map((e) => e.route).toList();
    final firstGuardedRouteIndex =
        routes.indexWhere((r) => r.guards.contains(guard));
    if (firstGuardedRouteIndex == -1) return;
    final routesToRemove =
        routes.sublist(firstGuardedRouteIndex, routes.length);
    for (final route in routesToRemove) {
      router._removeRoute(
        route,
        notify: route == routesToRemove.last,
      );
    }
  }
}
