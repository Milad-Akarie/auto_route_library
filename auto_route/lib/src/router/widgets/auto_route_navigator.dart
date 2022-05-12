import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoRouteNavigator extends StatefulWidget {
  final StackRouter router;
  final String? navRestorationScopeId;
  final WidgetBuilder? placeholder;
  final List<NavigatorObserver> navigatorObservers;
  final RoutePopCallBack? didPop;
  final RoutesBuilder? declarativeRoutesBuilder;

  const AutoRouteNavigator({
    required this.router,
    required this.navigatorObservers,
    this.navRestorationScopeId,
    this.didPop,
    this.declarativeRoutesBuilder,
    this.placeholder,
    Key? key,
  }) : super(key: key);

  @override
  _AutoRouteNavigatorState createState() => _AutoRouteNavigatorState();
}

class _AutoRouteNavigatorState extends State<AutoRouteNavigator> {
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
            restorationScopeId:
                widget.navRestorationScopeId ?? widget.router.routeData.name,
            pages: widget.router.stack,
            onPopPage: (route, result) {
              if (!route.didPop(result)) {
                return false;
              }
              if (route.settings is AutoRoutePage) {
                var routeData = (route.settings as AutoRoutePage).routeData;
                widget.router.removeRoute(routeData);
                widget.didPop?.call(routeData.route, result);
              }
              return true;
            },
          )
        : widget.placeholder?.call(context) ??
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
            );

    // fixes nested cupertino routes back gesture issue
    if (!widget.router.isRoot) {
      return WillPopScope(
        child: navigator,
        onWillPop: widget.router.canPopSelfOrChildren
            ? () => SynchronousFuture(true)
            : null,
      );
    }

    return navigator;
  }
}
