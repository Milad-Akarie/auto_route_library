import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// An AutoRoute Wrapper for [Navigator]
/// it handles empty stacks and declarative routes
class AutoRouteNavigator extends StatefulWidget {
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

  /// The router that handles the pages stack
  /// passed to [Navigator.pages]
  final StackRouter router;

  /// The navigator restoration key
  /// passed to [Navigator.restorationScopeId]
  final String? navRestorationScopeId;

  /// A builder for the placeholder page that is shown
  /// before the first route can be rendered. Defaults to
  /// an empty page with `Theme.scaffoldBackgroundColor`.
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

  @override
  AutoRouteNavigatorState createState() => .new();
}

/// State of [AutoRouteNavigator]
class AutoRouteNavigatorState extends State<AutoRouteNavigator> {
  List<PageRouteInfo>? _routesSnapshot;
  // The ancestors' routers, owned by them; this state only listens.
  // ignore: dispose-fields
  List<TabsRouter> _ancestorTabs = const [];
  late bool _inActiveTabs = widget.router.isInActiveTabs;

  @override
  void initState() {
    super.initState();
    _listenToAncestorTabs();
    _topPageKey = widget.router.stack.lastOrNull?.key;
    widget.router.addListener(_handleStackChanged);
  }

  // The fingers down on this navigator's pages, by pointer id.
  final _activePointers = <int>{};
  LocalKey? _topPageKey;

  // Navigator.push and pop cancel the fingers that are down, so a second
  // finger can't tap something on the page left behind. A Navigator given
  // pages doesn't, so it is done here when the top page changes: of two
  // buttons pressed at once, only the first opens its page.
  void _handleStackChanged() {
    final topPageKey = widget.router.stack.lastOrNull?.key;
    if (topPageKey == _topPageKey) return;
    _topPageKey = topPageKey;
    _activePointers.toList().forEach(WidgetsBinding.instance.cancelPointer);
  }

  // A tab switch above this navigator decides whether it takes back.
  void _listenToAncestorTabs() {
    for (final tabs in _ancestorTabs) {
      tabs.removeListener(_handleAncestorTabsChanged);
    }
    _ancestorTabs = widget.router.isRoot ? const [] : widget.router.ancestorTabsRouters;
    for (final tabs in _ancestorTabs) {
      // Removed again when the ancestors change and in dispose.
      // ignore: always-remove-listener
      tabs.addListener(_handleAncestorTabsChanged);
    }
  }

  void _handleAncestorTabsChanged() {
    final inActiveTabs = widget.router.isInActiveTabs;
    if (mounted && inActiveTabs != _inActiveTabs) {
      setState(() => _inActiveTabs = inActiveTabs);
    }
  }

  @override
  void dispose() {
    widget.router.removeListener(_handleStackChanged);
    for (final tabs in _ancestorTabs) {
      tabs.removeListener(_handleAncestorTabsChanged);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.declarativeRoutesBuilder != null && _routesSnapshot == null) {
      _updateDeclarativeRoutes();
    }
  }

  void _updateDeclarativeRoutes() {
    final delegate = AutoRouterDelegate.of(context);
    final newRoutes = widget.declarativeRoutesBuilder!(widget.router.pendingRoutesHandler);
    if (!const ListEquality<dynamic>().equals(newRoutes, _routesSnapshot)) {
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
    if (widget.router != oldWidget.router) {
      oldWidget.router.removeListener(_handleStackChanged);
      widget.router.addListener(_handleStackChanged);
      _topPageKey = widget.router.stack.lastOrNull?.key;
      _listenToAncestorTabs();
      _inActiveTabs = widget.router.isInActiveTabs;
    }
    if (widget.declarativeRoutesBuilder != null) {
      _updateDeclarativeRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Listener(
      onPointerDown: (event) => _activePointers.add(event.pointer),
      onPointerUp: (event) => _activePointers.remove(event.pointer),
      onPointerCancel: (event) => _activePointers.remove(event.pointer),
      // A widget class would add an element and move the state below it.
      // ignore: avoid-returning-widgets
      child: _buildNavigator(context),
    );
    if (widget.router.isRoot) return navigator;
    // A nested navigator sits on a page of its parent's navigator. While it
    // can take back itself, NavigatorPopHandler turns off that page's back
    // swipe, keeps Android sending back to Flutter, and passes the page's
    // pops down to it. A hidden tab's navigator does none of that: the tabs
    // share one page, and back belongs to the tab on screen. Its navigator
    // still tells NavigatorPopHandler whether it can take back, for when the
    // tab shows again, but not the app.
    return NotificationListener<NavigationNotification>(
      onNotification: (_) => !_inActiveTabs,
      child: NavigatorPopHandler<Object?>(
        enabled: widget.router.hasEntries && _inActiveTabs,
        onPopWithResult: (result) => widget.router.navigatorKey.currentState?.maybePop(result),
        child: navigator,
      ),
    );
  }

  // The pages handed to the Navigator by the previous build.
  List<AutoRoutePage<dynamic>> _shownPages = const [];

  Widget _buildNavigator(BuildContext context) {
    // Each page of the previous build now holds a route; mark it before the
    // Navigator matches the new pages to its routes.
    for (final page in _shownPages) {
      page.markShown();
    }
    _shownPages = widget.router.hasEntries ? widget.router.stack : const [];
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
        : (widget.placeholder?.call(context) ??
              // A Container with no child fills its space; a ColoredBox would shrink to nothing.
              // ignore: banned-usage
              Container(color: Theme.of(context).scaffoldBackgroundColor));
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
