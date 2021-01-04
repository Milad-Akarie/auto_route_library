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
    this.initialDeepLink,
    this.navigatorObservers = const [],
  })  : assert(initialDeepLink == null || initialRoutes == null),
        assert(controller != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    controller.addListener(notifyListeners);
  }

  @override
  List<PageRouteInfo> get currentConfiguration {
    var route = controller.topMost.currentRoute;
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
        child: !controller.hasEntries
            ? Container(color: Colors.white)
            : Navigator(
                key: controller.navigatorKey,
                pages: controller.stack,
                observers: navigatorObservers,
                onPopPage: (route, result) {
                  if (!route.didPop(result)) {
                    return false;
                  }
                  controller.removeLast();
                  return true;
                },
              ),
      ),
    );
  }
}
