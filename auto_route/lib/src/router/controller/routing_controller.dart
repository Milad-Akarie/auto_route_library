import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/navigation_failure.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/route/route_config.dart';
import 'package:auto_route/src/router/auto_route_page.dart';
import 'package:auto_route/src/router/root_stack_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:treeify/treeify.dart';

import '../../utils.dart';

typedef RouteDataPredicate = bool Function(RouteData route);

abstract class RoutingController with ChangeNotifier {
  ValueKey<String> get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  RoutingController? get _parent;

  T? parent<T extends RoutingController>() {
    return _parent == null ? null : _parent as T;
  }

  RoutingController get root => _parent?.root ?? this;

  StackRouter get rootAsStackRouter => root as StackRouter;

  StackRouter? get parentAsStackRouter => parent<StackRouter>();

  bool get isRoot => _parent == null;

  RoutingController get topMost;

  RouteData get current;

  RouteData get routeData;

  RouteCollection get routeCollection;

  bool get hasEntries;

  T? innerRouterOf<T extends RoutingController>(String routeName);

  List<PageRouteInfo>? get preMatchedRoutes;

  PageBuilder get pageBuilder;

  Future<bool> pop();

  bool get canPop;

  List<PageRouteInfo> get currentConfig;

  @override
  String toString() => '${routeData.name} Router';

  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parent);

  Future<void> rebuildRoutesFromUrl(List<PageRouteInfo> routes);

  CurrentConfigNotifier get configNotifier;
}

class TabsRouter extends RoutingController {
  final RoutingController? _parent;
  final ValueKey<String> key;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final RouteMatcher matcher;
  final RouteData routeData;
  final CurrentConfigNotifier configNotifier;
  final List<PageRouteInfo>? preMatchedRoutes;
  int _activeIndex = 0;
  final List<AutoRoutePage> _pages = [];
  final Map<ValueKey<String>, RoutingController> _subControllers = {};

  late List<PageRouteInfo> _routes;

  TabsRouter({
    required this.routeCollection,
    required this.pageBuilder,
    required this.key,
    required this.routeData,
    required this.configNotifier,
    RoutingController? parent,
    this.preMatchedRoutes,
  })  : matcher = RouteMatcher(routeCollection),
        _parent = parent {
    if (parent != null) {
      addListener(() {
        routeData.activeChild = current;
        parent.notifyListeners();
      });
    }
  }

  RouteData get current {
    if (_activeIndex < _pages.length) {
      return _pages[_activeIndex].routeData;
    } else {
      return routeData;
    }
  }

  int get activeIndex => _activeIndex;

  void setActiveIndex(int index) {
    assert(index >= 0 && index < _pages.length);
    if (_activeIndex != index) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  AutoRoutePage? get _activePage {
    return _pages.isEmpty ? null : _pages[_activeIndex];
  }

  @override
  RoutingController get topMost {
    var activeKey = _activePage?.routeData.key;
    if (_subControllers.containsKey(activeKey)) {
      return _subControllers[activeKey]!.topMost;
    }
    return this;
  }

  @override
  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_pages.isEmpty) {
      return null;
    }
    return _pages.map((p) => p.routeData).whereType<T>().lastOrNull(
          ((c) => c.routeData.name == routeName),
        );
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;

