import 'dart:collection';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:auto_route/src/route/route_def.dart';
import 'package:auto_route/src/router/auto_router_config.dart';
import 'package:auto_route/src/router/extended_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';

abstract class RoutingController {
  Future<void> push(PageRouteInfo route, {OnNavigationFails onFail});

  Future<void> replace(PageRouteInfo route, {OnNavigationFails onFail});

  Future<void> pushAll(List<PageRouteInfo> routes, {OnNavigationFails onFail});

  Future<void> replaceAll(List<PageRouteInfo> routes, {OnNavigationFails onFail});

  Future<bool> pop();

  List<ExtendedPage> get stack;

  RoutingController get parent;

  RoutingController get root;

  RoutingController get bottomMost;

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
  final ExtendedPage page;
  final String key;

  const RouteNode(this.page, this.key);

  RouteData get routeData => page.data;
}

class RouterNode extends ChangeNotifier implements RouteNode, RoutingController {
  final RouterNode parent;
  final ExtendedPage page;
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
  RoutingController get bottomMost {
    if (children.isNotEmpty) {
      var topNode = children.values.last;
      if (topNode is RouterNode) {
        return topNode.bottomMost;
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
  List<ExtendedPage> get stack => List.unmodifiable(children.values.map((e) => e.page));

  @override
  Future<void> push(PageRouteInfo route, {OnNavigationFails onFail}) async {
    var routeDef = _findRouteDefOrReportFailure(route, onFail);
    if (routeDef == null) {
      return null;
    }
    if (await _canNavigate(route, routeDef, onFail)) {
      return _push(route, routeDef: routeDef, onFail: onFail);
    }
    return null;
  }

  Future<void> pushSilently(
    PageRouteInfo route, {
    @required RouteDef routeDef,
    OnNavigationFails onFail,
  }) {
    return _push(route, routeDef: routeDef, onFail: onFail, notify: false);
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFails onFail,
  }) {
    assert(children.isNotEmpty);
    removeStackEntry(children.keys.last);
    return push(route, onFail: onFail);
  }

  @override
  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFails onFail,
  }) {
    return _pushAll(routes, onFail: onFail);
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFails onFail,
  }) {
    _clearHistory();
    return _pushAll(routes, onFail: onFail);
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
    OnNavigationFails onFail,
    bool notify = true,
  }) async {
    for (var route in routes) {
      var routeDef = _findRouteDefOrReportFailure(route, onFail);
      if (routeDef == null) {
        break;
      }
      if (await _canNavigate(route, routeDef, onFail)) {
        await _push(route, routeDef: routeDef, notify: false);
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
    OnNavigationFails onFail,
  ]) {
    var routeDef = _matcher.findRouteDef(route);
    if (routeDef != null) {
      return routeDef;
    } else {
      if (onFail != null) {
        onFail(RouteNotFoundFailure(route));
        return null;
      } else {
        throw FlutterError("[${toString()}] can not navigate to ${route.fullPathName}");
      }
    }
  }

  Future<void> _push(
    PageRouteInfo route, {
    @required RouteDef routeDef,
    OnNavigationFails onFail,
    bool notify = true,
  }) {
    var node = _createRouteNode(route, routeDef: routeDef);
    _addNode(node, notify: notify);
    return SynchronousFuture(null);
  }

  Future<bool> _canNavigate(
    PageRouteInfo route,
    RouteDef config,
    OnNavigationFails onFail,
  ) async {
    if (config.guards.isEmpty) {
      return true;
    }
    for (var guard in config.guards) {
      if (!await guard.canNavigate(route, this)) {
        if (onFail != null) {
          onFail(RejectedByGuardFailure(route, guard));
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
    ExtendedPage page = pageBuilder(routeData, routeDef);
    if (routeDef.hasChildren) {
      return RouterNode(
        parent: this,
        key: routeDef.path,
        routeCollection: routeCollection.subCollectionOf(routeDef.path),
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
      return RouteNode(page, routeDef.path);
    }
  }

  void removeStackEntry(dynamic key) {
    children.remove(key);
  }

  Future<void> _pushRouteTree(List<PageRouteInfo> routes, {bool notify = true}) {
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
      _pushRouteTree(routes, notify: true);
    }
    return SynchronousFuture(null);
  }

  RouteData _createRouteData(PageRouteInfo route, RouteDef routeDef) {
    return RouteData(
        route: route,
        key: route.path,
        path: route.pathName,
        queryParams: Parameters(route.queryParams),
        pathParams: Parameters(route.queryParams),
        parent: page?.data,
        fragment: route.fragment,
        args: route.args);
  }

  void _clearHistory() {
    if (children.isNotEmpty) {
      var keys = List.unmodifiable(children.keys);
      keys.forEach(removeStackEntry);
    }
  }

  @override
  RouteData get routeData => page?.data;
}
