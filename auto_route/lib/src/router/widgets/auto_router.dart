import 'package:auto_route/src/route/route_data_scope.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';
import '../controller/routing_controller.dart';
import 'auto_route_navigator.dart';

class AutoRouter extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, Widget content)? builder;
  final String? navRestorationScopeId;

  const AutoRouter({
    Key? key,
    this.navigatorObservers = const [],
    this.builder,
    this.navRestorationScopeId,
  }) : super(key: key);

  static Widget declarative({
    Key? key,
    List<NavigatorObserver> navigatorObservers = const [],
    required RoutesBuilder routes,
    RoutePopCallBack? onPopRoute,
    PreMatchedRoutesCallBack? onInitialRoutes,
    String? navRestorationScopeId,
  }) =>
      _DeclarativeAutoRouter(
        onPopRoute: onPopRoute,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
        routes: routes,
      );

  @override
  AutoRouterState createState() => AutoRouterState();

  static StackRouter of(BuildContext context) {
    var scope = StackRouterScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError('AutoRouter operation requested with a context that does not include an AutoRouter.\n'
            'The context used to retrieve the Router must be that of a widget that '
            'is a descendant of an AutoRouter widget.');
      }
      return true;
    }());
    return scope!.controller;
  }

  static StackRouter? innerRouterOf(BuildContext context, String routeName) {
    return of(context).innerRouterOf<StackRouter>(routeName);
  }
}

class AutoRouterState extends State<AutoRouter> {
  StackRouter? _controller;

  StackRouter? get controller => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parent = RoutingControllerScope.of(context);
      final parentRoute = RouteDataScope.of(context);
      _controller = parent.findOrCreateChildController<StackRouter>(parentRoute) as StackRouter;
      // var rootDelegate = AutoRouterDelegate.of(context);
      _controller!.addListener(_rebuildListener);
    }
  }

  void _rebuildListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    var navigator = AutoRouteNavigator(
      router: _controller!,
      navRestorationScopeId: widget.navRestorationScopeId,
      navigatorObservers: widget.navigatorObservers,
    );
    return RoutingControllerScope(
      controller: _controller!,
      child: StackRouterScope(
        controller: _controller!,
        child: widget.builder == null
            ? navigator
            : Builder(
                builder: (ctx) => widget.builder!(ctx, navigator),
              ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // _controller?.removeListener(_rebuildListener);
    // _controller?.dispose();
    // _controller = null;
  }
}

typedef RoutesGenerator = List<PageRouteInfo> Function(BuildContext context, List<PageRouteInfo> routes);

class _DeclarativeAutoRouter extends StatefulWidget {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final PreMatchedRoutesCallBack? onInitialRoutes;
  final List<NavigatorObserver> navigatorObservers;
  final String? navRestorationScopeId;

  const _DeclarativeAutoRouter({
    Key? key,
    required this.routes,
    this.navigatorObservers = const [],
    this.onPopRoute,
    this.onInitialRoutes,
    this.navRestorationScopeId,
  }) : super(key: key);

  @override
  _DeclarativeAutoRouterState createState() => _DeclarativeAutoRouterState();
}

class _DeclarativeAutoRouterState extends State<_DeclarativeAutoRouter> {
  late List<PageRouteInfo> _routes;
  StackRouter? _controller;
  late HeroController _heroController;

  StackRouter? get controller => _controller;

  @override
  void initState() {
    super.initState();
    _heroController = HeroController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parent = RoutingControllerScope.of(context);
      final parentRoute = RouteDataScope.of(context);
      _controller = parent.findOrCreateChildController<StackRouter>(parentRoute) as StackRouter;
      assert(_controller != null);
      widget.onInitialRoutes?.call(_controller!.preMatchedRoutes ?? const []);
      _routes = widget.routes(context);
      _controller!.updateDeclarativeRoutes(_routes);
      var rootDelegate = AutoRouterDelegate.of(context);
      _controller!.addListener(() {
        rootDelegate.notify(_controller!);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    return RoutingControllerScope(
      controller: _controller!,
      child: HeroControllerScope(
        controller: _heroController,
        child: AutoRouteNavigator(
          router: _controller!,
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: widget.navigatorObservers,
          didPop: (route) {
            widget.onPopRoute?.call(route);
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _DeclarativeAutoRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    var newRoutes = widget.routes(context);
    if (!ListEquality().equals(newRoutes, _routes)) {
      _routes = newRoutes;
      (_controller as BranchEntry).updateDeclarativeRoutes(newRoutes);
    }
  }
}

class EmptyRouterPage extends AutoRouter {
  const EmptyRouterPage({Key? key}) : super(key: key);
}
