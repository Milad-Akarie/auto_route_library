part of 'routing_controller.dart';

// ignore_for_file: deprecated_member_use_from_same_package
/// Signature for on navigation function used by [AutoRouteGuard]
typedef OnNavigation = Function(
    NavigationResolver resolver, StackRouter router);

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
  factory AutoRouteGuard.simple(OnNavigation onNavigation) =
      AutoRouteGuardCallback;

  /// Builds a simple instance that returns either a redirect-to route or null for no redirect
  factory AutoRouteGuard.redirect(
          PageRouteInfo? Function(NavigationResolver resolver) redirect) =
      _AutoRouteGuardRedirectCallback;

  /// Builds a simple instance that returns either a redirect-to path or null for no redirect
  factory AutoRouteGuard.redirectPath(
          String? Function(NavigationResolver resolver) redirect) =
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
  factory ReevaluateListenable.stream(Stream stream) =
      _StreamReevaluateListenable;
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

  /// Default constructor
  const ResolverResult({
    required this.continueNavigation,
    required this.reevaluateNext,
  });
}

/// Represents a guarded navigation event
/// which can be either continued or aborted
/// used in [AutoRouteGuard.onNavigation]
class NavigationResolver {
  final StackRouter _router;
  final Completer<ResolverResult> _completer;

  /// Whether the navigation event is triggered
  /// by [StackRouter.reevaluateGuards]
  final bool isReevaluating;

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

  /// default constructor
  NavigationResolver(
    this._router,
    this._completer,
    this.route, {
    this.pendingRoutes = const [],
    this.isReevaluating = false,
  });

  /// Completes [_completer] with either true to continue navigation
  /// or false to abort navigation
  void next([bool continueNavigation = true]) =>
      resolveNext(continueNavigation);

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
      ),
    );
  }

  /// Keeps track of the navigated-to route
  /// To be auto-removed when [completer] is resolved
  Future<T?> redirect<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) async {
    return _router._redirect(
      route,
      onFailure: onFailure,
      replace: replace,
      onMatch: (scope, match) async {
        await _completer.future;
        scope.markUrlStateForReplace();
        scope._removeRoute(match);
      },
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
}
