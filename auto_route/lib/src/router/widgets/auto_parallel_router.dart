import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:flutter/material.dart';

import '../controller/routing_controller.dart';
import 'auto_router_delegate.dart';

class AutoParallelRouter extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, Widget widget) builder;
  final List<PageRouteInfo> routes;

  const AutoParallelRouter({
    Key key,
    this.routes,
    this.navigatorObservers = const [],
    this.builder,
  }) : super(key: key);

  @override
  AutoParallelRouterState createState() => AutoParallelRouterState();

  static ParallelRouterNode of(BuildContext context) {
    var scope = ParallelRoutingControllerScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoParallelRouter operation requested with a context that does not include an AutoParallelRouter.\n'
            'The context used to retrieve the Router must be that of a widget that '
            'is a descendant of an AutoParallelRouter widget.');
      }
      return true;
    }());
    return scope.routerNode;
  }
}

class AutoParallelRouterState extends State<AutoParallelRouter> {
  ChildBackButtonDispatcher _backButtonDispatcher;
  AutoRouterDelegate _routerDelegate;

  RoutingController get controller => _routerDelegate?.routerNode;

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
      final routerNode = autoRouterDelegate.routerNode.routerOf(parentData);
      assert(routerNode != null);

      _routerDelegate = ParallelRouterDelegate(
        routerNode: routerNode,
        builder: widget.builder,
        // navigatorObservers: widget.navigatorObservers,
        // parallelRoutes: List.from(widget.routes),
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
