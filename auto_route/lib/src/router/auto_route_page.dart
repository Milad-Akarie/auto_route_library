import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/transitions/flutter_material_theme.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:material_ui/material_ui.dart';

part 'transitions/predictive_back_phase.dart';

// The pages a navigator has shown; see [AutoRoutePage.markShown].
final _shownPages = Expando<bool>();

// The routes of the pages the app took off the stack itself; see
// [AutoRoutePage.markRemoved].
final _removedRoutes = Expando<bool>();

/// Creates a RoutePage based on `routeData.type`,
/// The decision happens inside of [onCreateRoute]
class AutoRoutePage<T> extends Page<T> {
  /// Default constructor
  new({required this.routeData, required Widget child})
    // A page widget can implement AutoRouteWrapper to wrap itself.
    : _child = switch (child) {
        final AutoRouteWrapper wrapper => WrappedRoute(child: wrapper),
        _ => child,
      },
      super(
        restorationId: routeData.restorationId,
        name: routeData.name,
        arguments: routeData.route.args,
        key: routeData.matchId,
      );

  /// The Route Data that's used to build the page
  final RouteData<Object?> routeData;
  final Widget _child;

  /// Whether to treat the built route as a fullscreenDialog.
  /// Passed To [PageRoute.fullscreenDialog]
  bool get fullscreenDialog => routeData.route.fullscreenDialog;

  /// Whether the built route should maintain it's state.
  /// Passed To [PageRoute.maintainState]
  bool get maintainState => routeData.route.maintainState;

  /// Whether the built route should be opaque
  /// Passed To [PageRoute.opaque]
  bool get opaque => routeData.type.opaque;

  /// Whether the built route should allow snapshotting
  /// Passed To [PageRoute.allowSnapshotting]
  bool get allowSnapshotting => routeData.route.allowSnapshotting;

  /// The key that's used to decide whether
  /// This page can be updated or not
  /// used by [canUpdate]
  LocalKey get routeKey => routeData.key;

  /// The widget passed to the route
  Widget get child => _child;

  /// Records that the [Navigator] has shown this page, so it now holds a
  /// route of its own.
  ///
  /// Called by [AutoRouteNavigator] for the pages of its previous build. A
  /// shown page only updates its own route in [canUpdate].
  @internal
  void markShown() => _shownPages[this] = true;

  /// Records that the app took this page off the stack itself, with
  /// [StackRouter.removeLast], [StackRouter.removeRoute],
  /// [StackRouter.removeWhere] or [StackRouter.removeUntil].
  ///
  /// The route of a removed page leaves with it: a new page of the same route
  /// pushed before the navigator rebuilds is a page of its own (#1204).
  @internal
  void markRemoved() => _removedRoutes[routeData] = true;

  /// Whether the app took this page off the stack itself; see [markRemoved].
  @internal
  bool get isRemoved => _removedRoutes[routeData] ?? false;

  /// Builds a new page of the same type for [routeData], e.g. after its args
  /// changed.
  ///
  /// The new page has the same key, so it takes over this page's route.
  @internal
  AutoRoutePage<T> rebuild() => routeData.buildPage();

  /// Whether this page can take over the route that [other] is showing.
  ///
  /// A new page takes over the route of a page with the same [routeKey] in the
  /// same stack, so replacing a route with itself updates the page in place.
  /// A page the navigator already shows keeps its own route: when a page with
  /// the same [routeKey] is removed from below it, the page must not take the
  /// removed page's route and leave its own to be popped. Nor does a new page
  /// take the route of a page the app removed itself, see [markRemoved].
  @override
  bool canUpdate(Page<Object?> other) {
    final canUpdate =
        other.runtimeType == runtimeType &&
        (other as AutoRoutePage).routeKey == routeKey &&
        routeData.stackKey == other.routeData.stackKey &&
        (other.key == key || (_shownPages[this] != true && !other.isRemoved));
    return canUpdate;
  }

  @override
  PopInvokedWithResultCallback<T> get onPopInvoked {
    return (didPop, result) {
      if (didPop) {
        final router = routeData.router;
        // As Route.didComplete does, a pop without a result, such as the
        // back gesture, completes with the route's currentResult.
        final shownRoute = router is StackRouter
            ? router.pagelessRoutesObserver.routeOf(this)
            : null;
        routeData
          ..onPoppedByNavigator()
          ..onPopInvoked(result ?? shownRoute?.currentResult as T?);
      }
    };
  }

  /// Builds the page's widget, scoped with [routeData].
  ///
  /// The widget's semantics carry the route's name as their
  /// `Semantics.identifier`, so UI testing tools, and
  /// `find.bySemanticsIdentifier` in widget tests, find the page by its route
  /// name, whatever its route type.
  // Public API: changing it is the maintainer's call.
  Widget buildPage(BuildContext context) {
    // explicitChildNodes keeps the page's own nodes apart, as the route's
    // scopesRoute node above does.
    return Semantics(
      identifier: routeData.name,
      explicitChildNodes: true,
      child: RouteDataScope(routeData: routeData, child: _child),
    );
  }

