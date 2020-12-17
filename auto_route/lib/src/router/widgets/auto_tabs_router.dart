import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:flutter/material.dart';

import '../controller/routing_controller.dart';
import 'auto_router_delegate.dart';

class AutoTabsRouter extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, Widget widget) builder;
  final List<PageRouteInfo> routes;

  const AutoTabsRouter({
    Key key,
    this.routes,
    this.navigatorObservers = const [],
    this.builder,
  }) : super(key: key);

  @override
  AutoTabsRouterState createState() => AutoTabsRouterState();
  static TabsRouter of(BuildContext context) {
    var scope = TabsRoutingControllerScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoTabsRouter operation requested with a context that does not include an AutoTabsRouter.\n'
            'The context used to retrieve the AutoTabsRouter must be that of a widget that '
            'is a descendant of an AutoTabsRouter widget.');
      }
      return true;
    }());
    return scope.controller;
  }
}

class AutoTabsRouterState extends State<AutoTabsRouter> {
  ChildBackButtonDispatcher _backButtonDispatcher;
  AutoRouterDelegate _routerDelegate;

  TabsRouter get controller => _routerDelegate?.controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routerDelegate == null) {
      final router = Router.of(context);
      assert(router != null);
      _backButtonDispatcher = router.backButtonDispatcher.createChildBackButtonDispatcher();

      assert(router.routerDelegate is AutoRouterDelegate);
      final autoRouterDelegate = (router.routerDelegate as AutoRouterDelegate);
      final parentData = RouteData.of(context);
      assert(parentData != null);
      final routingController = autoRouterDelegate.controller.routerOfRoute(parentData);
      assert(routingController != null);

      _routerDelegate = TabsRouterDelegate(
        controller: routingController,
        builder: widget.builder,
        tabRoutes: List.from(widget.routes),
        rootDelegate: autoRouterDelegate.rootDelegate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: _routerDelegate,
      backButtonDispatcher: _backButtonDispatcher..takePriority(),
    );
  }
}
