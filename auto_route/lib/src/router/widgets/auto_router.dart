import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

part 'declarative_auto_router.dart';

/// A Wrapper for [Navigator] that handles stack-routing
class AutoRouter extends StatefulWidget {
  /// Default constructor
  const new({
    super.key,
    this.navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.builder,
    this.navRestorationScopeId,
    this.navigatorKey,
    this.inheritNavigatorObservers = true,
    this.placeholder,
    this.clipBehavior = Clip.hardEdge,
    this.traversalEdgeBehavior,
    this.heroControllerBuilder,
  });

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
  /// an empty page with `Theme.scaffoldBackgroundColor`.
  final WidgetBuilder? placeholder;

  /// The clip behavior of the navigator
  final Clip clipBehavior;

  /// The traversal edge behavior of the navigator
  final TraversalEdgeBehavior? traversalEdgeBehavior;

  /// Creates the [HeroController] that flies Heroes between this router's
  /// pages, or `null` to fly none.
  ///
  /// Flutter gives a [HeroController] only to the app's root navigator, so
  /// without one a Hero stays put between two pages of a nested router.
  /// Passing a builder turns flights on: the router calls it once, puts a
  /// [HeroControllerScope] with the controller around its navigator, and
  /// disposes the controller when the router leaves the tree. Flutter's own
  /// controllers plug in as they are: pass
  /// [MaterialApp.createMaterialHeroController] for Material's arc, or
  /// `CupertinoApp.createCupertinoHeroController` for a straight line.
  ///
  /// A rebuild that sets the builder creates a controller, and one that clears
  /// it disposes the controller; a rebuild that passes a different builder
  /// keeps the controller it has. Each router needs its own controller, which
  /// is why this takes a builder and not a controller.
  ///
  /// [AutoTabsRouter] needs none: it shows its tabs without a navigator, so a
  /// Hero flies only between the pages of a tab's own nested [AutoRouter],
  /// which is where this goes.
  final HeroController Function()? heroControllerBuilder;

  /// Builds a [_DeclarativeAutoRouter] which uses
  /// a declarative list of routes to update navigator stack
  ///
  /// [heroControllerBuilder] works as [AutoRouter.heroControllerBuilder]
  /// does: pass [MaterialApp.createMaterialHeroController] or
  /// `CupertinoApp.createCupertinoHeroController` to fly Heroes between this
  /// router's pages, and the router disposes the controller it creates. Left
  /// out, the router creates no [HeroController] and flies no Heroes between
  /// its pages. [AutoTabsRouter] needs none.
  static Widget declarative({
    required RoutesBuilder routes,
    Key? key,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    RoutePopCallBack? onPopRoute,
    String? navRestorationScopeId,
    bool inheritNavigatorObservers = true,
    GlobalKey<NavigatorState>? navigatorKey,
    OnNestedNavigateCallBack? onNavigate,
    WidgetBuilder? placeholder,
    Clip clipBehavior = .hardEdge,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    HeroController Function()? heroControllerBuilder,
  }) => _DeclarativeAutoRouter(
    key: key,
    onPopRoute: onPopRoute,
    navigatorKey: navigatorKey,
    navRestorationScopeId: navRestorationScopeId,
    navigatorObserversBuilder: navigatorObservers,
    inheritNavigatorObservers: inheritNavigatorObservers,
    onNavigate: onNavigate,
    placeholderBuilder: placeholder,
    routesBuilder: routes,
    clipBehavior: clipBehavior,
    traversalEdgeBehavior: traversalEdgeBehavior,
    heroControllerBuilder: heroControllerBuilder,
  );

  @override
  State<AutoRouter> createState() => AutoRouterState();

  /// Looks up and returns the scoped [StackRouter], the closest one above
  /// [context], which may be one built by [AutoRouter.declarative].
  ///
  /// if watch is true dependent widget will watch changes
  /// of this scope otherwise it would just read it
  ///
  /// throws an error if it does not find it
  static StackRouter of(BuildContext context, {bool watch = false}) {
    final scope = StackRouterScope.of(context, watch: watch);
    if (kDebugMode && scope == null) {
      throw FlutterError(
        'AutoRouter operation requested with a context that does not '
        'include an AutoRouter.\n'
        'The context used to retrieve the Router must be that of a widget that '
        'is a descendant of an AutoRouter widget.',
      );
    }
    return scope!.controller;
  }

  /// Helper to access [RoutingController.innerRouterOf]
  static StackRouter? innerRouterOf(BuildContext context, String routeName) {
    return of(context).innerRouterOf(routeName);
  }
}

/// State implementation of [AutoRouter]
class AutoRouterState extends State<AutoRouter>
    with _HeroControllerOwner<AutoRouter> {
  @override
  HeroController Function()? get _heroControllerBuilder =>
      widget.heroControllerBuilder;

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
        final observers = widget.navigatorObservers();
        if (!widget.inheritNavigatorObservers) {
          return observers;
        }
        final inheritedObservers = parentScope.inheritableObserversBuilder();
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
      if (_controller!.setupInitialRoutesSynchronously()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller?.notifyAll();
        });
      } else {
        // defer the setup of initial routes to the next frame
        // so that we can have access to the context inside guards
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller!.setupInitialRoutes();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null, 'The router controller is not set up yet.');
    return ListenableBuilder(
      listenable: _controller!,
      builder: (_, _) {
        final navigator = AutoRouteNavigator(
          router: _controller!,
          clipBehavior: widget.clipBehavior,
          key: GlobalObjectKey(_controller.hashCode),
          navRestorationScopeId: widget.navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          placeholder: widget.placeholder,
          routeTraversalEdgeBehavior: widget.traversalEdgeBehavior,
        );
        final heroController = _heroController;
        final scopedNavigator = heroController == null
            ? navigator
            : HeroControllerScope(controller: heroController, child: navigator);
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
                ? scopedNavigator
                : Builder(
                    builder: (ctx) => widget.builder!(ctx, scopedNavigator),
                  ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
      _parentController.removeChildController(_controller!);
      _controller = null;
    }
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StackRouter>('controller', controller));
  }
}

/// Owns the [HeroController] a router's `heroControllerBuilder` creates.
///
/// Creates it when the state starts or when a rebuild sets the builder, and
/// disposes it when a rebuild clears the builder or the state leaves the tree.
mixin _HeroControllerOwner<T extends StatefulWidget> on State<T> {
  HeroController? _heroController;

  HeroController Function()? get _heroControllerBuilder;

  @override
  void initState() {
    super.initState();
    _heroController = _heroControllerBuilder?.call();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final builder = _heroControllerBuilder;
    if (builder == null) {
      _heroController?.dispose();
      _heroController = null;
    } else {
      _heroController ??= builder();
    }
  }

  @override
  void dispose() {
    _heroController?.dispose();
    _heroController = null;
    super.dispose();
  }
}
