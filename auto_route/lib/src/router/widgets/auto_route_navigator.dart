import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

/// An AutoRoute Wrapper for [Navigator]
/// it handles empty stacks and declarative routes
class AutoRouteNavigator extends StatefulWidget {
  /// The router that handles the pages stack
  /// passed to [Navigator.pages]
  final StackRouter router;

  /// The navigator restoration key
  /// passed to [Navigator.restorationScopeId]
  final String? navRestorationScopeId;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with [Theme.scaffoldBackgroundColor].
  final WidgetBuilder? placeholder;

  /// The observers to observer navigator's navigation events
  ///
  /// Passed ot [Navigator.observers]
  final List<NavigatorObserver> navigatorObservers;

  /// A callback to report popped [AutoRoutePage]s
  /// Used by [Navigator.onPopPage]
  final RoutePopCallBack? didPop;

  /// Clients will use this build for declarative routing
  ///
  /// it returns a list of [PageRouteInfo]s that's handled
  /// by [router] to be finally passed to [Navigator.pages]
  final RoutesBuilder? declarativeRoutesBuilder;

  /// Default constructor
  const AutoRouteNavigator({
    required this.router,
    required this.navigatorObservers,
    this.navRestorationScopeId,
    this.didPop,
    this.declarativeRoutesBuilder,
    this.placeholder,
    super.key,
  });

  @override
  AutoRouteNavigatorState createState() => AutoRouteNavigatorState();
}

/// State of [AutoRouteNavigator]
class AutoRouteNavigatorState extends State<AutoRouteNavigator> {
  List<PageRouteInfo>? _routesSnapshot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.declarativeRoutesBuilder != null && _routesSnapshot == null) {
      _updateDeclarativeRoutes();
    }
  }

  void _updateDeclarativeRoutes() {
    final delegate = AutoRouterDelegate.of(context);
    var newRoutes =
        widget.declarativeRoutesBuilder!(widget.router.pendingRoutesHandler);
    if (!const ListEquality().equals(newRoutes, _routesSnapshot)) {
      _routesSnapshot = newRoutes;
      widget.router.updateDeclarativeRoutes(newRoutes);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        delegate.notifyUrlChanged();
      });
    }
  }

  @override
  void didUpdateWidget(covariant AutoRouteNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.declarativeRoutesBuilder != null) {
      _updateDeclarativeRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = widget.router.hasEntries
        ? Navigator(
            key: widget.router.navigatorKey,
            observers: [
              widget.router.pagelessRoutesObserver,
              ...widget.navigatorObservers
            ],
            restorationScopeId: widget.navRestorationScopeId ??
                widget.router.routeData.restorationId,
            pages: widget.router.stack,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              if (route.settings is AutoRoutePage) {
                var routeData = (route.settings as AutoRoutePage).routeData;
                widget.router.onPopPage(route, routeData);
                widget.didPop?.call(routeData.route, result);
              }
              route.onPopInvoked(true);
              return true;
            },
          )
        : widget.placeholder?.call(context) ??
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            );

    return navigator;
  }
}
