import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_config.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:auto_route/src/router/root_stack_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';

typedef RouteDataPredicate = bool Function(RouteData route);

abstract class RoutingController implements ChangeNotifier {
  ValueKey<PageRouteInfo> get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  T parent<T extends RoutingController>();

  StackRouter get root;

  RoutingController get topMost;

  RouteData get currentRoute;

  RouteData get routeData;

  RouteCollection get routeCollection;

  bool get hasEntries;

  T innerRouterOf<T extends RoutingController>(String routeName);

  RoutingController innerRouterOfRoute(PageRouteInfo route);

  List<PageRouteInfo> get preMatchedRoutes;

  PageBuilder get pageBuilder;

  @override
  String toString() => '$key Routing Controller';

  Future<bool> pop();
}

abstract class TabsRouter extends RoutingController {
  void setActiveIndex(int index);

  int get activeIndex;

  void setupRoutes(List<PageRouteInfo> routes);
}

abstract class StackRouter extends RoutingController {
  Future<void> push(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> navigate(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushPath(String path,
      {bool includePrefixMatches = false, OnNavigationFailure onFailure});

  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushAndRemoveUntil(PageRouteInfo route,
      {@required RouteDataPredicate predicate, OnNavigationFailure onFailure});

  Future<void> replace(PageRouteInfo route, {OnNavigationFailure onFailure});

  Future<void> pushAll(List<PageRouteInfo> routes,
      {OnNavigationFailure onFailure});

  Future<void> popAndPushAll(List<PageRouteInfo> routes,
      {OnNavigationFailure onFailure});

  Future<void> replaceAll(List<PageRouteInfo> routes,
      {OnNavigationFailure onFailure});

  bool removeUntilRoot();

  bool removeWhere(RouteDataPredicate predicate);

  bool removeUntil(RouteDataPredicate predicate);

  GlobalKey<NavigatorState> get navigatorKey;

  bool removeLast();
}

@protected
class RoutingControllerScope extends InheritedWidget {
  final RoutingController controller;

  const RoutingControllerScope({
    @required Widget child,
    @required this.controller,
  }) : super(child: child);

  static RoutingControllerScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoutingControllerScope>();
  }

  @override
  bool updateShouldNotify(covariant RoutingControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

class StackRouterScope extends InheritedWidget {
  final StackRouter controller;

  const StackRouterScope({
    @required Widget child,
    @required this.controller,
  }) : super(child: child);

  static StackRouterScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StackRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant StackRouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

abstract class StackEntryItem {
  AutoRoutePage get page;

  ValueKey<PageRouteInfo> get key;

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
            routeCollection:
                parent.routeCollection.subCollectionOf(config.name),
            key: ValueKey(route),
            page: page,
            preMatchedRoutes: route.initialChildren);
      } else {
        return TreeEntry(
            parentController: parent,
            key: ValueKey(route),
            routeCollection:
                parent.routeCollection.subCollectionOf(config.name),
            pageBuilder: parent.pageBuilder,
            page: page,
            preMatchedRoutes: route.initialChildren);
      }
    } else {
      return RouteEntry(page, ValueKey(route));
    }
  }
}

class RouteEntry implements StackEntryItem {
  final AutoRoutePage page;
  final ValueKey<PageRouteInfo> key;

  const RouteEntry(this.page, this.key);

  RouteData get routeData => page.data;
}

