import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';
import '../controller/routing_controller.dart';

class AutoRouter extends StatefulWidget {
  final List<NavigatorObserver> navigatorObservers;
  final Widget Function(BuildContext context, Widget content) builder;
  // final String navRestorationScopeId;

  const AutoRouter({
    Key key,
    this.navigatorObservers = const [],
    this.builder,
    // this.navRestorationScopeId,
  }) : super(key: key);

  static Widget declarative(
          {Key key,
          @required RoutesGenerator onGenerateRoutes,
          Function(PageRouteInfo route) onPopRoute,
          // String navRestorationScopeId,
          List<NavigatorObserver> navigatorObservers = const []}) =>
      _DeclarativeAutoRouter(
        onGenerateRoutes: onGenerateRoutes,
        onPopRoute: onPopRoute,
        // navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
      );

  @override
  AutoRouterState createState() => AutoRouterState();

  static StackRouter of(BuildContext context) {
    var scope = StackRouterScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoRouter operation requested with a context that does not include an AutoRouter.\n'
            'The context used to retrieve the Router must be that of a widget that '
            'is a descendant of an AutoRouter widget.');
      }
      return true;
    }());
    return scope.controller;
  }

  static StackRouter innerRouterOf(BuildContext context, String routeName) {
    return of(context)?.innerRouterOf<StackRouter>(routeName);
  }
}

class AutoRouterState extends State<AutoRouter> {
  StackRouter _controller;
  StackRouter get controller => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final entry = StackEntryScope.of(context);
      assert(entry is RoutingController);
      _controller = entry as RoutingController;
      assert(_controller != null);
      var rootDelegate = RootRouterDelegate.of(context);
      _controller.addListener(() {
        rootDelegate.notify();
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    var navigator = AutoRouteNavigator(
      router: _controller,
      // navRestorationScopeId: widget.navRestorationScopeId,
      navigatorObservers: widget.navigatorObservers,
    );
    return RoutingControllerScope(
      controller: _controller,
      child: StackRouterScope(
        controller: _controller,
        child: widget.builder == null
            ? navigator
            : Builder(
                builder: (ctx) => widget.builder(ctx, navigator),
              ),
      ),
    );
  }
}

typedef RoutesGenerator = List<PageRouteInfo> Function(
    BuildContext context, List<PageRouteInfo> routes);

class _DeclarativeAutoRouter extends StatefulWidget {
  final RoutesGenerator onGenerateRoutes;
  final Function(PageRouteInfo route) onPopRoute;
  final List<NavigatorObserver> navigatorObservers;
  // final String navRestorationScopeId;

  const _DeclarativeAutoRouter({
    Key key,
    @required this.onGenerateRoutes,
    this.navigatorObservers = const [],
    this.onPopRoute,
    // this.navRestorationScopeId,
  }) : super(key: key);

  @override
  _DeclarativeAutoRouterState createState() => _DeclarativeAutoRouterState();
}

class _DeclarativeAutoRouterState extends State<_DeclarativeAutoRouter> {
  List<PageRouteInfo> _routes;
  StackRouter _controller;

  StackRouter get controller => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final entry = StackEntryScope.of(context);
      assert(entry is StackRouter);
      _controller = entry as StackRouter;
      assert(_controller != null);
      _routes = widget.onGenerateRoutes(context, _controller.preMatchedRoutes);
      (_controller as BranchEntry).updateDeclarativeRoutes(_routes);
      var rootDelegate = RootRouterDelegate.of(context);

      _controller.addListener(() {
        rootDelegate.notify();
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);

    var navigator = AutoRouteNavigator(
      router: _controller,
      // navRestorationScopeId: widget.navRestorationScopeId,
      navigatorObservers: widget.navigatorObservers,
      didPop: (route) {
        widget.onPopRoute
            ?.call((route.settings as AutoRoutePage).routeData.route);
      },
    );
    return RoutingControllerScope(
      controller: _controller,
      child: navigator,
    );
  }

  @override
  void didUpdateWidget(covariant _DeclarativeAutoRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    var newRoutes = widget.onGenerateRoutes(context, _routes);
    if (!ListEquality().equals(newRoutes, _routes)) {
      _routes = newRoutes;
      (_controller as BranchEntry).updateDeclarativeRoutes(newRoutes);
    }
  }
}

class EmptyRouterPage extends AutoRouter {
  const EmptyRouterPage({Key key}) : super(key: key);
}
