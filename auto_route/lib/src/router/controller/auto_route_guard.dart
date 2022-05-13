part of 'routing_controller.dart';

abstract class AutoRouteGuard {
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

  Future<bool> canNavigate(RouteMatch route);

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

abstract class AutoRedirectGuard extends AutoRedirectGuardBase {
  NavigationResolver? _redirectResolver;

  @protected
  void redirect(PageRouteInfo route,
      {required NavigationResolver resolver}) async {
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

abstract class ReevaluationStrategy {
  const ReevaluationStrategy._();

  void reevaluate(AutoRedirectGuardBase guard, StackRouter router);

  const factory ReevaluationStrategy.rePushAllRoutes() = RePushAllStrategy;

  const factory ReevaluationStrategy.rePushFirstGuardedRoute() =
      RePushFirstGuarded;

  const factory ReevaluationStrategy.rePushFirstGuardedRouteAndUp() =
      RePushFirstGuardedAndUp;

  const factory ReevaluationStrategy.removeFirstGuardedRouteAndUp() =
      _RemoveFirstGuardedAndUp;

  const factory ReevaluationStrategy.removeAllAndPush(PageRouteInfo route) =
      _RemoveAllAndPush;
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
    // resolve initial child routes if there are any
    final routeToPush = router.matcher.matchByRoute(
      routes[firstGuardedRouteIndex].toPageRouteInfo(),
    );
    if (routeToPush != null) {
      router._pushAllGuarded([routeToPush]);
    }
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

class _RemoveAllAndPush extends ReevaluationStrategy {
  final PageRouteInfo route;

  const _RemoveAllAndPush(this.route) : super._();

  @override
  void reevaluate(AutoRedirectGuardBase guard, StackRouter router) {
    router._reset();
    router.push(route);
  }
}
