import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils.dart';
import '../controller/routing_controller.dart';
import 'auto_route_navigator.dart';

typedef RoutesBuilder = List<PageRouteInfo> Function(BuildContext context);
typedef RoutePopCallBack = void Function(PageRouteInfo route);
typedef PreMatchedRoutesCallBack = void Function(List<PageRouteInfo> routes);
typedef NavigatorObserversBuilder = List<NavigatorObserver> Function();

class CurrentConfigNotifier extends ValueNotifier<PageRouteInfo?> {
  CurrentConfigNotifier() : super(null);
}

class AutoRouterDelegate extends RouterDelegate<List<PageRouteInfo>> with ChangeNotifier {
  final List<PageRouteInfo>? initialRoutes;
  final GlobalKey<NavigatorState> navigatorKey;
  final StackRouter controller;
  final String? initialDeepLink;
  final String? navRestorationScopeId;
  final NavigatorObserversBuilder navigatorObservers;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with [Theme.scaffoldBackgroundColor].
  WidgetBuilder? placeholder;

  static List<NavigatorObserver> defaultNavigatorObserversBuilder() => const [];

  static AutoRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is AutoRouterDelegate);
    return delegate as AutoRouterDelegate;
  }

  @override
  Future<bool> popRoute() => controller.topMost.pop();

  late List<NavigatorObserver> _navigatorObservers;
  AutoRouterDelegate(
    this.controller, {
    this.initialRoutes,
    this.placeholder,
    GlobalKey<NavigatorState>? navigatorKey,
    this.navRestorationScopeId,
    this.initialDeepLink,
    this.navigatorObservers = defaultNavigatorObserversBuilder,
  })  : assert(initialDeepLink == null || initialRoutes == null),
        this.navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    _navigatorObservers = navigatorObservers();
    controller.addListener(notifyListeners);
  }

  factory AutoRouterDelegate.declarative(
    StackRouter controller, {
    GlobalKey<NavigatorState>? navigatorKey,
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    RoutePopCallBack? onPopRoute,
    PreMatchedRoutesCallBack? onInitialRoutes,
    NavigatorObserversBuilder navigatorObservers,
  }) = _DeclarativeAutoRouterDelegate;

  @override
  List<PageRouteInfo>? get currentConfiguration {
    // print("Current -----> ${controller.current.hashCode}");
    // print(controller.topMost.routeData.breadcrumbs.map((e) => e.routeName));

    print(controller.currentConfig.map((e) => e.routeName));
    return controller.currentConfig;
    // print("Current route -----> ${controller.current.route.fullPath}");
    // print('getting current config ${controller.topMost}');
    //
    // var route = controller.topMost.current;
    // if (route == null) {
    //   return null;
    // }
    // // print(controller.currentConfig.map((e) => e.routeName));
    // // return controller.currentConfig;
    // return route.breadcrumbs.map((e) => e.route).toList(growable: false);
  }

  @override
  Future<void> setInitialRoutePath(List<PageRouteInfo> routes) {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.hasEntries) {
      return SynchronousFuture(null);
    }

    if (initialRoutes?.isNotEmpty == true) {
      controller.configNotifier.value = initialRoutes!.last;
      return controller.pushAll(initialRoutes!);
    } else if (initialDeepLink != null) {
      return controller.pushPath(initialDeepLink!, includePrefixMatches: true);
    } else if (!listNullOrEmpty(routes)) {
      controller.configNotifier.value = routes.last;
      return controller.pushAll(routes);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  @override
  Future<void> setNewRoutePath(List<PageRouteInfo> routes) {
    if (routes.isNotEmpty) {
      return controller.rebuildRoutesFromUrl(routes);
    }
    controller.configNotifier.value = routes.last;
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    return RoutingControllerScope(
      controller: controller,
      navigatorObservers: navigatorObservers,
      child: StackRouterScope(
        controller: controller,
        child: AutoRouteNavigator(
          router: controller,
          placeholder: placeholder,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
        ),
      ),
    );
  }
}

class _DeclarativeAutoRouterDelegate extends AutoRouterDelegate {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final PreMatchedRoutesCallBack? onInitialRoutes;

  _DeclarativeAutoRouterDelegate(
    StackRouter controller, {
    GlobalKey<NavigatorState>? navigatorKey,
    required this.routes,
    String? navRestorationScopeId,
    this.onPopRoute,
    this.onInitialRoutes,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) : super(
          controller,
          navigatorKey: navigatorKey,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: navigatorObservers,
        );

  @override
  Future<void> setInitialRoutePath(List<PageRouteInfo> routes) {
    onInitialRoutes?.call(routes);
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    controller.updateDeclarativeRoutes(routes(context));

    return RoutingControllerScope(
      controller: controller,
      navigatorObservers: navigatorObservers,
      child: AutoRouteNavigator(
        router: controller,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: _navigatorObservers,
        didPop: onPopRoute,
      ),
    );
  }
}
