import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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
  /// Used by [Navigator.onDidRemovePage]
  final RoutePopCallBack? didPop;

  /// Clients will use this build for declarative routing
  ///
  /// it returns a list of [PageRouteInfo]s that's handled
  /// by [router] to be finally passed to [Navigator.pages]
  final RoutesBuilder? declarativeRoutesBuilder;

  /// The clip behavior of the navigator
  final Clip clipBehavior;

  /// The traversal edge behavior of the navigator
  final TraversalEdgeBehavior? routeTraversalEdgeBehavior;

  /// Default constructor
  const AutoRouteNavigator({
    required this.router,
    required this.navigatorObservers,
    this.navRestorationScopeId,
    this.didPop,
    this.declarativeRoutesBuilder,
    this.placeholder,
    this.clipBehavior = Clip.hardEdge,
    this.routeTraversalEdgeBehavior,
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
    var newRoutes = widget.declarativeRoutesBuilder!(widget.router.pendingRoutesHandler);
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
    return widget.router.hasEntries
        ? Navigator(
            key: widget.router.navigatorKey,
            clipBehavior: widget.clipBehavior,
            routeTraversalEdgeBehavior: widget.routeTraversalEdgeBehavior ?? kDefaultRouteTraversalEdgeBehavior,
            observers: [widget.router.pagelessRoutesObserver, ...widget.navigatorObservers],
            restorationScopeId: widget.navRestorationScopeId ?? widget.router.routeData.restorationId,
            pages: widget.router.stack,
            onDidRemovePage: (page) {
              if (page is AutoRoutePage) {
                widget.router.onPopPage(page);
                widget.didPop?.call(page.routeData.route, page);
              }
            },
          )
        : widget.placeholder?.call(context) ??
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StackRouter>('router', widget.router));
    properties.add(IterableProperty<NavigatorObserver>('navigatorObservers', widget.navigatorObservers));
    properties.add(DiagnosticsProperty<RoutesBuilder>('declarativeRoutesBuilder', widget.declarativeRoutesBuilder));
    properties.add(DiagnosticsProperty<WidgetBuilder>('placeholder', widget.placeholder));
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', widget.clipBehavior));
    properties.add(DiagnosticsProperty<String?>('navRestorationScopeId', widget.navRestorationScopeId));
    properties.add(DiagnosticsProperty<RoutePopCallBack>('didPop', widget.didPop));
  }
}
