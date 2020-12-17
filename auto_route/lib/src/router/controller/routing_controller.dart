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

typedef RouteDataPredicate = bool Function(RouteData route);

abstract class RoutingController implements ChangeNotifier {
  String get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  T parent<T extends RoutingController>();

  StackRouter get root;

  RoutingController get topMost;

  RouteData get currentRoute;

  RouteData get routeData;

  RouteCollection get routeCollection;

  bool get hasEntries;

  T childRouterOf<T extends RoutingController>(String routeKey);

  RoutingController routerOfRoute(RouteData routeData);

  List<PageRouteInfo> get preMatchedRoutes;

  PageBuilder get pageBuilder;

  @override
  String toString() => '$key Routing Controller';

  bool pop();
}

abstract class TabsRouter extends RoutingController {
  void setActiveIndex(int index);

  int get activeIndex;

  void setupRoutes(List<PageRouteInfo> routes);
}

abstract class StackRouter extends RoutingController {
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
}

class StackRouterScope extends InheritedWidget {
  final StackRouter router;

  const StackRouterScope({
    @required Widget child,
    @required this.router,
  }) : super(child: child);

  static StackRouterScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return router != oldWidget.router;
  }
}

abstract class StackEntryItem {
  AutoRoutePage get page;

  String get key;

  RouteData get routeData;

  factory StackEntryItem.create({
    @required RouteConfig config,
    AutoRoutePage page,
    @required PageRouteInfo route,
    @required RoutingController parent,
  }) {
    if (config.isSubTree) {
      if (config.usesTabsRouter) {
        return ParallelTreeEntry(
          parentController: parent,
          pageBuilder: parent.pageBuilder,
          routeCollection: parent.routeCollection.subCollectionOf(config.key),
          key: config.key,
          page: page,
          preMatchedRoutes: route?.children
              ?.map((r) => r.copyWith(
                    queryParams: route.queryParams,
                    fragment: route.fragment,
                  ))
              ?.toList(growable: false),
        );
      } else {
        return TreeEntry(
          parentController: parent,
          key: config.key,
          routeCollection: parent.routeCollection.subCollectionOf(config.key),
          pageBuilder: parent.pageBuilder,
          page: page,
          preMatchedRoutes: route?.children
              ?.map((r) => r.copyWith(
                    queryParams: route.queryParams,
                    fragment: route.fragment,
                  ))
              ?.toList(growable: false),
        );
      }
    } else {
      return RouteEntry(page, config.key);
    }
  }
}

class RouteEntry implements StackEntryItem {
  final AutoRoutePage page;
  final String key;

  const RouteEntry(this.page, this.key);

  RouteData get routeData => page.data;
}

class ParallelTreeEntry<T extends RoutingController> extends ChangeNotifier implements StackEntryItem, TabsRouter {
  final T parentController;
  final AutoRoutePage page;
  final String key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final List<StackEntryItem> _children = List();
  final List<PageRouteInfo> preMatchedRoutes;
  int _activeIndex = 0;

  ParallelTreeEntry({
    @required this.routeCollection,
    @required this.pageBuilder,
    this.page,
    this.key,
    this.parentController,
    this.preMatchedRoutes,
  }) : matcher = RouteMatcher(routeCollection);

  T parent<T extends RoutingController>() => parent as T;

  @override
  RouteData get currentRoute => _children[_activeIndex]?.routeData;

  @override
  int get activeIndex => _activeIndex;

  @override
  RouteData get routeData => page?.data;

  @override
  StackRouter get root => parentController?.root ?? this;

  @override
  void setActiveIndex(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_children.map((e) => e.page));

  StackEntryItem get _activeEntry => _children[_activeIndex];

  @override
  RoutingController get topMost {
    var activeEntry = _activeEntry;
    if (activeEntry is RoutingController) {
      return (activeEntry as RoutingController).topMost;
    }
    return this;
  }

  @override
  T childRouterOf<T extends RoutingController>(String routeKey) {
    if (_children.isEmpty) {
      return null;
    }
    return _children.whereType<T>().lastWhere(
          ((controller) => controller.key == routeKey),
          orElse: () => null,
        );
  }

  @override
  RoutingController routerOfRoute(RouteData routeData) {
    return _children.whereType<RoutingController>().lastWhere(
          (c) => c.routeData == routeData,
          orElse: () => null,
        );
  }

  @override
  bool get hasEntries => _children.isNotEmpty;

  @override
  bool pop() {
    final activeEntry = _activeEntry;
    if (activeEntry is RoutingController) {
      return (activeEntry as RoutingController).pop();
    }
    return false;
  }

