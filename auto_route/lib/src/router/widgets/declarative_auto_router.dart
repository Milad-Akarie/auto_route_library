part of 'auto_router.dart';

class _DeclarativeAutoRouter extends StatefulWidget {
  const new({
    required this.routesBuilder,
    required this.navigatorObserversBuilder,
    required this.onPopRoute,
    required this.navigatorKey,
    required this.navRestorationScopeId,
    required this.inheritNavigatorObservers,
    required this.onNavigate,
    required this.placeholderBuilder,
    required this.clipBehavior,
    required this.traversalEdgeBehavior,
    required this.heroControllerBuilder,
    super.key,
  });
  final RoutesBuilder routesBuilder;
  final RoutePopCallBack? onPopRoute;
  final NavigatorObserversBuilder navigatorObserversBuilder;
  final String? navRestorationScopeId;
  final bool inheritNavigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final OnNestedNavigateCallBack? onNavigate;
  final WidgetBuilder? placeholderBuilder;
  final Clip clipBehavior;
  final TraversalEdgeBehavior? traversalEdgeBehavior;
  final HeroController Function()? heroControllerBuilder;

  @override
  _DeclarativeAutoRouterState createState() => .new();
}

class _DeclarativeAutoRouterState extends State<_DeclarativeAutoRouter>
    with _HeroControllerOwner<_DeclarativeAutoRouter> {
  StackRouter? _controller;

  @override
  HeroController Function()? get _heroControllerBuilder =>
      widget.heroControllerBuilder;

  StackRouter? get controller => _controller;
  late List<NavigatorObserver> _navigatorObservers;
  late NavigatorObserversBuilder _inheritableObserversBuilder;
  late RoutingController _parentController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parentData = RouteData.of(context);
      final parentScope = RouterScope.of(context);
      _inheritableObserversBuilder = () {
        final observers = widget.navigatorObserversBuilder();
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
    if (_controller != null) {
      _controller!.dispose();
      _parentController.removeChildController(_controller!);
      _controller = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null, 'The router controller is not set up yet.');
    final stateHash = controller!.stateHash;
    final navigator = AutoRouteNavigator(
      router: _controller!,
      clipBehavior: widget.clipBehavior,
      key: GlobalObjectKey(_controller.hashCode),
      declarativeRoutesBuilder: widget.routesBuilder,
      navRestorationScopeId: widget.navRestorationScopeId,
      navigatorObservers: _navigatorObservers,
      didPop: widget.onPopRoute,
      placeholder: widget.placeholderBuilder,
      routeTraversalEdgeBehavior: widget.traversalEdgeBehavior,
    );
    final heroController = _heroController;
    return RouterScope(
      key: _controller!.globalRouterKey,
      controller: _controller!,
      inheritableObserversBuilder: _inheritableObserversBuilder,
      navigatorObservers: _navigatorObservers,
      stateHash: stateHash,
      child: heroController == null
          ? navigator
          : HeroControllerScope(controller: heroController, child: navigator),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StackRouter>('controller', controller));
  }
}