  @override
  Future<bool> pop() {
    if (_parent != null) {
      return _parent!.pop();
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  void setupRoutes(List<PageRouteInfo> routes) {
    _routes = routes;
    _setupRoutes(routes, preMatchedRoutes);
  }

  void _setupRoutes(List<PageRouteInfo> routes, List<PageRouteInfo>? preMatchedRoutes) {
    final routesToPush = List.of(routes);
    if (preMatchedRoutes?.isNotEmpty == true) {
      final preMatchedRoute = preMatchedRoutes!.last;
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
    if (routesToPush.isNotEmpty) {
      _pushAll(routesToPush);
    }
  }

  void _pushAll(List<PageRouteInfo> routes) {
    _pages.clear();
    for (var route in routes) {
      final config = matcher.resolveConfigOrNull(route);
      if (config == null) {
        throw FlutterError("$this can not navigate to ${route.routeName}");
      } else {
        if (config.guards.isNotEmpty == true) {
          throw FlutterError("Tab routes can not have guards");
        }
        final data = _createRouteData(route, config, routeData);
        pageBuilder(data);
        _pages.add(pageBuilder(data));
      }
    }
  }

  @override
  Future<void> rebuildRoutesFromUrl(List<PageRouteInfo> routes) {
    // _setupRoutes(this._routes, routes);
    // return SynchronousFuture(null);
    if (routes.isNotEmpty) {
      final preMatchedRoute = routes.last;
      final mayUpdateKey = ValueKey<String>(preMatchedRoute.stringMatch);
      final pageToUpdateIndex = _pages.indexWhere(
        (p) => p.routeData.key == mayUpdateKey,
      );

      if (pageToUpdateIndex != -1) {
        setActiveIndex(pageToUpdateIndex);
        var mayUpdateController = _subControllers[mayUpdateKey];
        if (mayUpdateController != null && preMatchedRoute.hasInitialChildren) {
          return mayUpdateController.rebuildRoutesFromUrl(preMatchedRoute.initialChildren!);
        }
      }
    }
    return SynchronousFuture(null);
  }

  StackRouter? stackRouterOfIndex(int index) {
    if (_pages.isEmpty) {
      return null;
    }
    if (_pages[index].routeData is StackRouter) {
      return _pages[index].routeData as StackRouter;
    } else {
      return null;
    }
  }

  @override
  bool get canPop => false;

  @override
  List<PageRouteInfo> get currentConfig {
    final routes = <PageRouteInfo>[];
    var currentData = _activePage?.routeData;
    if (currentData != null) {
      routes.add(currentData.route);
      if (_subControllers.containsKey(currentData.key)) {
        routes.addAll(_subControllers[currentData.key]!.currentConfig);
      }
      if (routes.length == 1 && currentData.activeChild != null) {
        routes.addAll(currentData.activeChild!.routeSegments);
      }
    }
    return routes;
  }

  @override
  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parentRoute) {
    // var existingController = _subControllers[parentRoute.key];
    // if (existingController != null) {
    //   return existingController as T;
    // }
    print('creating controller for -----> ${parentRoute.name}');
    if (T == TabsRouter) {
      return _subControllers[parentRoute.key] = TabsRouter(
          parent: this,
          pageBuilder: pageBuilder,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          key: parentRoute.key,
          routeData: parentRoute,
          configNotifier: configNotifier,
          preMatchedRoutes: parentRoute.route.initialChildren);
    } else if (T == StackRouter) {
      return _subControllers[parentRoute.key] = NestedStackRouter(
          parent: this,
          key: parentRoute.key,
          routeData: parentRoute,
          configNotifier: configNotifier,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          pageBuilder: pageBuilder,
          preMatchedRoutes: parentRoute.route.initialChildren);
    }
    throw FlutterError('Unsupported controller $T');
  }
}

abstract class StackRouter extends RoutingController {
  final RoutingController? _parent;
  final ValueKey<String> key;

  final RouteData routeData;
  final GlobalKey<NavigatorState> navigatorKey;
  final List<PageRouteInfo>? preMatchedRoutes;
  final List<AutoRoutePage> _pages = [];
  final Map<ValueKey<String>, RoutingController> _subControllers = {};

  StackRouter({
    required this.key,
    required this.routeData,
    RoutingController? parent,
    this.preMatchedRoutes,
  })  : navigatorKey = GlobalKey<NavigatorState>(),
        _parent = parent {
    if (parent != null) {
      addListener(() {
        routeData.activeChild = current;
        parent.notifyListeners();
        // configNotifier.value = current.route.updateChildren(children: _pages.map((e) => e.routeData.route).toList());
        // routeData.updateActiveChild(current!);
        // _parent!.notifyListeners();
        // _parent!.notifyChildrenChanged(routeData, _pages.map((e) => e.routeData.route).toList());
        // _parent!.notifyChildrenChanged(routeData, _pages.map((e) => e.routeData.route).toList());
      });
    }
  }

  RouteCollection get routeCollection;

  PageBuilder get pageBuilder;

  RouteMatcher get matcher;

  var _historyManagedByWidget = false;

  @override
  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parentRoute) {
    // var existingController = _subControllers[parentRoute.key];
    // if (existingController != null) {
    //   return existingController as T;
    // }
    print("Creating controller for  ----> ${parentRoute.name}");

    if (T == TabsRouter) {
      return _subControllers[parentRoute.key] = TabsRouter(
          parent: this,
          pageBuilder: pageBuilder,
          configNotifier: configNotifier,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          key: parentRoute.key,
          routeData: parentRoute,
          preMatchedRoutes: parentRoute.route.initialChildren);
    } else if (T == StackRouter) {
      return _subControllers[parentRoute.key] = NestedStackRouter(
          parent: this,
          key: parentRoute.key,
          configNotifier: configNotifier,
          routeData: parentRoute,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          pageBuilder: pageBuilder,
          preMatchedRoutes: parentRoute.route.initialChildren);
    } else {
      throw FlutterError('Unsupported controller $T');
    }
  }

  void _pushInitialRoutes() {
    if (preMatchedRoutes?.isNotEmpty == true) {
      pushAll(preMatchedRoutes!);
    }
  }

  @override
  List<PageRouteInfo> get currentConfig {
    final segments = <PageRouteInfo>[];
    var currentData = (_pages.isEmpty) ? null : _pages.last.routeData;
    if (currentData != null) {
      segments.add(currentData.route);
      if (_subControllers.containsKey(currentData.key)) {
        segments.addAll(_subControllers[currentData.key]!.currentConfig);
      }
      if (segments.length == 1 && currentData.activeChild != null) {
        segments.addAll(currentData.activeChild!.routeSegments);
      }
    }
    return segments;
  }

  @override
  bool get canPop {
    return _pages.length > 1;
  }

  @override
  RouteData get current {
    if (_pages.isNotEmpty) {
      return _pages.last.routeData;
    }
    return routeData;
  }

  @override
  RoutingController get topMost {
    if (_pages.isNotEmpty) {
      var topRouteKey = _pages.last.routeData.key;
      if (_subControllers.containsKey(topRouteKey)) {
        return _subControllers[topRouteKey]!.topMost;
      }
    }
    return this;
  }

  @override
  Future<bool> pop() async {
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) return SynchronousFuture<bool>(false);
    if (await navigator.maybePop()) {
      return true;
    } else if (_parent != null) {
      return _parent!.pop();
    } else {
      return false;
    }
  }

