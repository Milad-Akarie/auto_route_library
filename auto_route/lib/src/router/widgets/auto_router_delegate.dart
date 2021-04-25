import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';
import '../controller/routing_controller.dart';
import 'auto_route_navigator.dart';

part 'root_stack_router.dart';

typedef RoutesBuilder = List<PageRouteInfo> Function(BuildContext context);
typedef RoutePopCallBack = void Function(PageRouteInfo route);
typedef InitialRoutesCallBack = void Function(UrlState tree);
typedef NavigatorObserversBuilder = List<NavigatorObserver> Function();

class AutoRouterDelegate extends RouterDelegate<UrlState> with ChangeNotifier {
  final List<PageRouteInfo>? initialRoutes;
  final StackRouter controller;
  final String? initialDeepLink;
  final String? navRestorationScopeId;
  final NavigatorObserversBuilder navigatorObservers;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with [Theme.scaffoldBackgroundColor].
  WidgetBuilder? placeholder;

  static List<NavigatorObserver> defaultNavigatorObserversBuilder() => const [];

  static AutoRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is AutoRouterDelegate);
    return delegate as AutoRouterDelegate;
  }

  static reportUrlChanged(BuildContext context, String url) {
    Router.of(context)
        .routeInformationProvider
        ?.routerReportsNewRouteInformation(
          RouteInformation(
            location: url,
          ),
        );
  }

  @override
  Future<bool> popRoute() => controller.topMost.pop();

  late List<NavigatorObserver> _navigatorObservers;

  AutoRouterDelegate(
    this.controller, {
    this.initialRoutes,
    this.placeholder,
    this.navRestorationScopeId,
    this.initialDeepLink,
    this.navigatorObservers = defaultNavigatorObserversBuilder,
  }) : assert(initialDeepLink == null || initialRoutes == null) {
    _navigatorObservers = navigatorObservers();
    controller.addListener(_rebuildListener);
  }

  factory AutoRouterDelegate.declarative(
    RootStackRouter controller, {
    required RoutesBuilder routes,
    String? navRestorationScopeId,
    RoutePopCallBack? onPopRoute,
    InitialRoutesCallBack? onInitialRoutes,
    NavigatorObserversBuilder navigatorObservers,
  }) = _DeclarativeAutoRouterDelegate;

  UrlState urlState = UrlState.fromRoutes(const []);

  @override
  UrlState? get currentConfiguration {
    final newState = UrlState.fromRoutes(controller.currentSegments);
    if (urlState != newState) {
      urlState = newState;
      return newState;
    }
    return null;
  }

  @override
  Future<void> setInitialRoutePath(UrlState tree) {
    // setInitialRoutePath is re-fired on enabling
    // select widget mode from flutter inspector,
    // this check is preventing it from rebuilding the app
    if (controller.hasEntries) {
      return SynchronousFuture(null);
    }

    if (initialRoutes?.isNotEmpty == true) {
      return controller.pushAll(initialRoutes!);
    } else if (initialDeepLink != null) {
      return controller.pushNamed(initialDeepLink!, includePrefixMatches: true);
    } else if (!listNullOrEmpty(tree.segments)) {
      return controller.pushAll(tree.segments);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  @override
  Future<void> setNewRoutePath(UrlState tree) {
    if (tree.hasSegments) {
      return controller.navigateAll(tree.segments);
    }
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    final segmentsHash = controller.currentSegmentsHash;
    return RoutingControllerScope(
      controller: controller,
      navigatorObservers: navigatorObservers,
      segmentsHash: segmentsHash,
      child: StackRouterScope(
        segmentsHash: segmentsHash,
        controller: controller,
        child: AutoRouteNavigator(
          router: controller,
          placeholder: placeholder,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
        ),
      ),
    );
  }

  void _rebuildListener() {
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    removeListener(_rebuildListener);
  }

  void notifyUrlChanged() {
    notifyListeners();
  }
}

class _DeclarativeAutoRouterDelegate extends AutoRouterDelegate {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final InitialRoutesCallBack? onInitialRoutes;

  _DeclarativeAutoRouterDelegate(
    RootStackRouter controller, {
    required this.routes,
    String? navRestorationScopeId,
    this.onPopRoute,
    this.onInitialRoutes,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) : super(
          controller,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: navigatorObservers,
        ) {
    controller._stackManagedByWidget = true;
  }

  @override
  Future<void> setInitialRoutePath(UrlState tree) {
    return setNewRoutePath(tree);
  }

  @override
  Future<void> setNewRoutePath(UrlState tree) {
    onInitialRoutes?.call(tree);
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    controller.updateDeclarativeRoutes(routes(context));
    final segmentsHash = controller.currentSegmentsHash;
    return RoutingControllerScope(
      controller: controller,
      navigatorObservers: navigatorObservers,
      segmentsHash: segmentsHash,
      child: StackRouterScope(
        controller: controller,
        segmentsHash: segmentsHash,
        child: AutoRouteNavigator(
          router: controller,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          didPop: onPopRoute,
        ),
      ),
    );
  }
}