  /// Creates a PageRoute variant based on
  /// `routeData.type`
  Route<T> onCreateRoute(BuildContext context) {
    final type = routeData.type;
    final title = routeData.title(context);
    if (type is MaterialRouteType) {
      return _PageBasedMaterialPageRoute<T>(
        page: this,
        enablePredictiveBackGesture: type.enablePredictiveBackGesture,
        predictiveBackPageTransitionsBuilder:
            type.predictiveBackPageTransitionsBuilder,
      );
    } else if (type is CupertinoRouteType) {
      return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
    } else if (type is CustomRouteType) {
      if (type.customRouteBuilder != null) {
        return type.customRouteBuilder!<T>(
          context,
          _CurrentPageChild(page: this),
          this,
        );
      }
      return _CustomPageBasedPageRouteBuilder<T>(
        page: this,
        routeType: type,
        enablePredictiveBackGesture: type.enablePredictiveBackGesture,
        predictiveBackPageTransitionsBuilder:
            type.predictiveBackPageTransitionsBuilder,
      );
    } else if (type is AdaptiveRouteType) {
      if (kIsWeb) {
        return _NoAnimationPageRouteBuilder(page: this);
      } else if ([
        TargetPlatform.macOS,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform)) {
        return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
      }
      return _PageBasedMaterialPageRoute<T>(
        page: this,
        enablePredictiveBackGesture: type.enablePredictiveBackGesture,
        predictiveBackPageTransitionsBuilder:
            type.predictiveBackPageTransitionsBuilder,
      );
    }
    return _PageBasedMaterialPageRoute<T>(page: this);
  }

  @override
  Route<T> createRoute(BuildContext context) {
    return onCreateRoute(context);
  }
}

/// The child handed to [CustomRouteType.customRouteBuilder].
///
/// The route that builder returns keeps this child for its whole life, while
/// the navigator gives the route a new page whenever its data changes, for
/// example new query params. So this builds the page the route holds now, and
/// rebuilds whenever the page's router changes.
class _CurrentPageChild extends StatelessWidget {
  const new({required this.page});

  /// The page the route was created with.
  final AutoRoutePage<Object?> page;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: page.routeData.router,
      builder: (context, _) {
        final route = ModalRoute.of(context);
        final settings = route?.settings;
        final current = settings is AutoRoutePage ? settings : page;
        // The route is the app's own, so it can't set it as auto_route's do.
        current.routeData.animation ??= route?.animation;
        return current.buildPage(context);
      },
    );
  }
}

class _PageBasedMaterialPageRoute<T> extends _PageRoute<T>
    with
        MaterialRouteTransitionMixin<T>,
        _FlutterMaterialThemeTransitionMixin<T>,
        _CustomPredictiveBackGestureMixin<T> {
  new({
    required super.page,
    this.enablePredictiveBackGesture = false,
    this.predictiveBackPageTransitionsBuilder,
  });

  @override
  final bool enablePredictiveBackGesture;

  @override
  final RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder;

  @override
  Widget buildContent(BuildContext context) {
    return _page.buildPage(context);
  }
}

/// Takes the page transitions from the app's theme when it comes from
/// package:flutter/material.dart, see [flutterMaterialThemeOf]; otherwise
/// [MaterialRouteTransitionMixin] reads the theme of package:material_ui.
mixin _FlutterMaterialThemeTransitionMixin<T>
    on MaterialRouteTransitionMixin<T> {
  @override
  Duration get transitionDuration {
    final theme = flutterMaterialThemeOf(navigator!.context);
    if (theme == null) return super.transitionDuration;
    return flutterPageTransitionsBuilderOf(theme).transitionDuration;
  }

  @override
  Duration get reverseTransitionDuration {
    final theme = flutterMaterialThemeOf(navigator!.context);
    if (theme == null) return super.reverseTransitionDuration;
    return flutterPageTransitionsBuilderOf(theme).reverseTransitionDuration;
  }

  // The route below takes the delegated transition of the route above only
  // when it differs from its own, and keeps it. So this stays the function of
  // MaterialRouteTransitionMixin unless Flutter's theme is the nearer one, and
  // is static either way: a method would hold this route after it's popped.
  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final navigator = this.navigator;
    if (navigator == null ||
        flutterMaterialThemeOf(navigator.context) == null) {
      return super.delegatedTransition;
    }
    return _flutterThemeDelegatedTransition;
  }

  static Widget? _flutterThemeDelegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    final flutterTheme = flutterMaterialThemeOf(context);
    final themeDelegatedTransition = flutterTheme != null
        ? flutterTheme.pageTransitionsTheme.delegatedTransition(
            flutterTheme.platform,
          )
        : Theme.of(context).pageTransitionsTheme
              .delegatedTransition(Theme.of(context).platform);
    return themeDelegatedTransition?.call(
      context,
      animation,
      secondaryAnimation,
      allowSnapshotting,
      child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = flutterMaterialThemeOf(context);
    if (theme == null) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return theme.pageTransitionsTheme.buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

class _CustomPageBasedPageRouteBuilder<T> extends _PageRoute<T>
    with
        _CustomPageRouteTransitionMixin<T>,
        _CustomPredictiveBackGestureMixin<T> {
  new({
    required super.page,
    required this.routeType,
    required this.enablePredictiveBackGesture,
    required this.predictiveBackPageTransitionsBuilder,
  });

  @override
  final CustomRouteType routeType;

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  final bool enablePredictiveBackGesture;

  @override
  final RouteTransitionsBuilder? predictiveBackPageTransitionsBuilder;

  @override
  bool get barrierDismissible => routeType.barrierDismissible;

  @override
  Color? get barrierColor => routeType.barrierColor;

  @override
  String? get barrierLabel => routeType.barrierLabel;
}

class _NoAnimationPageRouteBuilder<T> extends _PageRoute<T>
    with _NoAnimationPageRouteTransitionMixin<T> {
  new({required super.page});

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  Duration get transitionDuration => .zero;
}

mixin _NoAnimationPageRouteTransitionMixin<T> on _PageRoute<T> {
  @protected
  Widget buildContent(BuildContext context);

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => _page.opaque;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: buildContent(context),
    );
  }
}

