import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Adds auto-route data getter
/// to [Route]
extension RouteX<T> on Route<T> {
  /// Returns RouteData of this page if
  /// it's an [AutoRoutePage] otherwise it
  /// returns null
  RouteData? get data {
    if (settings is AutoRoutePage) {
      return (settings as AutoRoutePage).routeData;
    }
    return null;
  }
}

/// An extended version of  [NavigatorObserver] to support
/// Tab-int and tab-change events observation
class AutoRouterObserver extends NavigatorObserver {
  /// called when a tab route activates
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {}

  /// called when tab route reactivates
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {}
}

/// An interface used to mark classes as AutoRouteAware entities
/// usually implemented by widget States
mixin class AutoRouteAware {
  /// Called when the top route has been popped off, and the current route
  /// shows up.
  void didPopNext() {}

  /// Called when the current route has been pushed.
  void didPush() {}

  /// Called when the current route has been popped off.
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  void didPushNext() {}

  /// called when a tab route activates
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  /// called when tab route reactivates
  void didChangeTabRoute(TabPageRoute previousRoute) {}
}

/// a helper mixin to utilises [AutoRouteAware] in a better manner
/// and reduce boilerplate code
mixin AutoRouteAwareStateMixin<T extends StatefulWidget> on State<T> implements AutoRouteAware {
  AutoRouteObserver? _observer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouterScope exposes the list of provided observers
    // including inherited observers
    _observer = RouterScope.of(context).firstObserverOfType<AutoRouteObserver>();

    if (_observer != null) {
      // we subscribe to the observer by passing our
      // AutoRouteAware state and the scoped routeData
      _observer!.subscribe(this, context.routeData);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _observer?.unsubscribe(this);
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {}

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  @override
  void didPop() {}

  @override
  void didPush() {}

  @override
  void didPopNext() {}

  @override
  void didPushNext() {}
}

/// A [Navigator] observer that notifies [AutoRouteAware]s of changes to the
/// state of their [Route].
///
/// [AutoRouteObserver] informs subscribers whenever a route of type `R` is pushed
/// on top of their own route of type `R` or popped from it. This is for example
/// useful to keep track of page transitions, e.g. a `RouteObserver<PageRoute>`
/// will inform subscribed [AutoRouteAware]s whenever the user navigates away from
/// the current page route to another page route.
class AutoRouteObserver extends AutoRouterObserver {
  final Map<LocalKey, Set<AutoRouteAware>> _listeners = <LocalKey, Set<AutoRouteAware>>{};

  /// Subscribe [AutoRouteAware] to be informed about changes to [route].
  ///
  /// Going forward, [AutoRouteAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(AutoRouteAware routeAware, RouteData route) {
    final Set<AutoRouteAware> subscribers = _listeners.putIfAbsent(route.key, () => <AutoRouteAware>{});
    if (subscribers.add(routeAware)) {
      final router = route.router;
      if (router is TabsRouter) {
        final previousIndex = router.previousIndex;
        if (previousIndex != null && previousIndex >= 0 && previousIndex < router.stackData.length) {
          final previousRoute = TabPageRoute(
            routeInfo: router.stackData[previousIndex].route,
            index: previousIndex,
          );
          routeAware.didInitTabRoute(previousRoute);
        } else {
          routeAware.didInitTabRoute(null);
        }
      } else {
        routeAware.didPush();
      }
    }
  }

  /// Unsubscribe [AutoRouteAware].
  ///
  /// [AutoRouteAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.

  void unsubscribe(AutoRouteAware routeAware) {
    for (final route in _listeners.keys) {
      final Set<AutoRouteAware>? subscribers = _listeners[route];
      subscribers?.remove(routeAware);
    }
  }

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    final List<AutoRouteAware>? subscribers = _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final AutoRouteAware routeAware in subscribers) {
        routeAware.didInitTabRoute(previousRoute);
      }
    }
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    final List<AutoRouteAware>? subscribers = _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final AutoRouteAware routeAware in subscribers) {
        routeAware.didChangeTabRoute(previousRoute);
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is AutoRoutePage && previousRoute?.settings is AutoRoutePage) {
      final previousKey = (previousRoute!.settings as AutoRoutePage).routeKey;
      final List<AutoRouteAware>? previousSubscribers = _listeners[previousKey]?.toList();

      if (previousSubscribers != null) {
        for (final AutoRouteAware routeAware in previousSubscribers) {
          routeAware.didPopNext();
        }
      }
      final key = (route.settings as AutoRoutePage).routeKey;

      final List<AutoRouteAware>? subscribers = _listeners[key]?.toList();

      if (subscribers != null) {
        for (final AutoRouteAware routeAware in subscribers) {
          routeAware.didPop();
        }
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is AutoRoutePage && previousRoute?.settings is AutoRoutePage) {
      final previousKey = (previousRoute!.settings as AutoRoutePage).routeKey;
      final Set<AutoRouteAware>? previousSubscribers = _listeners[previousKey];

      if (previousSubscribers != null) {
        for (final AutoRouteAware routeAware in previousSubscribers) {
          routeAware.didPushNext();
        }
      }
    }
  }
}

/// Holds information of Tab-init and Tab-changed events
/// used in [AutoRouteAware] and [AutoRouterObserver]
class TabPageRoute {
  /// match information of the target tab
  final RouteMatch routeInfo;

  /// index of the target tab
  final int index;

  /// default constructor
  const TabPageRoute({
    required this.routeInfo,
    required this.index,
  });

  /// helper getter to access [RouteMatch.name]
  String get name => routeInfo.name;

  /// helper getter to access [RouteMatch.path]
  String get path => routeInfo.path;

  /// helper getter to access [RouteMatch.stringMatch]
  String get match => routeInfo.stringMatch;
}