  @override
  void setupRoutes(List<PageRouteInfo> routes) {
    List<PageRouteInfo> routesToPush = routes;
    if (preMatchedRoutes?.isNotEmpty == true) {
      final preMatchedRoute = preMatchedRoutes.last;
      final correspondingRouteIndex = routes.indexWhere(
        (r) => r.routeKey == preMatchedRoute.routeKey,
      );
      if (correspondingRouteIndex != -1) {
        routesToPush
          ..removeAt(correspondingRouteIndex)
          ..insert(correspondingRouteIndex, preMatchedRoute);
        _activeIndex = correspondingRouteIndex;
      }
    }
    if (routesToPush?.isNotEmpty == true) {
      _pushAll(routesToPush);
    }
  }

  void _pushAll(List<PageRouteInfo> routes) {
    _children.clear();
    for (var route in routes) {
      final config = matcher.resolveConfigOrNull(route);
      if (config == null) {
        throw FlutterError("$this can not navigate to ${route.routeKey}");
      } else {
        final data = RouteData.from(route, config, parentData: page?.data);
        final entry = StackEntryItem.create(
          config: config,
          route: route,
          parent: this,
          page: pageBuilder(data, config),
        );
        _children.add(entry);
      }
    }
  }
}

class TreeEntry<T extends RoutingController> extends ChangeNotifier implements StackEntryItem, StackRouter {
  final T parentController;
  final AutoRoutePage page;
  final String key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final LinkedHashMap<ValueKey<RouteData>, StackEntryItem> _children = LinkedHashMap();
  final List<PageRouteInfo> preMatchedRoutes;

  TreeEntry({
    @required this.routeCollection,
    @required this.pageBuilder,
    this.page,
    this.key,
    this.parentController,
    this.preMatchedRoutes,
  }) : matcher = RouteMatcher(routeCollection);

  StackRouter get root => parentController?.root ?? this;

  T parent<T extends RoutingController>() => parentController as T;

  @override
  RouteData get currentRoute {
    if (_children.isNotEmpty) {
      return _children.values.last.routeData;
    }
    return null;
  }

  @override
  RoutingController get topMost {
    if (_children.isNotEmpty) {
      var topEntry = _children.values.last;
      if (topEntry is RoutingController) {
        return (topEntry as RoutingController).topMost;
      }
    }
    return this;
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
      final key = ValueKey(entry.routeData);
      _children.remove(key);
      _children[key] = entry;
      notifyListeners();
    } else {
      throw ("can not find entry with key ${route.routeKey}");
    }
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

      var entry = _createEntry(route, config: config);
      _addEntry(entry, notify: notify);
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
    var entry = _createEntry(route, config: config);
    _addEntry(entry, notify: notify);
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

  void _addEntry(StackEntryItem entry, {bool notify = true}) {
    _children[ValueKey(entry.routeData)] = entry;
    if (notify) {
      notifyListeners();
    }
  }

  StackEntryItem _createEntry(PageRouteInfo route, {RouteConfig config}) {
    var routeData = RouteData.from(route, config, parentData: page?.data);
    return StackEntryItem.create(
      config: config,
      route: route,
      page: pageBuilder(routeData, config),
      parent: this,
    );
  }

  void removeEntry(AutoRoutePage page) {
    _children.remove(ValueKey(page.data));
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
    var newData = RouteData.from(route, config, parentData: page?.data);
    var newKey = ValueKey(newData);
    var lastKey = _lastEntryKey;
    if (lastKey != null && lastKey == newKey) {
      if (route.hasChildren && _children[lastKey] is RoutingController) {
        // this line should remove any routes below the updated one
        // not sure if this's the desired behaviour
        // List.unmodifiable(children.keys).sublist(0, stack.length - 1).forEach(_removeHistoryEntry);
        (_children[lastKey] as TreeEntry).updateOrReplaceRoutes(route.children);
      }
    } else {
      _replaceAll(routes, notify: true);
    }
    return SynchronousFuture(null);
  }

  void _clearHistory() {
    if (_children.isNotEmpty) {
      var keys = List.unmodifiable(_children.keys);
      keys.forEach(_children.remove);
    }
  }

  @override
  RouteData get routeData => page?.data;

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

  RouteEntry _findLastEntryWithKey(String key) {
    if (_children.isEmpty) {
      return null;
    } else {
      return _children.values.lastWhere((n) => n.key == key, orElse: () => null);
    }
  }

  @override
  T childRouterOf<T extends RoutingController>(String routeKey) {
    if (_children.isEmpty) {
      return null;
    } else {
      return _children.values.whereType<T>().lastWhere(
            (n) => n.key == key,
            orElse: () => null,
          );
    }
  }

  @override
  RoutingController routerOfRoute(routeData) {
    return _children.values.whereType<RoutingController>().lastWhere(
          (c) => c.routeData == routeData,
          orElse: () => null,
        );
  }

  @override
  bool get hasEntries => _children.isNotEmpty;
}

class TabsRoutingControllerScope extends InheritedWidget {
  final TabsRouter controller;

  const TabsRoutingControllerScope({
    @required Widget child,
    @required this.controller,
  }) : super(child: child);

  static TabsRoutingControllerScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabsRoutingControllerScope>();
  }

  @override
  bool updateShouldNotify(covariant TabsRoutingControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