  bool removeLast() => _removeLast();

  void removeRoute(RouteData route) {
    _pages.removeWhere((p) => p.routeData.key == route.key);
    if (_subControllers.containsKey(route.key)) {
      // _subControllers[route.key]!.dispose();
      _subControllers.remove(route.key);
    }
    notifyListeners();
  }

  bool _removeLast({bool notify = true}) {
    var didRemove = false;
    if (_pages.isNotEmpty) {
      _pages.removeLast();
      if (notify) {
        notifyListeners();
      }
      didRemove = true;
    }
    return didRemove;
  }

  @override
  List<AutoRoutePage> get stack => List.unmodifiable(_pages);

  Future<void> push(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    // return _push(route, onFailure: onFailure, notify: true);
    // print(_findHandler(route));

    // print(Treeify.asTree(Map.fromEntries(routeCollection.routes.map((e) => MapEntry(e.name, ''))), true));
    return _findHandler(route)._push(route, onFailure: onFailure);
  }

  StackRouter _findHandler(PageRouteInfo route) {
    if (_parent == null || _canHandleNavigation(route)) {
      // print('Handler is ${this.routeData.name}');
      return this;
    }

    void getParentStackRouter(RoutingController currentParent, List<StackRouter> all) {
      if (currentParent is StackRouter) {
        all.add(currentParent);
      } else if (currentParent._parent != null) {
        getParentStackRouter(currentParent._parent!, all);
      }
    }

    var allParentStackRouters = <StackRouter>[];
    getParentStackRouter(_parent!, allParentStackRouters);
    return allParentStackRouters.firstWhere((c) => c._canHandleNavigation(route), orElse: () => this);
  }

  bool _canHandleNavigation(PageRouteInfo route) {
    return routeCollection.containsKey(route.routeName);
  }

  Future<void> navigate(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    var page = _pages.lastOrNull((p) => p.routeData.key == ValueKey(route.stringMatch));
    if (page != null) {
      for (var candidate in List<AutoRoutePage>.unmodifiable(_pages).reversed) {
        if (candidate == page) {
          break;
        } else {
          _removeLast(notify: false);
        }
      }
      notifyListeners();
    } else {
      return push(route, onFailure: onFailure);
    }
  }

