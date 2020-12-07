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

abstract class RoutingController {
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> replace(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushAll(List<PageRouteInfo> routes, {OnNavigationFailure onFailure});

  Future<void> replaceAll(List<PageRouteInfo> routes, {OnNavigationFailure onFailure});

  Future<bool> pop();

  List<AutoRoutePage> get stack;

  RoutingController get parent;

  RoutingController get root;

  RoutingController get topMost;

  RouteData get currentRoute;

  RoutingController findRouterOf(String routeKey);
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
    return routerNode != routerNode;
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
  final RouteMatcher _matcher;
  final LinkedHashMap<LocalKey, RouteNode> children = LinkedHashMap();
  final List<PageRouteInfo> preMatchedRoutes;

  RouterNode({
    @required this.routeCollection,
    @required this.pageBuilder,
    this.page,
    this.key,
    this.parent,
    this.preMatchedRoutes,
  }) : _matcher = RouteMatcher(routeCollection);

  @override
  String toString() {
    return '$key Router';
  }

  RoutingController get root => parent?.root ?? this;

  void printTree([int indent = 0]) {
    children.values.forEach((n) {
      print("${'-' * indent} ${n.key}");
      if (n is RouterNode) {
        n.printTree(indent + 2);
      }
    });
  }

  @override
  RoutingController findRouterOf(String routeKey) {
    if (children.isEmpty) {
      return null;
    }
    return children.values.whereType<RouterNode>().lastWhere(
          ((node) => node.key == routeKey),
          orElse: () => null,
        );
  }

  @override
  RouteData get currentRoute {
    if (children.isNotEmpty) {
      return children.values.last.routeData;
    }
    return null;
  }

  @override
  RoutingController get topMost {
    if (children.isNotEmpty) {
      var topNode = children.values.last;
      if (topNode is RouterNode) {
        return topNode.topMost;
      }
    }
    return this;
  }

  /// mayPop
  @override
  Future<bool> pop() {
    var didPop = false;
    if (children.length > 1) {
      children.remove(children.keys.last);
      notifyListeners();
      didPop = true;
    }
    return SynchronousFuture<bool>(didPop);
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(children.values.map((e) => e.page));

  @override
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure}) async {
    return _push(route, onFailure: onFailure, notify: true);
  }

  Future<void> pushSilently(PageRouteInfo route, {OnNavigationFailure onFailure}) async {
    return _push(route, onFailure: onFailure, notify: false);
  }

