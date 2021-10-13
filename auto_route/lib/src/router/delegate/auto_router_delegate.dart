import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/matcher/route_matcher.dart';
import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/controller_scope.dart';
import 'package:auto_route/src/router/parser/route_information_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../controller/routing_controller.dart';
import '../widgets/auto_route_navigator.dart';

part 'root_stack_router.dart';

typedef RoutesBuilder = List<PageRouteInfo> Function(BuildContext context);
typedef RoutePopCallBack = void Function(RouteMatch route, dynamic results);
typedef OnNavigateCallBack = void Function(UrlState tree, bool initial);
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
          type: RouteInformationReportingType.navigate,
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
    OnNavigateCallBack? onNavigate,
    NavigatorObserversBuilder navigatorObservers,
  }) = _DeclarativeAutoRouterDelegate;

  UrlState _urlState = UrlState.fromSegments(const []);

  UrlState get urlState => _urlState;

  @override
  UrlState? get currentConfiguration => _urlState;

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
    } else if (tree.hasSegments) {
      final routes = List<PageRouteInfo>.unmodifiable(
        tree.segments.map((m) => PageRouteInfo.fromMatch(m)),
      );
      return controller.pushAll(routes);
    } else {
      throw FlutterError("Can not resolve initial route");
    }
  }

  @override
  Future<void> setNewRoutePath(UrlState state) {
    final topMost = controller.topMost;
    if (topMost is StackRouter && topMost.hasPagelessTopRoute) {
      topMost.popUntil((route) => route.settings is AutoRoutePage);
    }
    if (state.hasSegments) {
      return controller.navigateAll(state.segments);
    }
    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    final segmentsHash = controller.currentSegmentsHash;
    return RouterScope(
      controller: controller,
      navigatorObservers: _navigatorObservers,
      inheritableObserversBuilder: navigatorObservers,
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
    final newState = UrlState.fromSegments(controller.currentSegments);
    if (_urlState.url != newState.url) {
      final segments = newState.segments;
      final replace = segments.isNotEmpty &&
          (segments.last.fromRedirect ||
              (segments.last.hasEmptyPath && _urlState.path == '/'));
      _urlState = newState.copyWith(replace: replace);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    removeListener(_rebuildListener);
  }

  void notifyUrlChanged() => _rebuildListener();
}

class _DeclarativeAutoRouterDelegate extends AutoRouterDelegate {
  final RoutesBuilder routes;
  final RoutePopCallBack? onPopRoute;
  final OnNavigateCallBack? onNavigate;

  _DeclarativeAutoRouterDelegate(
    RootStackRouter controller, {
    required this.routes,
    String? navRestorationScopeId,
    this.onPopRoute,
    this.onNavigate,
    NavigatorObserversBuilder navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
  }) : super(
          controller,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: navigatorObservers,
        ) {
    controller._managedByWidget = true;
  }

  @override
  Future<void> setInitialRoutePath(UrlState tree) {
    return _onNavigate(tree, true);
  }

  @override
  Future<void> setNewRoutePath(UrlState tree) async {
    return _onNavigate(tree);
  }

  Future<void> _onNavigate(UrlState tree, [bool initial = false]) {
    _urlState = tree;
    if (tree.hasSegments) {
      controller.navigateAll(tree.segments);
    }
    if (onNavigate != null) {
      onNavigate!(tree, true);
    }

    return SynchronousFuture(null);
  }

  @override
  Widget build(BuildContext context) {
    final segmentsHash = controller.currentSegmentsHash;
    return RouterScope(
      controller: controller,
      inheritableObserversBuilder: navigatorObservers,
      segmentsHash: segmentsHash,
      navigatorObservers: _navigatorObservers,
      child: StackRouterScope(
        controller: controller,
        segmentsHash: segmentsHash,
        child: AutoRouteNavigator(
          router: controller,
          declarativeRoutesBuilder: routes,
          navRestorationScopeId: navRestorationScopeId,
          navigatorObservers: _navigatorObservers,
          didPop: onPopRoute,
        ),
      ),
    );
  }
}
