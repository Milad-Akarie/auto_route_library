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

abstract class RoutingController with ChangeNotifier {
  ValueKey<String> get key;

  RouteMatcher get matcher;

  List<AutoRoutePage> get stack;

  T? parent<T extends RoutingController>();

  StackRouter get root;

  bool get isRoot;

  RoutingController get topMost;

  RouteData? get current;

  RouteData? get routeData;

  RouteCollection get routeCollection;

  bool get hasEntries;

  T? innerRouterOf<T extends RoutingController>(String routeName);

  List<PageRouteInfo>? get preMatchedRoutes;

  PageBuilder get pageBuilder;

  Future<bool> pop();

  bool get canPop;

  List<PageRouteInfo> get currentConfig;

  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parent);

  void notifyChildrenChanged(RouteData parent, List<PageRouteInfo> children) {}

  CurrentConfigNotifier get configNotifier;
}

abstract class TabsRouter extends RoutingController {
  void setActiveIndex(int index);

  StackRouter? stackRouterOfIndex(int index);

  int get activeIndex;

  void setupRoutes(List<PageRouteInfo> routes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TabsRouter && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

abstract class StackRouter extends RoutingController {
  Future<void> push(PageRouteInfo route, {OnNavigationFailure? onFailure});

  Future<void> navigate(PageRouteInfo route, {OnNavigationFailure? onFailure});

  Future<void> pushPath(String path, {bool includePrefixMatches = false, OnNavigationFailure? onFailure});

  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure? onFailure});

  Future<void> pushAndRemoveUntil(PageRouteInfo route,
      {required RoutePredicate predicate, OnNavigationFailure? onFailure});

  Future<void> replace(PageRouteInfo route, {OnNavigationFailure? onFailure});

  Future<void> pushAll(List<PageRouteInfo> routes, {OnNavigationFailure? onFailure});

  Future<void> popAndPushAll(List<PageRouteInfo> routes, {OnNavigationFailure? onFailure});

  Future<void> replaceAll(List<PageRouteInfo> routes, {OnNavigationFailure? onFailure});

  void popUntilRoot();

  bool removeWhere(RouteDataPredicate predicate);

  bool removeUntil(RouteDataPredicate predicate);

  void popUntil(RoutePredicate predicate);

  void popUntilRouteWithName(String name);

  void updateDeclarativeRoutes(
    List<PageRouteInfo> routes, {
    bool notify = false,
  });

  GlobalKey<NavigatorState> get navigatorKey;

  bool removeLast();

  void removeRoute(RouteData route);