  Future<void> _push(PageRouteInfo route, {OnNavigationFailure? onFailure, bool notify = true}) async {
    var config = _resolveConfigOrReportFailure(route, onFailure);
    if (config == null) {
      return null;
    }
    if (await _canNavigate([route], config, onFailure)) {
      _addStackEntry(route, config: config, onFailure: onFailure, notify: notify);
    }
    return null;
  }

  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    assert(_pages.isNotEmpty);
    _pages.removeLast();
    return push(route, onFailure: onFailure);
  }

  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    return _pushAll(routes, onFailure: onFailure, notify: true);
  }

  Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
    pop();
    return _pushAll(routes, onFailure: onFailure);
  }

  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    _clearHistory();
    return _pushAll(routes, onFailure: onFailure);
  }

  void popUntilRoot() {
    assert(navigatorKey.currentState != null);
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure? onFailure}) {
    pop();
    return push(route, onFailure: onFailure);
  }

  bool removeUntil(RouteDataPredicate predicate) => _removeUntil(predicate);

  void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState?.popUntil(predicate);
  }

  bool _removeUntil(RouteDataPredicate predicate, {bool notify = true}) {
    var didRemove = false;
    for (var candidate in List.unmodifiable(_pages).reversed) {
      if (predicate(candidate.routeData)) {
        break;
      } else {
        _removeLast(notify: false);
        didRemove = true;
      }
    }
    if (didRemove && notify) {
      notifyListeners();
    }
    return didRemove;
  }

  bool removeWhere(RouteDataPredicate predicate) {
    var didRemove = false;
    for (var entry in List.unmodifiable(_pages)) {
      if (predicate(entry.routeData)) {
        didRemove = true;
        _pages.remove(entry);
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
      final data = _createRouteData(route, config, routeData);
      _addEntry(pageBuilder(data), notify: notify);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
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

  RouteConfig? _resolveConfigOrReportFailure(
    PageRouteInfo route, [
    OnNavigationFailure? onFailure,
  ]) {
    var config = matcher.resolveConfigOrNull(route);
    if (config != null) {
      return config;
    } else {
      if (onFailure != null) {
        onFailure(RouteNotFoundFailure(route));
        return null;
      } else {
        throw FlutterError("[${toString()}] Router can not navigate to ${route.fullPath}");
      }
    }
  }

  void _addStackEntry(
    PageRouteInfo route, {
    required RouteConfig config,
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) {
    final data = _createRouteData(route, config, routeData);
    _addEntry(pageBuilder(data), notify: notify);
  }

  Future<bool> _canNavigate(
    List<PageRouteInfo> routes,
    RouteConfig config,
    OnNavigationFailure? onFailure,
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

  void _addEntry(AutoRoutePage page, {bool notify = true}) {
    _pages.add(page);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _replaceAll(List<PageRouteInfo> routes, {bool notify = true}) {
    _clearHistory();
    return _pushAll(routes, notify: notify);
  }

  @override
  Future<void> rebuildRoutesFromUrl(List<PageRouteInfo> routes) async {
    if (routes.isNotEmpty) {
      final mayUpdateRoute = routes.last;
      final mayUpdateKey = ValueKey<String>(mayUpdateRoute.stringMatch);
      final mayUpdateController = _subControllers[mayUpdateKey];
      if (mayUpdateController != null) {
        removeUntil((route) => route.key == mayUpdateKey);
        await mayUpdateController.rebuildRoutesFromUrl(
          mayUpdateRoute.initialChildren ?? const [],
        );
      }
    }
    return _replaceAll(routes, notify: true);
  }

  void _clearHistory() {
    _pages.clear();
  }

  @Deprecated('Use pushAndPopUntil')
  Future<void> pushAndRemoveUntil(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    OnNavigationFailure? onFailure,
  }) {
    return pushAndPopUntil(route, predicate: predicate, onFailure: onFailure);
  }

  Future<void> pushAndPopUntil(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    OnNavigationFailure? onFailure,
  }) {
    popUntil(predicate);
    return push(route, onFailure: onFailure);
  }

  Future<void> pushPath(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) {
    var matches = matcher.match(path, includePrefixMatches: includePrefixMatches);
    if (matches != null) {
      var routes = matches.map((m) => PageRouteInfo.fromMatch(m)).toList();
      return _pushAll(routes, onFailure: onFailure, notify: true);
    } else if (onFailure != null) {
      onFailure.call(
        RouteNotFoundFailure(
          PageRouteInfo('', path: path),
        ),
      );
    }
    return SynchronousFuture(null);
  }

  void popUntilRouteWithName(String name) {
    popUntil(ModalRoute.withName(name));
  }

  @override
  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_subControllers.isEmpty) {
      return null;
    }
    return _subControllers.values.whereType<T>().lastOrNull(
          ((c) => c.routeData.name == routeName),
        );
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;
}

RouteData _createRouteData(PageRouteInfo route, RouteConfig config, RouteData parent) {
  var routeToPush = route;
  if (config.isSubTree && !route.hasInitialChildren) {
    var matches = RouteMatcher(config.children!).match('');
    if (matches != null) {
      routeToPush = route.updateChildren(
        children: matches.map((m) => PageRouteInfo.fromMatch(m)).toList(),
      );
    }
  }
  final data = RouteData(
    route: routeToPush,
    parent: parent,
    config: config,
    key: ValueKey(routeToPush.stringMatch),
  );
  return data;
}

class NestedStackRouter extends StackRouter {
  final RouteMatcher matcher;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final CurrentConfigNotifier configNotifier;

  NestedStackRouter({
    required this.routeCollection,
    required this.pageBuilder,
    required ValueKey<String> key,
    required RouteData routeData,
    required this.configNotifier,
    required RoutingController parent,
    List<PageRouteInfo>? preMatchedRoutes,
  })  : matcher = RouteMatcher(routeCollection),
        super(
          key: key,
          routeData: routeData,
          preMatchedRoutes: preMatchedRoutes,
          parent: parent,
        ) {
    _pushInitialRoutes();
  }
}