  Future<void> _push(PageRouteInfo route, {OnNavigationFailure onFailure, bool notify = true}) async {
    var routeDef = _findRouteDefOrReportFailure(route, onFailure);
    if (routeDef == null) {
      return null;
    }
    if (await _canNavigate(route, routeDef, onFailure)) {
      return _addStackEntry(route, routeDef: routeDef, onFailure: onFailure, notify: notify);
    }
    return null;
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure onFailure,
  }) {
    assert(children.isNotEmpty);
    children.remove(children.keys.last);
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

  void updateDeclarativeRoutes(
    List<PageRouteInfo> routes, {
    bool notify = false,
  }) {
    _clearHistory();

    for (var route in routes) {
      var routeDef = _findRouteDefOrReportFailure(route);
      if (routeDef == null) {
        break;
      }
      if (!listNullOrEmpty(routeDef.guards)) {
        throw FlutterError("Declarative routes can not have guards");
      }

      var node = _createRouteNode(route, routeDef: routeDef);
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
    for (var route in routes) {
      var routeDef = _findRouteDefOrReportFailure(route, onFailure);
      if (routeDef == null) {
        break;
      }
      if (await _canNavigate(route, routeDef, onFailure)) {
        _addStackEntry(route, routeDef: routeDef, notify: false);
      } else {
        break;
      }
    }
    if (notify) {
      notifyListeners();
    }
    return SynchronousFuture(null);
  }

  RouteDef _findRouteDefOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure onFailure,
  ]) {
    var routeDef = _matcher.findRouteDef(route);
    if (routeDef != null) {
      return routeDef;
    } else {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route));
        return null;
      } else {
        throw FlutterError("[${toString()}] can not navigate to ${route.fullPathName}");
      }
    }
  }

  void _addStackEntry(
    PageRouteInfo route, {
    @required RouteDef routeDef,
    OnNavigationFailure onFailure,
    bool notify = true,
  }) {
    var node = _createRouteNode(route, routeDef: routeDef);
    _addNode(node, notify: notify);
  }

  Future<bool> _canNavigate(
    PageRouteInfo route,
    RouteDef config,
    OnNavigationFailure onFailure,
  ) async {
    if (config.guards.isEmpty) {
      return true;
    }
    for (var guard in config.guards) {
      if (!await guard.canNavigate(route, this)) {
        if (onFailure != null) {
          onFailure(RejectedByGuardFailure(route, guard));
        }
        return false;
      }
    }
    return true;
  }

  Key get _lastEntryKey {
    if (children.isNotEmpty) {
      return children.keys.last;
    }
    return null;
  }

  void _addNode(RouteNode node, {bool notify = true}) {
    children[ValueKey(node.routeData)] = node;
    if (notify) {
      notifyListeners();
    }
  }

  RouteNode _createRouteNode(PageRouteInfo route, {RouteDef routeDef}) {
    var routeData = _createRouteData(route, routeDef);
    AutoRoutePage page = pageBuilder(routeData, routeDef);
    if (routeDef.isSubTree) {
      return RouterNode(
        parent: this,
        key: routeDef.key,
        routeCollection: routeCollection.subCollectionOf(routeDef.key),
        pageBuilder: pageBuilder,
        page: page,
        preMatchedRoutes: route?.children
            ?.map((d) => d.copyWith(
                  queryParams: route.queryParams,
                  fragment: route.fragment,
                ))
            ?.toList(growable: false),
      );
    } else {
      return RouteNode(page, routeDef.key);
    }
  }

  void removeEntry(AutoRoutePage page) {
    children.remove(ValueKey(page.data));
  }

  Future<void> _replaceAll(List<PageRouteInfo> routes, {bool notify = true}) {
    assert(routes != null && routes.isNotEmpty);
    _clearHistory();
    return _pushAll(routes, notify: notify);
  }

  Future<void> updateOrReplaceRoutes(List<PageRouteInfo> routes) {
    assert(routes != null);
    var route = routes.last;
    var routeDef = _findRouteDefOrReportFailure(route);
    var newData = _createRouteData(route, routeDef);
    var newKey = ValueKey(newData);
    var lastKey = _lastEntryKey;
    if (lastKey != null && lastKey == newKey) {
      if (route.hasChildren && children[lastKey] is RouterNode) {
        // this line should remove any routes below the updated one
        // not sure if this's the desired behaviour
        // List.unmodifiable(children.keys).sublist(0, stack.length - 1).forEach(_removeHistoryEntry);
        (children[lastKey] as RouterNode).updateOrReplaceRoutes(route.children);
      }
    } else {
      _replaceAll(routes, notify: true);
    }
    return SynchronousFuture(null);
  }

  RouteData _createRouteData(PageRouteInfo route, RouteDef routeDef) {
    return RouteData(
        route: route,
        key: route.routeKey,
        path: route.path,
        pathName: route.pathName,
        pathParams: Parameters(route.pathParams),
        queryParams: Parameters(route.queryParams),
        parent: page?.data,
        fragment: route.fragment,
        args: route.args);
  }

  void _clearHistory() {
    if (children.isNotEmpty) {
      var keys = List.unmodifiable(children.keys);
      keys.forEach(children.remove);
    }
  }

  @override
  RouteData get routeData => page?.data;

  void removeTopMostEntry() {
    assert(children.isNotEmpty);
    children.remove(children.keys.last);
  }
}
