import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';

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
  final Completer<bool> _completer;
  final RouteMatch route;
  final List<RouteMatch> pendingRoutes;

  NavigationResolver(
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
