import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A Wrapper for [Navigator] that handles stack-routing
class AutoRouter extends StatefulWidget {
  /// A builder function that returns a list of observes
  ///
  /// Why isn't this a list of navigatorObservers?
  /// The reason for that is a [NavigatorObserver] instance can only
  /// be used by a single [Navigator], so unless you're using a one
  /// single router or you don't want your nested routers to inherit
  /// observers make sure navigatorObservers builder always returns
  /// fresh observer instances.
  final NavigatorObserversBuilder navigatorObservers;

  /// This builder maybe used to build content with context
  /// that has [AutoRouterState.controller]
  final Widget Function(BuildContext context, Widget content)? builder;

  /// Passed to [Navigator.restorationScopeId]
  final String? navRestorationScopeId;

  /// Whether this router should inherit it's ancestor's observers
  final bool inheritNavigatorObservers;

  /// The state key passed to [Navigator]
  final GlobalKey<NavigatorState>? navigatorKey;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with [Theme.scaffoldBackgroundColor].
  final WidgetBuilder? placeholder;

  /// The clip behavior of the navigator
  final Clip clipBehavior;

  /// The traversal edge behavior of the navigator
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  /// Default constructor
  const AutoRouter({
    super.key,
    this.navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.builder,
    this.navRestorationScopeId,
    this.navigatorKey,
    this.inheritNavigatorObservers = true,
    this.placeholder,
    this.clipBehavior = Clip.hardEdge,
    this.traversalEdgeBehavior,
  });

  /// Builds a [_DeclarativeAutoRouter] which uses
  /// a declarative list of routes to update navigator stack
  static Widget declarative({
    Key? key,
    NavigatorObserversBuilder navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    required RoutesBuilder routes,
    RoutePopCallBack? onPopRoute,
    String? navRestorationScopeId,
    bool inheritNavigatorObservers = true,
    GlobalKey<NavigatorState>? navigatorKey,
    OnNestedNavigateCallBack? onNavigate,
    WidgetBuilder? placeholder,
    Clip clipBehavior = Clip.hardEdge,
    TraversalEdgeBehavior? traversalEdgeBehavior,
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
        clipBehavior: clipBehavior,
        traversalEdgeBehavior: traversalEdgeBehavior,
      );

  @override
  State<AutoRouter> createState() => AutoRouterState();

  /// Looks up and returns the scoped [StackRouter]
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// throws an error if it does not find it
  static StackRouter of(BuildContext context, {bool watch = false}) {
    var scope = StackRouterScope.of(context, watch: watch);
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

  /// Helper to access [RoutingController.innerRouterOf]
  static StackRouter? innerRouterOf(BuildContext context, String routeName) {
    return of(context).innerRouterOf<StackRouter>(routeName);
  }
}

/// State implementation of [AutoRouter]
class AutoRouterState extends State<AutoRouter> {
  NestedStackRouter? _controller;

  /// The StackRouter controlling this router widget
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
        matchId: parentRouteData.matchId,
        routeData: parentRouteData,
        navigatorKey: widget.navigatorKey,
        routeCollection: _parentController.routeCollection.subCollectionOf(
          parentRouteData.name,
        ),
      );
      _parentController.attachChildController(_controller!);
      _controller!.addListener(_rebuildListener);
      // defer the setup of initial routes to the next frame
      // so that we can have access to the context inside guards
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller!.setupInitialRoutes();
      });
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
    final navigator = AutoRouteNavigator(
      router: _controller!,
      clipBehavior: widget.clipBehavior,
      key: GlobalObjectKey(_controller.hashCode),
      navRestorationScopeId: widget.navRestorationScopeId,
      navigatorObservers: _navigatorObservers,
      placeholder: widget.placeholder,
      routeTraversalEdgeBehavior: widget.traversalEdgeBehavior,
    );
    final stateHash = _controller!.stateHash;
    return RouterScope(
      key: _controller!.globalRouterKey,
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

  @override
  debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StackRouter>('controller', controller));
  }
}

class _DeclarativeAutoRouter extends StatefulWidget {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final NavigatorObserversBuilder navigatorObservers;
  final String? navRestorationScopeId;
  final bool inheritNavigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final OnNestedNavigateCallBack? onNavigate;
  final WidgetBuilder? placeholder;
  final Clip clipBehavior;
  final TraversalEdgeBehavior? traversalEdgeBehavior;
  const _DeclarativeAutoRouter({
    required this.routes,
    this.navigatorObservers = AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.onPopRoute,
    this.navigatorKey,
    this.navRestorationScopeId,
    this.inheritNavigatorObservers = true,
    this.onNavigate,
    this.placeholder,
    this.clipBehavior = Clip.hardEdge,
    this.traversalEdgeBehavior,
  });

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
        matchId: parentData.matchId,
        routeData: parentData,
        managedByWidget: true,
        onNavigate: widget.onNavigate,
        navigatorKey: widget.navigatorKey,
        routeCollection: _parentController.routeCollection.subCollectionOf(
          parentData.name,
        ),
      );
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
      key: _controller!.globalRouterKey,
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      navigatorObservers: _navigatorObservers,
      stateHash: stateHash,
      child: HeroControllerScope(
        controller: _heroController,
        child: AutoRouteNavigator(
          router: _controller!,
          clipBehavior: widget.clipBehavior,
          key: GlobalObjectKey(_controller.hashCode),
          declarativeRoutesBuilder: widget.routes,
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          didPop: widget.onPopRoute,
          placeholder: widget.placeholder,
          routeTraversalEdgeBehavior: widget.traversalEdgeBehavior,
        ),
      ),
    );
  }

  @override
  debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StackRouter>('controller', controller));
  }
}
