import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoRouter extends StatefulWidget {
  final NavigatorObserversBuilder navigatorObservers;
  final Widget Function(BuildContext context, Widget content)? builder;
  final String? navRestorationScopeId;
  final bool inheritNavigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final WidgetBuilder? placeholder;

  const AutoRouter({
    Key? key,
    this.navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.builder,
    this.navRestorationScopeId,
    this.navigatorKey,
    this.inheritNavigatorObservers = true,
    this.placeholder,
  }) : super(key: key);

  static Widget declarative({
    Key? key,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    required RoutesBuilder routes,
    RoutePopCallBack? onPopRoute,
    String? navRestorationScopeId,
    bool inheritNavigatorObservers = true,
    GlobalKey<NavigatorState>? navigatorKey,
    OnNestedNavigateCallBack? onNavigate,
    WidgetBuilder? placeholder,
  }) =>
      _DeclarativeAutoRouter(
        onPopRoute: onPopRoute,
        navigatorKey: navigatorKey,
        navRestorationScopeId: navRestorationScopeId,
        navigatorObservers: navigatorObservers,
        inheritNavigatorObservers: inheritNavigatorObservers,
        onNavigate: onNavigate,
        placeholder: placeholder,
        routes: routes,
      );

  @override
  AutoRouterState createState() => AutoRouterState();

  static StackRouter of(BuildContext context, {bool watch = false}) {
    var scope = StackRouterScope.of(context, watch: watch);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoRouter operation requested with a context that does not include an AutoRouter.\n'
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
  late List<NavigatorObserver> _navigatorObservers;
  late NavigatorObserversBuilder _inheritableObserversBuilder;
  late RoutingController _parentController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parentRouteData = RouteData.of(context);
      final parentScope = RouterScope.of(context, watch: true);
      _inheritableObserversBuilder = () {
        var observers = widget.navigatorObservers();
        if (!widget.inheritNavigatorObservers) {
          return observers;
        }
        var inheritedObservers = parentScope.inheritableObserversBuilder();
        return inheritedObservers + observers;
      };
      _navigatorObservers = _inheritableObserversBuilder();
      _parentController = parentScope.controller;
      _controller = NestedStackRouter(
        parent: _parentController,
        key: parentRouteData.key,
        routeData: parentRouteData,
        navigatorKey: widget.navigatorKey,
        routeCollection: _parentController.routeCollection.subCollectionOf(
          parentRouteData.name,
        ),
        pageBuilder: _parentController.pageBuilder,
      );

      _parentController.attachChildController(_controller!);
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
      navigatorObservers: _navigatorObservers,
      placeholder: widget.placeholder,
    );
    final stateHash = controller!.stateHash;
    return RouterScope(
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      navigatorObservers: _navigatorObservers,
      stateHash: stateHash,
      child: StackRouterScope(
        controller: _controller!,
        stateHash: stateHash,
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
    if (_controller != null) {
      _controller!.removeListener(_rebuildListener);
      _controller!.dispose();
      _parentController.removeChildController(_controller!);
      _controller = null;
    }
  }
}

typedef RoutesGenerator = List<PageRouteInfo> Function(
    BuildContext context, List<PageRouteInfo> routes);

class _DeclarativeAutoRouter extends StatefulWidget {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final NavigatorObserversBuilder navigatorObservers;
  final String? navRestorationScopeId;
  final bool inheritNavigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final OnNestedNavigateCallBack? onNavigate;
  final WidgetBuilder? placeholder;

  const _DeclarativeAutoRouter({
    Key? key,
    required this.routes,
    this.navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.onPopRoute,
    this.navigatorKey,
    this.navRestorationScopeId,
    this.inheritNavigatorObservers = true,
    this.onNavigate,
    this.placeholder,
  }) : super(key: key);

  @override
  _DeclarativeAutoRouterState createState() => _DeclarativeAutoRouterState();
}

class _DeclarativeAutoRouterState extends State<_DeclarativeAutoRouter> {
  StackRouter? _controller;
  late HeroController _heroController;

  StackRouter? get controller => _controller;
  late List<NavigatorObserver> _navigatorObservers;
  late NavigatorObserversBuilder _inheritableObserversBuilder;
  late RoutingController _parentController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentData = RouteData.of(context);
    if (_controller == null) {
      _heroController = HeroController();
      final parentScope = RouterScope.of(context);
      _inheritableObserversBuilder = () {
        var observers = widget.navigatorObservers();
        if (!widget.inheritNavigatorObservers) {
          return observers;
        }
        var inheritedObservers = parentScope.inheritableObserversBuilder();
        return inheritedObservers + observers;
      };
      _navigatorObservers = _inheritableObserversBuilder();
      _parentController = parentScope.controller;
      _controller = NestedStackRouter(
          parent: _parentController,
          key: parentData.key,
          routeData: parentData,
          managedByWidget: true,
          onNavigate: widget.onNavigate,
          navigatorKey: widget.navigatorKey,
          routeCollection: _parentController.routeCollection.subCollectionOf(
            parentData.name,
          ),
          pageBuilder: _parentController.pageBuilder);
      _parentController.attachChildController(_controller!);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_controller != null) {
      _controller!.dispose();
      _parentController.removeChildController(_controller!);
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final stateHash = controller!.stateHash;

    return RouterScope(
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      navigatorObservers: _navigatorObservers,
      stateHash: stateHash,
      child: HeroControllerScope(
        controller: _heroController,
        child: AutoRouteNavigator(
          router: _controller!,
          declarativeRoutesBuilder: widget.routes,
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          didPop: widget.onPopRoute,
          placeholder: widget.placeholder,
        ),
      ),
    );
  }
}

class EmptyRouterPage extends AutoRouter {
  const EmptyRouterPage({Key? key}) : super(key: key);
}

class EmptyRouterScreen extends AutoRouter {
  const EmptyRouterScreen({Key? key}) : super(key: key);
}