mixin _CustomPageRouteTransitionMixin<T> on _PageRoute<T> {
  /// Builds the primary contents of the route.

  CustomRouteType get routeType;

  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration =>
      routeType.duration ?? const .new(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration =>
      routeType.reverseDuration ?? const .new(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: buildContent(context),
    );
  }

  Widget _defaultTransitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionsBuilder =
        routeType.transitionsBuilder ?? _defaultTransitionsBuilder;
    final transitions = transitionsBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );
    final platform =
        flutterMaterialThemeOf(context)?.platform ?? Theme.of(context).platform;
    if (!routeType.enableCupertinoBackGesture ||
        (platform != .iOS && platform != .macOS)) {
      return transitions;
    }
    // Flutter's iOS back gesture comes only with its slide transition, which
    // moves nothing when its animations stand still. The gesture drives this
    // route's own animation, so the page follows the finger through its
    // custom transition.
    return CupertinoRouteTransitionMixin.buildPageTransitions(
      this,
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      transitions,
    );
  }
}

class _PageBasedCupertinoPageRoute<T> extends _PageRoute<T>
    with
        CupertinoRouteTransitionMixin<T>,
        CupertinoRouteTransitionOverrideMixin<T> {
  new({required super.page, required this.title});

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  final String title;
}

mixin _CustomPredictiveBackGestureMixin<T> on _PageRoute<T>
    implements PredictiveBackGestureMixin {
  late final _predictiveBackTransitions =
      const PredictiveBackPageTransitionsBuilder();
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform =
        flutterMaterialThemeOf(context)?.platform ?? Theme.of(context).platform;
    if (!enablePredictiveBackGesture || platform != .android) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    if (predictiveBackPageTransitionsBuilder == null) {
      return _predictiveBackTransitions.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return _PredictiveBackGestureDetector(
      route: this,
      builder: (context, phase, startBackEvent, currentBackEvent) {
        if (popGestureInProgress) {
          return predictiveBackPageTransitionsBuilder!(
            context,
            animation,
            secondaryAnimation,
            child,
          );
        }
        return super.buildTransitions(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
    );
  }
}

abstract class _PageRoute<T> extends PageRoute<T> {
  new({required AutoRoutePage<Object?> page}) : super(settings: page);

  AutoRoutePage<Object?> get _page => settings as AutoRoutePage;

  @override
  bool get popGestureEnabled {
    /// This fixes the issue of nested navigators back-gesture
    /// It prevents back-gesture on parent navigator if sub-router
    /// can pop
    if (super.popGestureEnabled) {
      final router = _page.routeData.router;
      // A page in a hidden tab stays mounted, and its predictive back
      // detector still listens; the gesture belongs to the tab on screen.
      if (!router.isInActiveTabs) return false;
      final topMostRouter = router.topMostRouter();
      return router.isTopMost ||
          !topMostRouter.canPop(
            ignoreParentRoutes: true,
            ignorePagelessRoutes: true,
          );
    }
    return false;
  }

  @override
  void install() {
    super.install();
    _page.routeData.animation = animation;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get allowSnapshotting => _page.allowSnapshotting;

  @override
  bool get opaque => _page.opaque;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.routeData.name})';

  @override
  bool canTransitionTo(TransitionRoute<Object?> nextRoute) {
    return (nextRoute is _CustomPageBasedPageRouteBuilder &&
                !nextRoute.fullscreenDialog ||
            nextRoute is MaterialRouteTransitionMixin &&
                !nextRoute.fullscreenDialog) ||
        (nextRoute is _NoAnimationPageRouteTransitionMixin &&
            !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoRouteTransitionMixin &&
            !nextRoute.fullscreenDialog);
  }
}
