import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/widgets.dart';

import '../../auto_route.dart';
import '../route/route_config.dart';
import 'auto_route_page.dart';
import 'controller/routing_controller.dart';

typedef PageBuilder = AutoRoutePage Function(RouteData data);
typedef PageFactory = Page<dynamic> Function(RouteData data);

abstract class RootStackRouter extends BranchEntry {
  RootStackRouter()
      : super(
          key: const ValueKey('Root'),
          routeData: RouteData(
              route: const PageRouteInfo('Root', path: ''),
              config: RouteConfig('Root', path: ''),
              key: const ValueKey('Root')),
        );

  Map<String, PageFactory> get pagesMap;

  List<RouteConfig> get routes;

  @override
  final CurrentConfigNotifier configNotifier = CurrentConfigNotifier();

  @override
  PageBuilder get pageBuilder => _pageBuilder;

  AutoRouterDelegate? _lazyRootDelegate;

  // _lazyRootDelegate is only built one time
  AutoRouterDelegate delegate({
    List<PageRouteInfo>? initialRoutes,
    String? initialDeepLink,
    String? navRestorationScopeId,
    WidgetBuilder? placeholder,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return _lazyRootDelegate ??= AutoRouterDelegate(
      this,
      initialDeepLink: initialDeepLink,
      initialRoutes: initialRoutes,
      navRestorationScopeId: navRestorationScopeId,
      navigatorObservers: navigatorObservers,
      navigatorKey: navigatorKey,
      placeholder: placeholder,
    );
  }

  DefaultRouteParser defaultRouteParser({bool includePrefixMatches = false}) =>
      DefaultRouteParser(matcher, includePrefixMatches: includePrefixMatches);

  AutoRoutePage _pageBuilder(RouteData data) {
    var builder = pagesMap[data.name];
    assert(builder != null);
    return builder!(data) as AutoRoutePage;
  }

  @override
  RouteMatcher get matcher => RouteMatcher(routeCollection);

  @override
  RouteCollection get routeCollection => RouteCollection.from(routes);
}

//
// abstract class RootStackRouter extends BranchEntry{
//   late StackRouter _router;
//
//   RootStackRouter() {
//     _router = BranchEntry(
//       routeCollection: RouteCollection.from(routes),
//       pageBuilder: _pageBuilder,
//       key: const ValueKey('Root'),
//       routeData: RouteData(
//         route: const PageRouteInfo('root', path: ''),
//         config: RouteConfig('root', path: ''),
//       ),
//     );
//   }
//
//   Map<String, PageFactory> get pagesMap;
//
//   List<RouteConfig> get routes;
//
//   @override
//   PageBuilder get pageBuilder => _pageBuilder;
//
//   AutoRouterDelegate? _lazyRootDelegate;
//
//   // _lazyRootDelegate is only built one time
//   AutoRouterDelegate delegate({
//     List<PageRouteInfo>? initialRoutes,
//     String? initialDeepLink,
//     String? navRestorationScopeId,
//     WidgetBuilder? placeholder,
//     GlobalKey<NavigatorState>? navigatorKey,
//     List<NavigatorObserver> navigatorObservers = const [],
//   }) {
//     return _lazyRootDelegate ??= AutoRouterDelegate(
//       this,
//       initialDeepLink: initialDeepLink,
//       initialRoutes: initialRoutes,
//       navRestorationScopeId: navRestorationScopeId,
//       navigatorObservers: navigatorObservers,
//       navigatorKey: navigatorKey,
//       placeholder: placeholder,
//     );
//   }
//
//   DefaultRouteParser defaultRouteParser({bool includePrefixMatches = false}) =>
//       DefaultRouteParser(matcher, includePrefixMatches: includePrefixMatches);
//
//   AutoRoutePage _pageBuilder(StackEntryItem entry) {
//     var builder = pagesMap[entry.routeData.name];
//     assert(builder != null);
//     return builder!(entry) as AutoRoutePage;
//   }
//
//   @override
//   RouteData? get current => _router.current;
//
//   @override
//   bool get hasEntries => _router.hasEntries;
//
//   @override
//   T? innerRouterOf<T extends RoutingController>(String routeName) {
//     return _router.innerRouterOf<T>(routeName);
//   }
//
//   @override
//   ValueKey<String> get key => _router.key;
//
//   @override
//   RouteMatcher get matcher => _router.matcher;
//
//   @override
//   GlobalKey<NavigatorState> get navigatorKey => _router.navigatorKey;
//
//   @override
//   Future<void> navigate(PageRouteInfo route, {onFailure}) {
//     return _router.navigate(route, onFailure: onFailure);
//   }
//
//   @override
//   T? parent<T extends RoutingController>() {
//     return _router.parent<T>();
//   }
//
//   @override
//   Future<bool> pop() => _router.pop();
//
//   @override
//   Future<void> popAndPush(PageRouteInfo route, {onFailure}) {
//     return _router.popAndPush(route, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> popAndPushAll(List<PageRouteInfo> routes, {onFailure}) {
//     return _router.popAndPushAll(routes, onFailure: onFailure);
//   }
//
//   @override
//   void popUntil(predicate) => _router.popUntil(predicate);
//
//   @override
//   void popUntilRoot() => _router.popUntilRoot();
//
//   @override
//   void popUntilRouteWithName(String name) => _router.popUntilRouteWithName(name);
//
//   @override
//   List<PageRouteInfo>? get preMatchedRoutes => null;
//
//   @override
//   Future<void> push(PageRouteInfo route, {onFailure}) {
//     return _router.push(route, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> pushAll(List<PageRouteInfo> routes, {onFailure}) {
//     return _router.pushAll(routes, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> pushAndRemoveUntil(PageRouteInfo route, {required predicate, onFailure}) {
//     return _router.pushAndRemoveUntil(route, predicate: predicate, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> pushPath(String path, {bool includePrefixMatches = false, onFailure}) {
//     return _router.pushPath(path, onFailure: onFailure);
//   }
//
//   @override
//   bool removeLast() => _router.removeLast();
//
//   @override
//   bool removeUntil(predicate) => _router.removeUntil(predicate);
//
//   @override
//   bool removeWhere(predicate) => _router.removeWhere(predicate);
//
//   @override
//   Future<void> replace(PageRouteInfo route, {onFailure}) {
//     return _router.replace(route, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> replaceAll(List<PageRouteInfo> routes, {onFailure}) {
//     return _router.replaceAll(routes, onFailure: onFailure);
//   }
//
//   @override
//   Future<void> rebuildRoutesFromUrl(List<PageRouteInfo> routes) {
//     return _router.rebuildRoutesFromUrl(routes);
//   }
//
//   @override
//   StackRouter get root => _router.root;
//
//   @override
//   RouteCollection get routeCollection => _router.routeCollection;
//
//   @override
//   RouteData? get routeData => _router.routeData;
//
//   @override
//   List<AutoRoutePage> get stack => _router.stack;
//
//   @override
//   RoutingController get topMost => _router.topMost;
//
//   @override
//   void updateDeclarativeRoutes(List<PageRouteInfo> routes, {bool notify = false}) {
//     _router.updateDeclarativeRoutes(routes, notify: notify);
//   }
//
//   @override
//   void addListener(listener) {
//     _router.addListener(listener);
//   }
//
//   @override
//   void notifyListeners() {
//     print('notifying');
//     _router.notifyListeners();
//   }
//
//   @override
//   void removeListener(listener) {
//     _router.removeListener(listener);
//   }
//
//   @override
//   bool get hasListeners => _router.hasEntries;
//   @override
//   void dispose() {
//     super.dispose();
//     _router.dispose();
//   }
//
//   @override
//   bool get isRoot => _router.isRoot;
// }
