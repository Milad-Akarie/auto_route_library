import 'dart:collection';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:auto_route/src/route/route_def.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:auto_route/src/router/auto_router_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';

part 'parallel_router_node.dart';

typedef RouteDataPredicate = bool Function(RouteData route);

abstract class RoutingController {
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> navigate(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushPath(String path, {bool includePrefixMatches = false, OnNavigationFailure onFailure});

  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushAndRemoveUntil(PageRouteInfo route,
      {@required RouteDataPredicate predicate, OnNavigationFailure onFailure});

  Future<void> replace(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushAll(List<PageRouteInfo> routes, {OnNavigationFailure onFailure});

  Future<void> replaceAll(List<PageRouteInfo> routes, {OnNavigationFailure onFailure});

  bool removeUntilRoot();

  bool removeUntil(RouteDataPredicate predicate);

  bool pop();

  String get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  RoutingController get parent;

  RoutingController get root;

  RoutingController get topMost;

  RouteData get currentRoute;

  RoutingController findRouterOf(String routeKey);

  void setCurrentRoute(String routeKey);
}

class RoutingControllerScope extends InheritedWidget {
  final RouterNode routerNode;

  const RoutingControllerScope({
    @required Widget child,
    @required this.routerNode,
  }) : super(child: child);

  static RoutingControllerScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoutingControllerScope>();
  }

  @override
  bool updateShouldNotify(covariant RoutingControllerScope oldWidget) {
    return routerNode != oldWidget.routerNode;
  }
}

class RouteNode {
  final AutoRoutePage page;
  final String key;

  const RouteNode(this.page, this.key);

  RouteData get routeData => page.data;
}

class RouterNode extends ChangeNotifier implements RouteNode, RoutingController {
  final RouterNode parent;
  final AutoRoutePage page;
  final String key;
  final RoutesCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final LinkedHashMap<ValueKey<RouteData>, RouteNode> _children = LinkedHashMap();
  final List<PageRouteInfo> preMatchedRoutes;

  RouteNode _activeNode;

  RouterNode({
    @required this.routeCollection,
    @required this.pageBuilder,
    this.page,
    this.key,
    this.parent,
    this.preMatchedRoutes,
  }) : matcher = RouteMatcher(routeCollection);

  bool get stackIsEmpty => _children.isEmpty;

  @override
  String toString() {
    return '$key Router';
  }

  RoutingController get root => parent?.root ?? this;

  void printTree([int indent = 0]) {
    _children.values.forEach((n) {
      print("${'-' * indent} ${n.key}");
      if (n is RouterNode) {
        n.printTree(indent + 2);
      }
    });
  }

  @override
  RoutingController findRouterOf(String routeKey) {
    if (_children.isEmpty) {
      return null;
    }
    return _children.values.whereType<RouterNode>().lastWhere(
          ((node) => node.key == routeKey),
          orElse: () => null,
        );
  }

  @override
  RouteData get currentRoute => _activeNode?.routeData;

  @override
  RoutingController get topMost {
    if (_activeNode is RouterNode) {
      return (_activeNode as RouterNode).topMost;
    }
    return this;
    // if (_children.isNotEmpty) {
    //   var topNode = _children.values.last;
    //   if (topNode is RouterNode) {
    //     return topNode.topMost;
    //   }
    // }
    // return this;
  }

  /// mayPop
  @override
  bool pop() => _pop();

  bool _pop({bool notify = true}) {
    var didPop = false;
    if (_children.length > 1) {
      removeEntry(_children.values.last.page);
      if (notify) {
        notifyListeners();
      }
      didPop = true;
    }
    return didPop;
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_children.values.map((e) => e.page));

