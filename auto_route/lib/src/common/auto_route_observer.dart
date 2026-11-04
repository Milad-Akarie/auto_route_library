import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Adds auto-route data getter
/// to [Route]
extension RouteX<T> on Route<T> {
  /// Returns RouteData of this page if
  /// it's an [AutoRoutePage] otherwise it
  /// returns null
  RouteData<dynamic>? get data {
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
  // A hook for subclasses: the default does nothing with what it is told.
  // ignore: avoid-unused-parameters
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {}

  /// called when tab route reactivates
  // A hook for subclasses: the default does nothing with what it is told.
  // ignore: avoid-unused-parameters
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
  // A hook for implementers: the default does nothing with what it is told.
  // ignore: avoid-unused-parameters
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  /// called when tab route reactivates
  // A hook for implementers: the default does nothing with what it is told.
  // ignore: avoid-unused-parameters
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
    _observer?.unsubscribe(this);
    super.dispose();
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

  // Subscribers of routes inside nested routers, keyed by the route in this
  // observer's navigator that hosts them, each with the route it subscribed to.
  final Map<LocalKey, Map<AutoRouteAware, RouteData<dynamic>>> _nestedListeners = {};

  // The observers of ancestor navigators each subscriber was added to.
  final Map<AutoRouteAware, Set<AutoRouteObserver>> _ancestorObservers = {};

  /// Subscribe [AutoRouteAware] to be informed about changes to [route].
  ///
  /// Going forward, [AutoRouteAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  ///
  /// When [route] is inside a nested router, [AutoRouteAware] is also informed
  /// while [route] shows inside its host route, when the host route is covered,
  /// uncovered or popped in an ancestor navigator that has an [AutoRouteObserver].
  void subscribe(AutoRouteAware routeAware, RouteData<dynamic> route) {
    final subscribers = _listeners.putIfAbsent(route.key, () => <AutoRouteAware>{});
    if (subscribers.add(routeAware)) {
      _subscribeToAncestors(routeAware, route);
      final router = route.router;
      if (router is TabsRouter) {
        final previousIndex = router.previousIndex;
        if (previousIndex != null && previousIndex >= 0 && previousIndex < router.stackData.length) {
          final previousRoute = TabPageRoute(routeInfo: router.stackData[previousIndex].route, index: previousIndex);
          routeAware.didInitTabRoute(previousRoute);
        } else {
          routeAware.didInitTabRoute(null);
        }
      } else {
        routeAware.didPush();
        // A page built while covered, as under a deep link's top page, missed
        // the push that covered it: the navigator reported it before this
        // page existed to subscribe.
        if (_isCovered(routeAware, route)) routeAware.didPushNext();
      }
    }
  }

  // Whether another page covers [route] in its own router, or covers a host
  // route of it in an ancestor router whose observer tells [routeAware] when
  // that host shows again.
  bool _isCovered(AutoRouteAware routeAware, RouteData<dynamic> route) {
    if (_isBelowTop(route)) return true;
    final ancestorObservers = _ancestorObservers[routeAware] ?? const <AutoRouteObserver>{};
    for (var host = route.parent; host != null && host.parent != null; host = host.parent) {
      if (!_isBelowTop(host)) continue;
      final hostKey = host.key;
      if (ancestorObservers.any((observer) => observer._nestedListeners[hostKey]?.containsKey(routeAware) ?? false)) {
        return true;
      }
    }
    return false;
  }

  static bool _isBelowTop(RouteData<dynamic> route) {
    final router = route.router;
    return router is StackRouter && router.stackData.isNotEmpty && router.stackData.last.key != route.key;
  }

  /// Unsubscribe [AutoRouteAware].
  ///
  /// [AutoRouteAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.

  void unsubscribe(AutoRouteAware routeAware) {
    for (final route in _listeners.keys) {
      final subscribers = _listeners[route];
      subscribers?.remove(routeAware);
    }
    for (final observer in _ancestorObservers.remove(routeAware) ?? const <AutoRouteObserver>{}) {
      for (final nestedSubscribers in observer._nestedListeners.values) {
        nestedSubscribers.remove(routeAware);
      }
    }
  }

  // Adds [routeAware] to the observers of the navigators that hold the host
  // routes of [route], so it hears when one of them is covered or uncovered.
  void _subscribeToAncestors(AutoRouteAware routeAware, RouteData<dynamic> route) {
    // The root router's own route data has no parent and no navigator around it.
    for (var host = route.parent; host != null && host.parent != null; host = host.parent) {
      final router = host.router;
      if (router is! StackRouter) continue;
      final observers = router.navigatorKey.currentState?.widget.observers ?? const <NavigatorObserver>[];
      for (final observer in observers.whereType<AutoRouteObserver>()) {
        if (identical(observer, this)) continue;
        observer._nestedListeners.putIfAbsent(host.key, () => {})[routeAware] = route;
        _ancestorObservers.putIfAbsent(routeAware, () => {}).add(observer);
      }
    }
  }

  // Calls [notify] for each subscriber of a route that shows inside the route
  // with [hostKey], skipping those covered in their own router or in an
  // inactive tab.
  void _notifyNested(LocalKey hostKey, void Function(AutoRouteAware routeAware) notify) {
    final nestedSubscribers = _nestedListeners[hostKey];
    if (nestedSubscribers == null) return;
    for (final MapEntry(key: routeAware, value: route) in nestedSubscribers.entries.toList()) {
      if (_showsInHost(route, hostKey)) notify(routeAware);
    }
  }

  static bool _showsInHost(RouteData<dynamic> route, LocalKey hostKey) {
    for (RouteData<dynamic>? data = route; data != null && data.key != hostKey; data = data.parent) {
      if (data.router.currentChild?.matchId != data.matchId) return false;
    }
    return true;
  }

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    final subscribers = _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final routeAware in subscribers) {
        routeAware.didInitTabRoute(previousRoute);
      }
    }
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    final subscribers = _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final routeAware in subscribers) {
        routeAware.didChangeTabRoute(previousRoute);
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notifyPop(route, previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // navigate() and popUntil() remove a page instead of popping it when, for
    // example, a dialog above it is still closing. When that shows the route
    // underneath again, its subscribers hear what a pop would tell them.
    if (previousRoute != null && previousRoute.isCurrent) {
      _notifyPop(route, previousRoute);
    }
  }

  void _notifyPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is AutoRoutePage && previousRoute?.settings is AutoRoutePage) {
      // The page that leaves hears first, then the page that shows again, as
      // on a push, where the covered page hears didPushNext before the new
      // page subscribes and hears didPush.
      final key = (route.settings as AutoRoutePage).routeKey;
      final subscribers = _listeners[key]?.toList();

      if (subscribers != null) {
        for (final routeAware in subscribers) {
          routeAware.didPop();
        }
      }
      _notifyNested(key, (routeAware) => routeAware.didPop());

      final previousKey = (previousRoute!.settings as AutoRoutePage).routeKey;
      final previousSubscribers = _listeners[previousKey]?.toList();

      if (previousSubscribers != null) {
        for (final routeAware in previousSubscribers) {
          routeAware.didPopNext();
        }
      }
      _notifyNested(previousKey, (routeAware) => routeAware.didPopNext());
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is AutoRoutePage && previousRoute?.settings is AutoRoutePage) {
      final previousKey = (previousRoute!.settings as AutoRoutePage).routeKey;
      final previousSubscribers = _listeners[previousKey];

      if (previousSubscribers != null) {
        for (final routeAware in previousSubscribers) {
          routeAware.didPushNext();
        }
      }
      _notifyNested(previousKey, (routeAware) => routeAware.didPushNext());
    }
  }
}

/// Holds information of Tab-init and Tab-changed events
/// used in [AutoRouteAware] and [AutoRouterObserver]
class TabPageRoute {
  /// default constructor
  const TabPageRoute({required this.routeInfo, required this.index});

  /// match information of the target tab
  final RouteMatch<dynamic> routeInfo;

  /// index of the target tab
  final int index;

  /// helper getter to access [RouteMatch.name]
  String get name => routeInfo.name;

  /// helper getter to access [RouteMatch.path]
  String get path => routeInfo.path;

  /// helper getter to access [RouteMatch.stringMatch]
  String get match => routeInfo.stringMatch;
}