  Future<void> rebuildRoutesFromUrl(List<PageRouteInfo> routes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StackRouter && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

class ParallelBranchEntry extends TabsRouter {
  final RoutingController? parentController;
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

  ParallelBranchEntry({
    required this.routeCollection,
    required this.pageBuilder,
    required this.key,
    required this.routeData,
    required this.configNotifier,
    this.parentController,
    this.preMatchedRoutes,
  }) : matcher = RouteMatcher(routeCollection) {
    if (parentController != null) {
      addListener(() {
        // routeData.updateActiveChild(current!);
        // parentController!.notifyListeners();
        // parentController!.notifyChildrenChanged(routeData, _pages.map((e) => e.routeData.route).toList());
        configNotifier.value = current?.route.updateChildren(children: _pages.map((e) => e.routeData.route).toList());
      });
    }
  }

  @override
  bool get isRoot => parentController == null;

  @override
  T? parent<T extends RoutingController>() {
    return parentController == null ? null : parentController as T;
  }

  @override
  RouteData? get current {
    if (_activeIndex < _pages.length) {
      return _pages[_activeIndex].routeData;
    } else {
      return routeData;
    }
  }

  @override
  int get activeIndex => _activeIndex;

  @override
  StackRouter get root => parentController?.root ?? this as StackRouter;

  @override
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
  String toString() => '${routeData.name} Router';

  @override
  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_pages.isEmpty) {
      return null;
    }
    return _pages.map((p) => p.routeData).whereType<T>().lastOrNull(
          ((c) => c.routeData?.name == routeName),
        );
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;

  @override
  Future<bool> pop() {
    if (parentController != null) {
      return parentController!.pop();
    } else {
      return SynchronousFuture<bool>(false);
    }
  }

  @override
  void setupRoutes(List<PageRouteInfo> routes) {
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
        final data = RouteData(route: route, parent: this.routeData, config: config, key: ValueKey(route.stringMatch));
        pageBuilder(data);
        _pages.add(pageBuilder(data));
      }
    }
  }

  Future<void> updateRoutes(List<PageRouteInfo> routes) {
    assert(routes.isNotEmpty);
    final preMatchedRoute = routes.last;
    final mayUpdateKey = ValueKey<String>(preMatchedRoute.stringMatch);

    final pageToUpdateIndex = _pages.indexWhere(
      (p) => p.routeData.key == mayUpdateKey,
    );

    if (pageToUpdateIndex != -1) {
      setActiveIndex(pageToUpdateIndex);
      var mayUpdateController = _subControllers[mayUpdateKey];
      if (mayUpdateController != null && preMatchedRoute.hasInitialChildren) {
        if (mayUpdateController is StackRouter) {
          return mayUpdateController.rebuildRoutesFromUrl(preMatchedRoute.initialChildren!);
        } else if (mayUpdateController is ParallelBranchEntry) {
          return mayUpdateController.updateRoutes(preMatchedRoute.initialChildren!);
        }
      }
    }
    return SynchronousFuture(null);
  }

  @override
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
    // var activeEntry = _activePage?.routeData;
    // if (activeEntry != null) {
    //   routes.add(activeEntry.routeData.route);
    //   if (activeEntry is RoutingController) {
    //     routes.addAll((activeEntry as RoutingController).currentConfig);
    //   }
    // }
    return routes;
  }

  @override
  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parentRoute) {
    print("Creating controller for  ----> ${parentRoute.name}");
    var existingController = _subControllers[parentRoute.key];
    if (existingController != null) {
      return existingController as T;
    }
    if (T == TabsRouter) {
      return _subControllers[parentRoute.key] = ParallelBranchEntry(
          parentController: this,
          pageBuilder: pageBuilder,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          key: parentRoute.key,
          routeData: parentRoute,
          configNotifier: configNotifier,
          preMatchedRoutes: parentRoute.route.initialChildren);
    } else if (T == StackRouter) {
      return _subControllers[parentRoute.key] = SubBranchEntry(
          parentController: this,
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

class SubBranchEntry extends BranchEntry {
  final RouteMatcher matcher;
  final RouteCollection routeCollection;
  final PageBuilder pageBuilder;
  final CurrentConfigNotifier configNotifier;

  SubBranchEntry({
    required this.routeCollection,
    required this.pageBuilder,
    required ValueKey<String> key,
    required RouteData routeData,
    required this.configNotifier,
    required RoutingController parentController,
    List<PageRouteInfo>? preMatchedRoutes,
  })  : matcher = RouteMatcher(routeCollection),
        super(
          key: key,
          routeData: routeData,
          preMatchedRoutes: preMatchedRoutes,
          parentController: parentController,
        ) {
    _pushInitialRoutes();
  }
}

abstract class BranchEntry extends StackRouter {
  final RoutingController? parentController;
  final ValueKey<String> key;

  final RouteData routeData;
  final GlobalKey<NavigatorState> navigatorKey;
  final List<PageRouteInfo>? preMatchedRoutes;
  final List<AutoRoutePage> _pages = [];
  final Map<ValueKey<String>, RoutingController> _subControllers = {};

  BranchEntry({
    required this.key,
    required this.routeData,
    this.parentController,
    this.preMatchedRoutes,
  }) : navigatorKey = GlobalKey<NavigatorState>() {
    if (parentController != null) {
      addListener(() {
        configNotifier.value = current?.route.updateChildren(children: _pages.map((e) => e.routeData.route).toList());
        // routeData.updateActiveChild(current!);
        // parentController!.notifyListeners();
        // parentController!.notifyChildrenChanged(routeData, _pages.map((e) => e.routeData.route).toList());
        // parentController!.notifyChildrenChanged(routeData, _pages.map((e) => e.routeData.route).toList());
      });
    }
  }

  RouteCollection get routeCollection;

  PageBuilder get pageBuilder;

  RouteMatcher get matcher;

  @override
  void notifyChildrenChanged(RouteData parent, List<PageRouteInfo> children) {
    // var page = _pages.lastOrNull((p) => p.routeData.key == parent.key);
    // if (page != null) {
    //
    // }
    // parent.updateActiveChild(children);
    notifyListeners();
  }

  @override
  RoutingController findOrCreateChildController<T extends RoutingController>(RouteData parentRoute) {
    var existingController = _subControllers[parentRoute.key];
    if (existingController != null) {
      return existingController as T;
    }
    print("Creating controller for  ----> ${parentRoute.name}");

    if (T == TabsRouter) {
      return _subControllers[parentRoute.key] = ParallelBranchEntry(
          parentController: this,
          pageBuilder: pageBuilder,
          configNotifier: configNotifier,
          routeCollection: routeCollection.subCollectionOf(parentRoute.name),
          key: parentRoute.key,
          routeData: parentRoute,
          preMatchedRoutes: parentRoute.route.initialChildren);
    } else if (T == StackRouter) {
      return _subControllers[parentRoute.key] = SubBranchEntry(
          parentController: this,
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
    final routes = <PageRouteInfo>[];
    // var activeEntry = (_pages.isEmpty) ? null : _pages.last.routeData;
    // if (activeEntry != null) {
    //   routes.add(activeEntry.routeData.route);
    //   if (activeEntry is RoutingController) {
    //     routes.addAll((activeEntry as RoutingController).currentConfig);
    //   }
    // }
    return routes;
  }

  @override
  bool get canPop {
    return _pages.length > 1;
  }

  StackRouter get root => parentController?.root ?? this;

  @override
  T? parent<T extends RoutingController>() {
    return parentController == null ? null : parentController as T;
  }

  @override
  RouteData? get current {
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
    } else if (parentController != null) {
      return parentController!.pop();
    } else {
      return false;
    }
  }

  @override
  bool removeLast() => _removeLast();

  @override
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

  @override
  Future<void> push(PageRouteInfo route, {OnNavigationFailure? onFailure}) async {
    return _push(route, onFailure: onFailure, notify: true);
  }

  @override
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
      return _addStackEntry(route, config: config, onFailure: onFailure, notify: notify);
    }
    return null;
  }

  @override
  Future<void> replace(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) {
    assert(_pages.isNotEmpty);
    _pages.removeLast();
    return push(route, onFailure: onFailure);
  }

  @override
  Future<void> pushAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    return _pushAll(routes, onFailure: onFailure, notify: true);
  }

  @override
  Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
    pop();
    return _pushAll(routes, onFailure: onFailure);
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
  }) {
    _clearHistory();
    return _pushAll(routes, onFailure: onFailure);
  }

  @override
  void popUntilRoot() {
    assert(navigatorKey.currentState != null);
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Future<void> popAndPush(PageRouteInfo route, {OnNavigationFailure? onFailure}) {
    pop();
    return push(route, onFailure: onFailure);
  }

  @override
  bool removeUntil(RouteDataPredicate predicate) => _removeUntil(predicate);

  @override
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

  @override
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

  @override
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
      var entry = _createRouteData(route, config: config);
      _addEntry(pageBuilder(entry), notify: notify);
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
    var data = _createRouteData(route, config: config);
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

  RouteData _createRouteData(PageRouteInfo route, {required RouteConfig config}) {
    var routeToPush = route;
    if (config.isSubTree && !route.hasInitialChildren) {
      var matches = RouteMatcher(config.children!).match('');
      if (matches != null) {
        routeToPush = route.updateChildren(
          children: matches.map((m) => PageRouteInfo.fromMatch(m)).toList(),
        );
      }
    }
    return RouteData(
      route: routeToPush,
      parent: routeData,
      config: config,
      key: ValueKey(routeToPush.stringMatch),
    );
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
        if (mayUpdateController is BranchEntry) {
          await mayUpdateController.rebuildRoutesFromUrl(mayUpdateRoute.initialChildren ?? const []);
        } else if (mayUpdateController is ParallelBranchEntry) {
          await mayUpdateController.updateRoutes(mayUpdateRoute.initialChildren!);
        }
      }
    }
    return _replaceAll(routes, notify: true);
  }

  void _clearHistory() {
    _pages.clear();
  }

  @override
  Future<void> pushAndRemoveUntil(
    PageRouteInfo route, {
    required RoutePredicate predicate,
    OnNavigationFailure? onFailure,
  }) {
    popUntil(predicate);
    return push(route, onFailure: onFailure);
  }

  @override
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

  @override
  void popUntilRouteWithName(String name) {
    popUntil(ModalRoute.withName(name));
  }

  @override
  T? innerRouterOf<T extends RoutingController>(String routeName) {
    if (_pages.isEmpty) {
      return null;
    }
    return _pages.map((p) => p.routeData).whereType<T>().lastOrNull(
          ((c) => c.routeData?.name == routeName),
        );
  }

  @override
  bool get hasEntries => _pages.isNotEmpty;

  @override
  String toString() => '${routeData.name} Router';

  @override
  bool get isRoot => parentController == null;
}