class ParallelTreeEntry<T extends RoutingController> extends ChangeNotifier
    implements StackEntryItem, TabsRouter {
  final T parentController;
  final AutoRoutePage page;
  final ValueKey<PageRouteInfo> key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final List<StackEntryItem> _entries = [];
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
  RouteData get currentRoute => _entries[_activeIndex]?.routeData;

  @override
  int get activeIndex => _activeIndex;

  @override
  RouteData get routeData => page?.data;

  @override
  StackRouter get root => parentController?.root ?? this;

  @override
  void setActiveIndex(int index) {
    if (_activeIndex != index) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  @override
  List<AutoRoutePage> get stack =>
      List.unmodifiable(_entries.map((e) => e.page));

  StackEntryItem get _activeEntry => _entries[_activeIndex];

  @override
  RoutingController get topMost {
    var activeEntry = _activeEntry;
    if (activeEntry is RoutingController) {
      return (activeEntry as RoutingController).topMost;
    }
    return this;
  }

  @override
  T innerRouterOf<T extends RoutingController>(String routeName) {
    if (_entries.isEmpty) {
      return null;
    }
    return _entries.whereType<T>().lastWhere(
          ((controller) => controller.key.value.routeName == routeName),
          orElse: () => null,
        );
  }

  @override
  RoutingController innerRouterOfRoute(PageRouteInfo route) {
    return _entries.whereType<RoutingController>().lastWhere(
          (c) => c.key == ValueKey(route),
          orElse: () => null,
        );
  }

  @override
  bool get hasEntries => _entries.isNotEmpty;

  @override
  Future<bool> pop() {
    if (parentController != null) {
      return parentController.pop();
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  @override
  void setupRoutes(List<PageRouteInfo> routes) {
    List<PageRouteInfo> routesToPush = routes;
    if (preMatchedRoutes?.isNotEmpty == true) {
      final preMatchedRoute = preMatchedRoutes.last;
      final correspondingRouteIndex = routes.indexWhere(
        (r) => r.routeName == preMatchedRoute.routeName,
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
    _entries.clear();
    for (var route in routes) {
      final config = matcher.resolveConfigOrNull(route);
      if (config == null) {
        throw FlutterError("$this can not navigate to ${route.routeName}");
      } else {
        if (config.guards?.isNotEmpty == true) {
          throw FlutterError("Tab routes can not have guards");
        }
        final data = RouteData(
          route: route,
          parent: page?.data,
          config: config,
        );
        final entry = StackEntryItem.create(
          config: config,
          route: route,
          parent: this,
          page: pageBuilder(data),
        );
        _entries.add(entry);
      }
    }
  }
}

class TreeEntry<T extends RoutingController> extends ChangeNotifier
    implements StackEntryItem, StackRouter {
  final T parentController;
  final AutoRoutePage page;
  final ValueKey<PageRouteInfo> key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final GlobalKey<NavigatorState> navigatorKey;
  final List<StackEntryItem> _entries = [];
  final List<PageRouteInfo> preMatchedRoutes;
  RouteMatcher _lazyMatcher;

  TreeEntry({
    @required this.routeCollection,
    @required this.pageBuilder,
    this.page,
    this.key,
    this.parentController,
    this.preMatchedRoutes,
  }) : navigatorKey = GlobalKey<NavigatorState>() {
    _pushInitialRoutes();
  }

  RouteMatcher get matcher => _lazyMatcher ??= RouteMatcher(routeCollection);

  void _pushInitialRoutes() {
    if (!listNullOrEmpty(preMatchedRoutes)) {
      pushAll(preMatchedRoutes);
    } else {
      var defaultConfig = routeCollection.configWithPath('');
      if (defaultConfig != null) {
        if (defaultConfig.isRedirect) {
          pushPath(defaultConfig.redirectTo);
        } else {
          push(RouteMatch(
            config: defaultConfig,
            segments: defaultConfig.path.split('/'),
            pathParams: Parameters({}),
            queryParams: Parameters({}),
          ).toRoute);
        }
      }
    }
  }

  StackRouter get root => parentController?.root ?? this;

  T parent<T extends RoutingController>() => parentController as T;

  @override
  RouteData get currentRoute {
    if (_entries.isNotEmpty) {
      return _entries.last.routeData;
    }
    return null;
  }

  @override
  RoutingController get topMost {
    if (_entries.isNotEmpty) {
      var topEntry = _entries.last;
      if (topEntry is RoutingController) {
        return (topEntry as RoutingController).topMost;
      }
    }
    return this;
  }

  @override
  Future<bool> pop() {
    final NavigatorState navigator = navigatorKey?.currentState;
    if (navigator == null) return SynchronousFuture<bool>(false);
    if (navigator.canPop()) {
      return navigator.maybePop();
    } else if (parentController != null) {
      return parentController.pop();
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  @override
  bool removeLast() => _removeLast();

  bool _removeLast({bool notify = true}) {
    var didRemove = false;
    if (_entries.length > 1) {
      _entries.removeLast();
      if (notify) {
        notifyListeners();
      }
      didRemove = true;
    }
    return didRemove;
  }

  @override
  List<AutoRoutePage> get stack =>
      List.unmodifiable(_entries.map((e) => e.page));

  @override
  Future<void> push(PageRouteInfo route,
      {OnNavigationFailure onFailure}) async {
    return _push(route, onFailure: onFailure, notify: true);
  }

  @override
  Future<void> navigate(PageRouteInfo route,
      {OnNavigationFailure onFailure}) async {
    var entry =
        _entries.lastWhere((e) => e.key == ValueKey(route), orElse: () => null);
    if (entry != null) {
      removeUntil((d) => d.route == route);
    } else {
      return push(route, onFailure: onFailure);
    }
  }

  Future<void> _push(PageRouteInfo route,
      {OnNavigationFailure onFailure, bool notify = true}) async {
    var config = _resolveConfigOrReportFailure(route, onFailure);
    if (config == null) {
      return null;
    }
    if (await _canNavigate([route], config, onFailure)) {
      return _addStackEntry(route,
          config: config, onFailure: onFailure, notify: notify);
    }
    return null;
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure onFailure,
  }) {
    assert(_entries.isNotEmpty);
    _entries.removeLast();
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
  Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
    pop();
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
    if (_entries.length > 1) {
      _entries.removeRange(1, _entries.length);
      notifyListeners();
      didPop = true;
    }
    return didPop;
  }

  @override
  Future<void> popAndPush(PageRouteInfo route,
      {OnNavigationFailure onFailure}) {
    pop();
    return push(route, onFailure: onFailure);
  }

  @override
  bool removeUntil(RouteDataPredicate predicate) => _removeUntil(predicate);

  bool _removeUntil(RouteDataPredicate predicate, {bool notify = true}) {
    var didPop = false;
    for (var candidate in List.unmodifiable(_entries).reversed) {
      if (predicate(candidate.routeData)) {
        break;
      } else {
        _removeLast(notify: false);
        didPop = true;
      }
    }
    if (didPop && notify) {
      notifyListeners();
    }
    return didPop;
  }

  @override
  bool removeWhere(RouteDataPredicate predicate) {
    var didRemove = false;
    for (var entry in List.unmodifiable(_entries)) {
      if (predicate(entry.routeData)) {
        didRemove = true;
        _entries.remove(entry);
      }
    }
    notifyListeners();
    return didRemove;
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
        throw FlutterError(
            "[${toString()}] Router can not navigate to ${route.fullPath}");
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

  void _addEntry(StackEntryItem entry, {bool notify = true}) {
    _entries.add(entry);
    if (notify) {
      notifyListeners();
    }
  }

  StackEntryItem _createEntry(PageRouteInfo route, {RouteConfig config}) {
    final data = RouteData(
      route: route,
      parent: page?.data,
      config: config,
    );
    return StackEntryItem.create(
      config: config,
      route: route,
      page: pageBuilder(data),
      parent: this,
    );
  }

  Future<void> _replaceAll(List<PageRouteInfo> routes, {bool notify = true}) {
    assert(routes != null && routes.isNotEmpty);
    _clearHistory();
    return _pushAll(routes, notify: notify);
  }

  Future<void> updateOrReplaceRoutes(List<PageRouteInfo> routes) {
    assert(routes != null);
    var route = routes.last;
    var newKey = ValueKey(route);
    var lastKey = _entries.last.key;
    if (lastKey != null && lastKey == newKey) {
      if (route.hasChildren && _entries.last is RoutingController) {
        // this line should remove any routes below the updated one
        // not sure if this's the desired behaviour
        // List.unmodifiable(children.keys).sublist(0, stack.length - 1).forEach(_removeHistoryEntry);
        (_entries.last as TreeEntry)
            .updateOrReplaceRoutes(route.initialChildren);
      }
    } else {
      _replaceAll(routes, notify: true);
    }
    return SynchronousFuture(null);
  }

  void _clearHistory() {
    _entries.clear();
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
    var matches =
        matcher.match(path, includePrefixMatches: includePrefixMatches);
    if (matches != null) {
      var routes = matches.map((m) => m.toRoute).toList();
      return _pushAll(routes, onFailure: onFailure, notify: true);
      // ToDo validate this
    } else if (onFailure != null) {
      onFailure.call(
        RouteNotFoundFailure(
          PageRouteInfo(null, path: path),
        ),
      );
    }
    return SynchronousFuture(null);
  }

  @override
  T innerRouterOf<T extends RoutingController>(String routeName) {
    if (_entries.isEmpty) {
      return null;
    } else {
      return _entries.whereType<T>().lastWhere(
            (n) => n.key.value.routeName == routeName,
            orElse: () => null,
          );
    }
  }

  @override
  RoutingController innerRouterOfRoute(PageRouteInfo route) {
    return _entries.whereType<RoutingController>().lastWhere(
          (c) => c.key == ValueKey(route),
          orElse: () => null,
        );
  }

  @override
  bool get hasEntries => _entries.isNotEmpty;

  @override
  String toString() {
    return key?.value?.routeName ?? 'Root';
  }
}

class TabsRouterScope extends InheritedWidget {
  final TabsRouter controller;

  const TabsRouterScope({
    @required Widget child,
    @required this.controller,
  }) : super(child: child);

  static TabsRouterScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabsRouterScope>();
  }

  @override
  bool updateShouldNotify(covariant TabsRouterScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
