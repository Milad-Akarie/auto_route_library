import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class AutoRouterObserver extends NavigatorObserver {
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {}
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {}
}

final observer = RouteObserver();

abstract class AutoRouteAware {
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

  // called when a tab route actives
  void didInitTabRoute(TabPageRoute? previousRoute) {}
  // called when tab route reactivates
  void didChangeTabRoute(TabPageRoute previousRoute) {}
}

class AutoRouteObserver extends AutoRouterObserver {
  final Map<LocalKey, Set<AutoRouteAware>> _listeners =
      <LocalKey, Set<AutoRouteAware>>{};

  /// Subscribe [routeAware] to be informed about changes to [route].
  ///
  /// Going forward, [routeAware] will be informed about qualifying changes
  /// to [route], e.g. when [route] is covered by another route or when [route]
  /// is popped off the [Navigator] stack.
  void subscribe(AutoRouteAware routeAware, RouteData route) {
    final Set<AutoRouteAware> subscribers =
        _listeners.putIfAbsent(route.key, () => <AutoRouteAware>{});
    if (subscribers.add(routeAware)) {
      if (route.router is TabsRouter) {
        routeAware.didInitTabRoute(null);
      } else {
        routeAware.didPush();
      }
    }
  }

  /// Unsubscribe [routeAware].
  ///
  /// [routeAware] is no longer informed about changes to its route. If the given argument was
  /// subscribed to multiple types, this will unregister it (once) from each type.

  void unsubscribe(AutoRouteAware routeAware) {
    for (final route in _listeners.keys) {
      final Set<AutoRouteAware>? subscribers = _listeners[route];
      subscribers?.remove(routeAware);
    }
  }

  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    final List<AutoRouteAware>? subscribers =
        _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final AutoRouteAware routeAware in subscribers) {
        routeAware.didInitTabRoute(previousRoute);
      }
    }
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    final List<AutoRouteAware>? subscribers =
        _listeners[route.routeInfo.key]?.toList();
    if (subscribers != null) {
      for (final AutoRouteAware routeAware in subscribers) {
        routeAware.didChangeTabRoute(previousRoute);
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is AutoRoutePage &&
        previousRoute?.settings is AutoRoutePage) {
      final previousKey = (previousRoute!.settings as AutoRoutePage).routeKey;
      final List<AutoRouteAware>? previousSubscribers =
          _listeners[previousKey]?.toList();

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
    if (route.settings is AutoRoutePage &&
        previousRoute?.settings is AutoRoutePage) {
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

class TabPageRoute {
  final RouteMatch routeInfo;

  final int index;
  const TabPageRoute({
    required this.routeInfo,
    required this.index,
  });

  String get name => routeInfo.routeName;
  String get path => routeInfo.path;
  String get match => routeInfo.stringMatch;
}