  @override
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure}) async {
    return _push(route, onFailure: onFailure, notify: true);
  }

  @override
  Future<void> navigate(PageRouteInfo route, {OnNavigationFailure onFailure}) async {
    var entry = _findLastEntryWithKey(route.routeKey);
    if (entry != null) {
      return _removeUntil((route) => route == entry.routeData);
    }
    return _push(route, onFailure: onFailure, notify: true);
  }

  Future<void> pushSilently(PageRouteInfo route, {OnNavigationFailure onFailure}) async {
    return _push(route, onFailure: onFailure, notify: false);
  }

  Future<void> _push(PageRouteInfo route, {OnNavigationFailure onFailure, bool notify = true}) async {
    var config = _resolveConfigOrReportFailure(route, onFailure);
    if (config == null) {
      return null;
    }
    if (await _canNavigate([route], config, onFailure)) {
      return _addStackEntry(route, config: config, onFailure: onFailure, notify: notify);
    }
    return null;
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure onFailure,
  }) {
    // assert(_children.isNotEmpty);
    if (_children.isNotEmpty) _children.remove(_children.keys.last);
    return push(route, onFailure: onFailure);
  }

  @override
  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure onFailure,
  }) {
    return _pushAll(routes, onFailure: onFailure);
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure onFailure,
  }) {
    _clearHistory();
    return _pushAll(routes, onFailure: onFailure);
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
  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure onFailure}) {
    _pop(notify: false);
    return push(route, onFailure: onFailure);
  }

  @override
  bool removeUntil(RouteDataPredicate predicate) => _removeUntil(predicate);

  bool _removeUntil(RouteDataPredicate predicate, {bool notify = true}) {
    var didPop = false;
    for (var candidate in List.unmodifiable(_children.values).reversed) {
      if (predicate(candidate.routeData)) {
        break;
      } else {
        _pop(notify: false);
        didPop = true;
      }
    }
    if (didPop && notify) {
      notifyListeners();
    }
    return didPop;
  }

  void updateDeclarativeRoutes(
    List<PageRouteInfo> routes, {
    bool notify = false,
  }) {
    _clearHistory();

    for (var route in routes) {
      var config = _resolveConfigOrReportFailure(route);
      if (config == null) {
        break;
      }
      if (!listNullOrEmpty(config.guards)) {
        throw FlutterError("Declarative routes can not have guards");
      }

      var node = _createRouteNode(route, config: config);
      _addNode(node, notify: notify);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure onFailure,
    bool notify = true,
  }) async {
    final checkedRoutes = List<PageRouteInfo>.from(routes);
    for (var route in routes) {
      var config = _resolveConfigOrReportFailure(route, onFailure);
      if (config == null) {
        break;
      }
      if (await _canNavigate(checkedRoutes, config, onFailure)) {
        checkedRoutes.remove(route);
        _addStackEntry(route, config: config, notify: false);
      } else {
        break;
      }
    }
    if (notify) {
      notifyListeners();
    }
    return SynchronousFuture(null);
  }

  RouteConfig _resolveConfigOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure onFailure,
  ]) {
    var config = matcher.resolveConfigOrNull(route);
    if (config != null) {
      return config;
    } else {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route));
        return null;
      } else {
        throw FlutterError("[${toString()}] can not navigate to ${route.fullPath}");
      }
    }
  }

  void _addStackEntry(
    PageRouteInfo route, {
    @required RouteConfig config,
    OnNavigationFailure onFailure,
    bool notify = true,
  }) {
    var node = _createRouteNode(route, config: config);
    _addNode(node, notify: notify);
  }

  Future<bool> _canNavigate(
    List<PageRouteInfo> routes,
    RouteConfig config,
    OnNavigationFailure onFailure,
  ) async {
    if (config.guards.isEmpty) {
      return true;
    }
    for (var guard in config.guards) {
      if (!await guard.canNavigate(routes, this)) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(routes, guard));
        }
        return false;
      }
    }
    return true;
  }

  Key get _lastEntryKey {
    if (_children.isNotEmpty) {
      return _children.keys.last;
    }
    return null;
  }

  void _addNode(RouteNode node, {bool notify = true}) {
    _children[ValueKey(node.routeData)] = node;
    _activeNode = node;
    if (notify) {
      notifyListeners();
    }
  }

  RouteNode _createRouteNode(PageRouteInfo route, {RouteConfig config}) {
    var routeData = _createRouteData(route, config);
    AutoRoutePage page = pageBuilder(routeData, config);
    if (config.hasParallelChildren) {
      return ParallelRouterNode(
        parent: this,
        key: config.key,
        routeCollection: routeCollection.subCollectionOf(config.key),
        pageBuilder: pageBuilder,
        page: page,
        preMatchedRoutes: route?.children
            ?.map((r) => r.copyWith(
                  queryParams: route.queryParams,
                  fragment: route.fragment,
                ))
            ?.toList(growable: false),
      );
    } else if (config.isSubTree) {
      return RouterNode(
        parent: this,
        key: config.key,
        routeCollection: routeCollection.subCollectionOf(config.key),
        pageBuilder: pageBuilder,
        page: page,
        preMatchedRoutes: route?.children
            ?.map((r) => r.copyWith(
                  queryParams: route.queryParams,
                  fragment: route.fragment,
                ))
            ?.toList(growable: false),
      );
    } else {
      return RouteNode(page, config.key);
    }
  }

  void removeEntry(AutoRoutePage page) {
    _children.remove(ValueKey(page.data));
    if (_children.isNotEmpty) {
      _activeNode = _children.values.last;
    }
  }

  Future<void> _replaceAll(List<PageRouteInfo> routes, {bool notify = true}) {
    assert(routes != null && routes.isNotEmpty);
    _clearHistory();
    return _pushAll(routes, notify: notify);
  }

  Future<void> updateOrReplaceRoutes(List<PageRouteInfo> routes) {
    assert(routes != null);
    var route = routes.last;
    var config = _resolveConfigOrReportFailure(route);
    var newData = _createRouteData(route, config);
    var newKey = ValueKey(newData);
    var lastKey = _lastEntryKey;
    if (lastKey != null && lastKey == newKey) {
      if (route.hasChildren && _children[lastKey] is RouterNode) {
        // this line should remove any routes below the updated one
        // not sure if this's the desired behaviour
        // List.unmodifiable(children.keys).sublist(0, stack.length - 1).forEach(_removeHistoryEntry);
        (_children[lastKey] as RouterNode).updateOrReplaceRoutes(route.children);
      }
    } else {
      _replaceAll(routes, notify: true);
    }
    return SynchronousFuture(null);
  }

  RouteData _createRouteData(PageRouteInfo route, RouteConfig config) {
    return RouteData(
        route: route,
        key: route.routeKey,
        path: route.path,
        match: route.match,
        pathParams: Parameters(route.pathParams),
        queryParams: Parameters(route.queryParams),
        parent: page?.data,
        fragment: route.fragment,
        args: route.args);
  }

  void _clearHistory() {
    if (_children.isNotEmpty) {
      var keys = List.unmodifiable(_children.keys);
      keys.forEach(_children.remove);
    }
  }

  @override
  RouteData get routeData => page?.data;

  RouterNode routerOf(RouteData data) {
    return _children[ValueKey(data)];
  }

  @override
  Future<void> pushAndRemoveUntil(
    PageRouteInfo route, {
    @required RouteDataPredicate predicate,
    onFailure,
  }) {
    _removeUntil(predicate, notify: false);
    return push(route, onFailure: onFailure);
  }

  @override
  Future<void> pushPath(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure onFailure,
  }) {
    var matches = matcher.match(path, includePrefixMatches: includePrefixMatches);
    if (matches != null) {
      var routes = matches.map((m) => PageRouteInfo.fromMatch(m)).toList();
      return _pushAll(routes, onFailure: onFailure, notify: true);
    } else if (onFailure != null) {
      onFailure.call(
        RouteNotFoundFailure(
          PageRouteInfo(null, path: null, match: path),
        ),
      );
    }
    return SynchronousFuture(null);
  }

  RouteNode _findLastEntryWithKey(String key) {
    if (_children.isEmpty) {
      return null;
    } else {
      return _children.values.lastWhere((n) => n.key == key, orElse: () => null);
    }
  }

  @override
  void setCurrentRoute(String routeKey) {
    var route = _findLastEntryWithKey(routeKey);
    if (route != null) {
      _activeNode = route;
      notifyListeners();
    } else {
      throw ("Cant find route with key $routeKey  $stack");
    }
  }
}
