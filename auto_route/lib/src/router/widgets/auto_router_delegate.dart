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

  @override
  Future<bool> popRoute() {
    return SynchronousFuture<bool>(controller.pop());
  }
}

class RootRouterDelegate extends RouterDelegate<List<PageRouteInfo>>
    with ChangeNotifier, AutoRouterDelegate<List<PageRouteInfo>> {
  final List<PageRouteInfo> defaultHistory;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackRouter controller;
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
    return StackRouterScope(
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

class InnerRouterDelegate extends RouterDelegate with ChangeNotifier, AutoRouterDelegate {
  final RootRouterDelegate rootDelegate;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackRouter controller;
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

    return builder == null
        ? content
        : LayoutBuilder(
            builder: (ctx, _) => builder(ctx, content),
          );
  }

  void pushInitialRoutes(List<PageRouteInfo> routes) {
    if (controller.hasEntries) {
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
              defaultConfig.name,
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
  final StackRouter controller;
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
  final TabsRouter controller;
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
    controller.setupRoutes(routes);
  }

  @override
  Widget build(BuildContext context) {
    var stack = controller.stack;
    final content = stack.isEmpty
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        : Stack(
            fit: StackFit.expand,
            children: List<Widget>.generate(stack.length, (int index) {
              final bool active = index == controller.activeIndex;
              final page = stack[index];
              return Offstage(
                offstage: !active,
                key: page.key,
                child: page.wrappedChild(context),
              );
            }),
          );

    return builder == null
        ? content
        : LayoutBuilder(
            builder: (ctx, _) => builder(ctx, content),
          );
  }

  @override
  Future<bool> popRoute() {
    return SynchronousFuture<bool>(controller.topMost.pop());
  }

  @override
  Future<void> setNewRoutePath(_) {
    assert(false);
    return SynchronousFuture(null);
  }
}
