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
    var shouldNotify = false;
    final delegate = AutoRouterDelegate.of(context);
    var newRoutes = widget.declarativeRoutesBuilder!(context);
    if (!ListEquality().equals(newRoutes, _routesSnapshot)) {
      shouldNotify = true;
      _routesSnapshot = newRoutes;
      widget.router.updateDeclarativeRoutes(newRoutes);
    } else if (!ListEquality().equals(
      delegate.urlState.segments,
      delegate.controller.currentSegments,
    )) {
      shouldNotify = true;
    }
    if (shouldNotify) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
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
    final navigator = Navigator(
      key: widget.router.navigatorKey,
      observers: widget.navigatorObservers,
      restorationScopeId:
          widget.navRestorationScopeId ?? widget.router.routeData.name,
      pages: widget.router.hasEntries
          ? widget.router.stack
          : [_PlaceHolderPage(widget.placeholder)],
      transitionDelegate: _CustomTransitionDelegate(),
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

class _PlaceHolderPage extends Page {
  final WidgetBuilder? placeholder;

  const _PlaceHolderPage(this.placeholder)
      : super(
          key: const ValueKey('_placeHolder_'),
          name: '_placeHolder_',
        );

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, __, ___) {
        return placeholder != null
            ? placeholder!(context)
            : Container(
                color: Theme.of(context).scaffoldBackgroundColor,
              );
      },
    );
  }
}

class _CustomTransitionDelegate<T> extends TransitionDelegate<T> {
  const _CustomTransitionDelegate() : super();

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord? location, bool isLast) {
      final RouteTransitionRecord? exitingPageRoute =
          locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final bool hasPagelessRoute =
            pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        final bool isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute
              .markForComplete(exitingPageRoute.route.currentResult);
        }
        if (hasPagelessRoute) {
          final List<RouteTransitionRecord> pagelessRoutes =
              pageRouteToPagelessRoutes[exitingPageRoute]!;
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            // It is possible that a pageless route that belongs to an exiting
            // page-based route does not require exiting decision. This can
            // happen if the page list is updated right after a Navigator.pop.
            if (pagelessRoute.isWaitingForExitingDecision) {
              if (isLastExitingPageRoute &&
                  pagelessRoute == pagelessRoutes.last) {
                pagelessRoute.markForPop(pagelessRoute.route.currentResult);
              } else {
                pagelessRoute
                    .markForComplete(pagelessRoute.route.currentResult);
              }
            }
          }
        }
      }
      results.add(exitingPageRoute);

      // It is possible there is another exiting route above this exitingPageRoute.
      handleExitingRoute(exitingPageRoute, isLast);
    }

    // Handles exiting route in the beginning of list.
    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      final bool isLastIteration = newPageRouteHistory.last == pageRoute;
      final bool firstPageIsPlaceHolder = results.isNotEmpty &&
          results.first.route.settings is _PlaceHolderPage;
      if (pageRoute.isWaitingForEnteringDecision) {
        if (!locationToExitingPageRoute.containsKey(pageRoute) &&
            isLastIteration &&
            !firstPageIsPlaceHolder) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }
    return results;
  }
}
