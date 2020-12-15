part of 'routing_controller.dart';

class ParallelRoutingControllerScope extends InheritedWidget {
  final ParallelRouterNode routerNode;

  const ParallelRoutingControllerScope({
    @required Widget child,
    @required this.routerNode,
  }) : super(child: child);

  static ParallelRoutingControllerScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ParallelRoutingControllerScope>();
  }

  @override
  bool updateShouldNotify(covariant ParallelRoutingControllerScope oldWidget) {
    return routerNode != oldWidget.routerNode;
  }
}

class ParallelRouterNode extends RouterNode {
  String _activeRouteKey;

  ParallelRouterNode({
    RouterNode parent,
    AutoRoutePage page,
    String key,
    RoutesCollection routeCollection,
    PageBuilder pageBuilder,
    RouteMatcher matcher,
    List<PageRouteInfo> preMatchedRoutes,
  }) : super(
          parent: parent,
          page: page,
          key: key,
          routeCollection: routeCollection,
          pageBuilder: pageBuilder,
          preMatchedRoutes: preMatchedRoutes,
        );

  String get activeRouteKey => _activeRouteKey;

  void setActiveRouteKey(String key) {
    _activeRouteKey = key;
    notifyListeners();
  }

  RouteNode _findLastEntryWithKey(String key) {
    if (_children.isEmpty) {
      return null;
    } else {
      return _children.values.lastWhere((n) => n.key == key, orElse: () => null);
    }
  }

  @override
  RouteData get currentRoute {
    var activeChild = _findLastEntryWithKey(_activeRouteKey);
    return activeChild?.routeData;
  }

  @override
  RoutingController get topMost {
    var activeChild = _findLastEntryWithKey(_activeRouteKey);
    if (activeChild != null && activeChild is RouterNode) {
      return activeChild.topMost;
    }
    return this;
  }

  RouterNode _findChildRouterOrThrow(String routerKey) {
    final childRouter = findRouterOf(routerKey);
    if (childRouter == null) {
      throw FlutterError('Can not find child router with key $routerKey');
    }
    return childRouter;
  }

  @override
  bool pop({@required String childRouterKey}) {
    final childRouter = _findChildRouterOrThrow(childRouterKey);
    return childRouter.pop();
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_children.values.map((e) => e.page));

  @override
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure, @required String childRouterKey}) async {
    return _findChildRouterOrThrow(childRouterKey).push(route, onFailure: onFailure);
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure onFailure,
    @required String childRouterKey,
  }) {
    return _findChildRouterOrThrow(childRouterKey).replace(route, onFailure: onFailure);
  }

  @override
  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure onFailure,
    @required String childRouterKey,
  }) {
    return _findChildRouterOrThrow(childRouterKey).pushAll(routes, onFailure: onFailure);
  }

  @override
  bool removeUntilRoot() {
    var didPop = false;
    if (_children.length > 1) {
      for (var i = 1; i < _children.keys.length; i++) {
        _children.remove(_children.keys.elementAt(i));
      }
      notifyListeners();
      didPop = true;
    }
    return didPop;
  }

  @override
  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure onFailure, @required String childRouterKey}) {
    return _findChildRouterOrThrow(childRouterKey).popAndPush(route, onFailure: onFailure);
  }

  @override
  bool removeUntil(RouteDataPredicate predicate, {@required String childRouterKey}) =>
      _findChildRouterOrThrow(childRouterKey).removeUntil(predicate);

  void removeEntry(AutoRoutePage page) {
    _children.remove(ValueKey(page.data));
  }

  @override
  RouteData get routeData => page?.data;

  RouterNode routerOf(RouteData data) {
    return _children[ValueKey(data)];
  }
}
