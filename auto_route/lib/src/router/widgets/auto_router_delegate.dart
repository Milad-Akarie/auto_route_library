import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:auto_route/src/router/auto_router_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';
import '../auto_router_config.dart';
import '../controller/routing_controller.dart';

mixin AutoRouterDelegate<T> on RouterDelegate<T> {
  RootRouterDelegate get rootDelegate;

  RoutingController get controller;
}

class RootRouterDelegate extends RouterDelegate<List<PageRouteInfo>>
    with ChangeNotifier, AutoRouterDelegate<List<PageRouteInfo>>, PopNavigatorRouterDelegateMixin<List<PageRouteInfo>> {
  final List<PageRouteInfo> defaultHistory;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackController controller;
  final String initialDeepLink;
  final List<NavigatorObserver> navigatorObservers;

  RootRouterDelegate(
    AutoRouterConfig routerConfig, {
    this.defaultHistory,
    this.initialDeepLink,
    this.navigatorObservers = const [],
  })  : assert(initialDeepLink == null || defaultHistory == null),
        assert(routerConfig != null),
        controller = routerConfig.root,
        navigatorKey = GlobalKey<NavigatorState>() {
    controller.addListener(notifyListeners);
  }

  @override
  List<PageRouteInfo> get currentConfiguration {
    var route = controller.topMost.currentRoute;
    if (route == null) {
      return null;
    }
    return route.breadcrumbs.map((d) => d.route).toList(growable: false);
  }

  @override
  Future<void> setInitialRoutePath(List<PageRouteInfo> routes) {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.stack.isEmpty) {
      return SynchronousFuture(null);
    }

    if (!listNullOrEmpty(defaultHistory)) {
      return controller.pushAll(defaultHistory);
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
      return controller.pushAll(routes);
    }
    return SynchronousFuture(null);
  }

  @override
  RootRouterDelegate get rootDelegate => this;

  @override
  Widget build(BuildContext context) {
    return StackControllerScope(
      controller: controller,
      child: !controller.hasEntries
          ? Container(color: Colors.white)
          : Navigator(
              key: navigatorKey,
              pages: controller.stack,
              observers: navigatorObservers,
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }
                controller.pop();
                return true;
              },
            ),
    );
  }
}

class InnerRouterDelegate extends RouterDelegate
    with ChangeNotifier, PopNavigatorRouterDelegateMixin, AutoRouterDelegate {
  final RootRouterDelegate rootDelegate;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackController controller;
  final Widget Function(BuildContext context, Widget widget) builder;

  final List<NavigatorObserver> navigatorObservers;

  InnerRouterDelegate({
    this.rootDelegate,
    this.controller,
    this.builder,
    this.navigatorObservers,
    List<PageRouteInfo> defaultRoutes,
  })  : assert(controller != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    controller.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });
    pushInitialRoutes(defaultRoutes);
  }

  @override
  Widget build(BuildContext context) {
    var content = !controller.hasEntries
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        : Navigator(
            key: navigatorKey,
            pages: controller.stack,
            observers: navigatorObservers,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              controller.pop();
              return true;
            },
          );

    return StackControllerScope(
      controller: controller,
      child: builder == null
          ? content
          : LayoutBuilder(
              builder: (ctx, _) => builder(ctx, content),
            ),
    );
  }

  void pushInitialRoutes(List<PageRouteInfo> routes) {
    if (!controller.hasEntries) {
      return;
    }
    if (!listNullOrEmpty(controller.preMatchedRoutes)) {
      controller.pushAll(controller.preMatchedRoutes);
    } else if (!listNullOrEmpty(routes)) {
      controller.pushAll(routes);
    } else {
      var defaultConfig = controller.routeCollection.configWithPath('');
      if (defaultConfig != null) {
        if (defaultConfig.isRedirect) {
          controller.pushPath(defaultConfig.redirectTo);
        } else {
          controller.push(
            PageRouteInfo(
              defaultConfig.key,
              path: defaultConfig.path,
            ),
          );
        }
      }
    }
  }

  @override
  Future<void> setNewRoutePath(configuration) {
    assert(false);
    return SynchronousFuture(null);
  }
}

