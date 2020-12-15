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

  RouterNode get routerNode;
}

class RootRouterDelegate extends RouterDelegate<List<PageRouteInfo>>
    with ChangeNotifier, AutoRouterDelegate<List<PageRouteInfo>>, PopNavigatorRouterDelegateMixin<List<PageRouteInfo>> {
  final List<PageRouteInfo> defaultHistory;
  final GlobalKey<NavigatorState> navigatorKey;
  final RouterNode routerNode;
  final String initialDeepLink;
  final List<NavigatorObserver> navigatorObservers;

  RootRouterDelegate(
    AutoRouterConfig routerConfig, {
    this.defaultHistory,
    this.initialDeepLink,
    this.navigatorObservers = const [],
  })  : assert(initialDeepLink == null || defaultHistory == null),
        assert(routerConfig != null),
        routerNode = routerConfig.root,
        navigatorKey = GlobalKey<NavigatorState>() {
    routerNode.addListener(notifyListeners);
  }

  @override
  List<PageRouteInfo> get currentConfiguration {
    var route = routerNode.topMost.currentRoute;
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
    if (!routerNode.stackIsEmpty) {
      return SynchronousFuture(null);
    }

    if (!listNullOrEmpty(defaultHistory)) {
      return routerNode.pushAll(defaultHistory);
    } else if (initialDeepLink != null) {
      return routerNode.pushPath(initialDeepLink, includePrefixMatches: true);
    } else if (!listNullOrEmpty(routes)) {
      return routerNode.pushAll(routes);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  @override
  Future<void> setNewRoutePath(List<PageRouteInfo> routes) {
    if (!listNullOrEmpty(routes)) {
      return routerNode.pushAll(routes);
    }
    return SynchronousFuture(null);
  }

  @override
  RootRouterDelegate get rootDelegate => this;

  @override
  Widget build(BuildContext context) {
    return RoutingControllerScope(
      routerNode: routerNode,
      child: routerNode.stack.isEmpty
          ? Container(color: Colors.white)
          : Navigator(
              key: navigatorKey,
              pages: routerNode.stack,
              observers: navigatorObservers,
              onPopPage: (route, result) {
                if (!route.didPop(result)) {
                  return false;
                }
                routerNode.pop();
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
  final RouterNode routerNode;
  final Widget Function(BuildContext context, Widget widget) builder;

  final List<NavigatorObserver> navigatorObservers;

  InnerRouterDelegate({
    this.rootDelegate,
    this.routerNode,
    this.builder,
    this.navigatorObservers,
    List<PageRouteInfo> defaultRoutes,
  })  : assert(routerNode != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    routerNode.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });
    pushInitialRoutes(defaultRoutes);
  }

  @override
  Widget build(BuildContext context) {
    var navigator = routerNode.stack.isEmpty
        ? Container(color: Colors.white)
        : Navigator(
            key: navigatorKey,
            pages: routerNode.stack,
            observers: navigatorObservers,
            // restorationScopeId: routerNode.key,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              routerNode.pop();
              return true;
            },
          );

    return RoutingControllerScope(
      routerNode: routerNode,
      child: LayoutBuilder(builder: (ctx, _) => builder != null ? builder(ctx, navigator) : navigator),
    );
  }

  void pushInitialRoutes(List<PageRouteInfo> routes) {
    if (!routerNode.stackIsEmpty) {
      return;
    }
    if (!listNullOrEmpty(routerNode.preMatchedRoutes)) {
      routerNode.pushAll(routerNode.preMatchedRoutes);
    } else if (!listNullOrEmpty(routes)) {
      routerNode.pushAll(routes);
    } else {
      var defaultConfig = routerNode.routeCollection.configWithPath('');
      if (defaultConfig != null) {
        if (defaultConfig.isRedirect) {
          routerNode.pushPath(defaultConfig.redirectTo);
        } else {
          routerNode.push(
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
  final RouterNode routerNode;
  final Function(PageRouteInfo route) onPopRoute;
  final List<NavigatorObserver> navigatorObservers;

  DeclarativeRouterDelegate({
    this.rootDelegate,
    this.routerNode,
    this.navigatorObservers,
    @required this.onPopRoute,
    List<PageRouteInfo> routes,
  })  : assert(routerNode != null),
        navigatorKey = GlobalKey<NavigatorState>() {
    routerNode.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });
    updateRoutes(routes);
  }

  @override
  Widget build(BuildContext context) {
    return routerNode.stack.isEmpty
        ? Container(color: Colors.white)
        : Navigator(
            key: navigatorKey,
            pages: routerNode.stack,
            observers: navigatorObservers,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              var data = (route.settings as AutoRoutePage).data;
              routerNode.pop();
              onPopRoute?.call(data.route);
              return true;
            },
          );
  }

  void updateRoutes(List<PageRouteInfo> routes) {
    if (!listNullOrEmpty(routes)) {
      routerNode.updateDeclarativeRoutes(routes, notify: false);
    }
  }

  @override
  Future<void> setNewRoutePath(configuration) {
    assert(false);
    return SynchronousFuture(null);
  }
}

class ParallelRouterDelegate extends RouterDelegate with ChangeNotifier, AutoRouterDelegate {
  final RootRouterDelegate rootDelegate;
  final List<PageRouteInfo> parallelRoutes;
  final RouterNode routerNode;
  final Widget Function(BuildContext context, Widget widget) builder;
  final _bucket = PageStorageBucket();

  ParallelRouterDelegate({
    @required this.rootDelegate,
    @required this.parallelRoutes,
    @required this.routerNode,
    this.builder,
  })  : assert(routerNode != null),
        assert(rootDelegate != null) {
    routerNode.addListener(() {
      notifyListeners();
      rootDelegate.notifyListeners();
    });

    setupRoutes(parallelRoutes);
  }

  void setupRoutes(List<PageRouteInfo> routes) {
    List<PageRouteInfo> routesToPush = routes;
    if (!listNullOrEmpty(routerNode.preMatchedRoutes) && false) {
      for (var preMatchedRoute in routerNode.preMatchedRoutes) {
        var route = routes.firstWhere(
          (r) => r.path == preMatchedRoute.path,
          orElse: () {
            throw FlutterError('${preMatchedRoute.path} is not assign as a parallel route');
          },
        );
        routesToPush.remove(route);
      }
      routesToPush.addAll(routerNode.preMatchedRoutes);
    }
    if (!listNullOrEmpty(routesToPush)) {
      routerNode.replaceAll(routesToPush);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Bucket ${_bucket.hashCode}");
    var stack = routerNode.stack;
    // var activeIndex = 0;
    final content = stack.isEmpty
        ? Container(color: Theme.of(context).scaffoldBackgroundColor)
        // : PageStorage(
        //     bucket: _bucket,
        //     key: PageStorageKey(stack.last.data),
        //     child: stack.last.wrappedChild(context),
        //   );
        : Stack(
            fit: StackFit.expand,
            children: List<Widget>.generate(stack.length, (int index) {
              var keysList = stack.map((r) => r.data.key).toList(growable: false);

              final bool active = keysList[index] == routerNode.currentRoute.key;
              var page = routerNode.stack[index];
              assert(page != null);
              return Offstage(
                offstage: !active,
                key: page.key,
                child: PageStorage(
                  bucket: _bucket,
                  key: PageStorageKey(page.data),
                  child: page.wrappedChild(context),
                ),
              );
            }),
          );

    return RoutingControllerScope(
      routerNode: routerNode,
      child: LayoutBuilder(builder: (ctx, _) => builder != null ? builder(ctx, content) : content),
    );
  }

  @override
  Future<bool> popRoute() async {
    var activeRouter = routerNode.topMost;
    if (activeRouter == null) return SynchronousFuture<bool>(false);
    return activeRouter.pop();
  }

  @override
  Future<void> setNewRoutePath(configuration) {
    assert(false);
    return SynchronousFuture(null);
  }
}
