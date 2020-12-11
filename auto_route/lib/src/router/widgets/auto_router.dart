import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../controller/routing_controller.dart';
import 'auto_router_delegate.dart';

class AutoRouter extends StatefulWidget {
  final List<PageRouteInfo> Function(BuildContext context, List<PageRouteInfo> routes) onGenerateRoutes;
  final bool isDeclarative;
  final Function(PageRouteInfo route) onPopRoute;

  const AutoRouter({Key key})
      : isDeclarative = false,
        onGenerateRoutes = null,
        onPopRoute = null,
        super(key: key);

  const AutoRouter.declarative({
    Key key,
    @required this.onGenerateRoutes,
    this.onPopRoute,
  })  : isDeclarative = true,
        super(key: key);

  @override
  _AutoRouterState createState() => _AutoRouterState();

  static RoutingController of(BuildContext context) {
    var scope = RoutingControllerScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError('AutoRouter operation requested with a context that does not include an AutoRouter.\n'
            'The context used to retrieve the Router must be that of a widget that '
            'is a descendant of an AutoRouter widget.');
      }
      return true;
    }());

    return RoutingControllerScope.of(context).routerNode;
  }

  static RoutingController ofChildRoute(BuildContext context, String routeKey) {
    return of(context)?.findRouterOf(routeKey);
  }
}

class _AutoRouterState extends State<AutoRouter> {
  ChildBackButtonDispatcher _backButtonDispatcher;
  RouterDelegate _routerDelegate;
  List<PageRouteInfo> _routes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var router = Router.of(context);
    assert(router != null);
    _backButtonDispatcher = router.backButtonDispatcher.createChildBackButtonDispatcher();

    if (_routerDelegate == null) {
      assert(router.routerDelegate is AutoRouterDelegate);
      var autoRouterDelegate = (router.routerDelegate as AutoRouterDelegate);
      var parentData = RouteData.of(context);
      assert(parentData != null);
      RouterNode routerNode = autoRouterDelegate.routerNode.routerOf(parentData);
      assert(routerNode != null);
      if (widget.isDeclarative) {
        _routes = routerNode.preMatchedRoutes;
        _routerDelegate = DeclarativeRouterDelegate(
          routerNode: routerNode,
          routes: widget.onGenerateRoutes(context, _routes),
          onPopRoute: widget.onPopRoute,
          rootDelegate: autoRouterDelegate.rootDelegate,
        );
      } else {
        _routerDelegate = InnerRouterDelegate(
          routerNode: routerNode,
          defaultRoutes: routerNode.preMatchedRoutes,
          rootDelegate: autoRouterDelegate.rootDelegate,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_backButtonDispatcher);
    return Router(
      routerDelegate: _routerDelegate,
      backButtonDispatcher: _backButtonDispatcher..takePriority(),
    );
  }

  @override
  void didUpdateWidget(covariant AutoRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeclarative) {
      var newRoutes = widget.onGenerateRoutes(context, _routes);
      if (!ListEquality().equals(newRoutes, _routes)) {
        _routes = newRoutes;
        (_routerDelegate as DeclarativeRouterDelegate).updateRoutes(newRoutes);
      }
    }
  }
}