class DeclarativeRouterDelegate extends RouterDelegate
    with ChangeNotifier, PopNavigatorRouterDelegateMixin, AutoRouterDelegate {
  final RootRouterDelegate rootDelegate;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackController controller;
  final Function(PageRouteInfo route) onPopRoute;
  final List<NavigatorObserver> navigatorObservers;

  DeclarativeRouterDelegate({
    this.rootDelegate,
    this.controller,
    this.navigatorObservers,
    @required this.onPopRoute,
    List<PageRouteInfo> routes,
  })  : assert(controller != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    controller.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });
    updateRoutes(routes);
  }

  @override
  Widget build(BuildContext context) {
    return !controller.hasEntries
        ? Container(color: Colors.white)
        : Navigator(
            key: navigatorKey,
            pages: controller.stack,
            observers: navigatorObservers,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              var data = (route.settings as AutoRoutePage).data;
              controller.pop();
              onPopRoute?.call(data.route);
              return true;
            },
          );
  }

  void updateRoutes(List<PageRouteInfo> routes) {
    if (!listNullOrEmpty(routes)) {
      // controller.updateDeclarativeRoutes(routes, notify: false);
    }
  }

  @override
  Future<void> setNewRoutePath(configuration) {
    assert(false);
    return SynchronousFuture(null);
  }
}

class TabsRouterDelegate extends RouterDelegate with ChangeNotifier, AutoRouterDelegate {
  final RootRouterDelegate rootDelegate;
  final List<PageRouteInfo> tabRoutes;
  final TabsController controller;
  final Widget Function(BuildContext context, Widget widget) builder;

  TabsRouterDelegate({
    @required this.rootDelegate,
    @required this.tabRoutes,
    @required this.controller,
    this.builder,
  })  : assert(controller != null),
        assert(rootDelegate != null) {
    controller.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });

    setupRoutes(tabRoutes);
  }

  void setupRoutes(List<PageRouteInfo> routes) {
    List<PageRouteInfo> routesToPush = routes;
    if (!listNullOrEmpty(controller.preMatchedRoutes)) {
      for (var preMatchedRoute in controller.preMatchedRoutes) {
        var route = routes.firstWhere(
          (r) => r.path == preMatchedRoute.path,
          orElse: () {
            throw FlutterError('${preMatchedRoute.path} is not assign as a tab route');
          },
        );
        routesToPush.remove(route);
      }
      routesToPush.addAll(controller.preMatchedRoutes);
    }
    if (!listNullOrEmpty(routesToPush)) {
      controller.setupRoutes(routesToPush);
    }
  }

  @override
  Widget build(BuildContext context) {
    var stack = controller.stack;
    var keysList = tabRoutes.map((e) => e.routeKey).toList(growable: false);
    final content = stack.isEmpty
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        : Stack(
            fit: StackFit.expand,
            children: List<Widget>.generate(tabRoutes.length, (int index) {
              final bool active = keysList[index] == controller.currentRoute.key;
              var page = stack.firstWhere((p) => p.data.key == keysList[index]);
              return Offstage(
                offstage: !active,
                key: page.key,
                child: page.wrappedChild(context),
              );
            }),
          );

    return TabsRoutingControllerScope(
      controller: controller,
      child: builder == null
          ? content
          : LayoutBuilder(
              builder: (ctx, _) => builder(ctx, content),
            ),
    );
  }

  @override
  Future<bool> popRoute() async {
    var topMostRouter = controller.topMost;
    if (topMostRouter == null) return SynchronousFuture<bool>(false);
    return topMostRouter.pop();
  }

  @override
  Future<void> setNewRoutePath(configuration) {
    assert(false);
    return SynchronousFuture(null);
  }
}
