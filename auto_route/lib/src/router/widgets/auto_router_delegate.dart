import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils.dart';
import '../controller/routing_controller.dart';

class RootRouterDelegate extends RouterDelegate<List<PageRouteInfo>>
    with ChangeNotifier {
  final List<PageRouteInfo> initialRoutes;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackRouter controller;
  final String initialDeepLink;
  final String navRestorationScopeId;
  final List<NavigatorObserver> navigatorObservers;

  static RootRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is RootRouterDelegate);
    return delegate as RootRouterDelegate;
  }

  @override
  Future<bool> popRoute() {
    return controller.topMost.pop();
  }

  void notify() {
    notifyListeners();
  }

  RootRouterDelegate(
    this.controller, {
    this.initialRoutes,
    this.navRestorationScopeId,
    this.initialDeepLink,
    this.navigatorObservers = const [],
  })  : assert(initialDeepLink == null || initialRoutes == null),
        assert(controller != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    controller.addListener(notifyListeners);
  }

  @override
  List<PageRouteInfo> get currentConfiguration {
    var route = controller.topMost.current;
    if (route == null) {
      return null;
    }
    return route.breadcrumbs.map((e) => e.route).toList(growable: false);
  }

  @override
  Future<void> setInitialRoutePath(List<PageRouteInfo> routes) {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.hasEntries) {
      return SynchronousFuture(null);
    }

    if (!listNullOrEmpty(initialRoutes)) {
      return controller.pushAll(initialRoutes);
    } else if (initialDeepLink != null) {
      return controller.pushPath(initialDeepLink, includePrefixMatches: true);
    } else if (!listNullOrEmpty(routes)) {
      return controller.pushAll(routes);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  @override
  Future<void> setNewRoutePath(List<PageRouteInfo> routes) {
    if (!listNullOrEmpty(routes)) {
      return (controller as BranchEntry).updateOrReplaceRoutes(routes);
    }
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    return RoutingControllerScope(
      controller: controller,
      child: StackRouterScope(
          controller: controller,
          child: AutoRouteNavigator(
            router: controller,
            // navRestorationScopeId: navRestorationScopeId,
            navigatorObservers: navigatorObservers,
          )),
    );
  }
}

class AutoRouteNavigator extends StatelessWidget {
  final StackRouter router;
  // final String navRestorationScopeId;
  final List<NavigatorObserver> navigatorObservers;
  final void Function(Route route) didPop;

  const AutoRouteNavigator({
    @required this.router,
    @required this.navigatorObservers,
    // this.navRestorationScopeId,
    this.didPop,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Navigator(
        key: router.navigatorKey,
        observers: navigatorObservers,
        // restorationScopeId: navRestorationScopeId,
        pages: router.hasEntries ? router.stack : const [_PlaceHolderPage()],
        transitionDelegate: _CustomTransitionDelegate(),
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }
          router.removeLast();
          didPop?.call(route);
          return true;
        },
      );
}

class _PlaceHolderPage extends Page {
  const _PlaceHolderPage() : super(key: const ValueKey('_placeHolder_'));

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, __, ___) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

class _CustomTransitionDelegate extends TransitionDelegate {
  @override
  Iterable<RouteTransitionRecord> resolve(
      {List<RouteTransitionRecord> newPageRouteHistory,
      Map<RouteTransitionRecord, RouteTransitionRecord>
          locationToExitingPageRoute,
      Map<RouteTransitionRecord, List<RouteTransitionRecord>>
          pageRouteToPagelessRoutes}) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord location, bool isLast) {
      final RouteTransitionRecord exitingPageRoute =
          locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final bool hasPagelessRoute =
            pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        final bool isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute
              .markForComplete(exitingPageRoute.route.currentResult);
        }
        if (hasPagelessRoute) {
          final List<RouteTransitionRecord> pagelessRoutes =
              pageRouteToPagelessRoutes[exitingPageRoute];
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            assert(pagelessRoute.isWaitingForExitingDecision);
            if (isLastExitingPageRoute &&
                pagelessRoute == pagelessRoutes.last) {
              pagelessRoute.markForPop(pagelessRoute.route.currentResult);
            } else {
              pagelessRoute.markForComplete(pagelessRoute.route.currentResult);
            }
          }
        }
      }
      results.add(exitingPageRoute);

      // It is possible there is another exiting route above this exitingPageRoute.
      handleExitingRoute(exitingPageRoute, isLast);
    }

    // Handles exiting route in the beginning of list.
    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      final bool isLastIteration = newPageRouteHistory.last == pageRoute;
      final firstPageIsPlaceHolder = results.isNotEmpty &&
          results.first.route.settings is _PlaceHolderPage;
      if (pageRoute.isWaitingForEnteringDecision) {
        if (!locationToExitingPageRoute.containsKey(pageRoute) &&
            isLastIteration &&
            !firstPageIsPlaceHolder) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }
    return results;
  }
}
