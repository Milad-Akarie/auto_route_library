import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;

part 'transitions/predictive_back_page_detector.dart';

/// Creates a RoutePage based on [routeData.type],
/// The decision happens inside of [onCreateRoute]
class AutoRoutePage<T> extends Page<T> {
  /// The Route Data that's used to build the page
  final RouteData routeData;
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

  /// Default constructor
  AutoRoutePage({
    required this.routeData,
    required Widget child,
  })  : _child = child is AutoRouteWrapper ? WrappedRoute(child: child as AutoRouteWrapper) : child,
        super(
          restorationId: routeData.restorationId,
          name: routeData.name,
          arguments: routeData.route.args,
          key: routeData.matchId,
        );

  @override
  bool canUpdate(Page<dynamic> other) {
    final canUpdate = other.runtimeType == runtimeType &&
        (other as AutoRoutePage).routeKey == routeKey &&
        routeData.stackKey == other.routeData.stackKey;
    return canUpdate;
  }

  @override
  PopInvokedWithResultCallback<T> get onPopInvoked {
    return (didPop, result) {
      if (didPop) {
        routeData.onPopInvoked(result);
      }
    };
  }

  /// Builds a the widget that's scoped
  /// with [routeData]
  Widget buildPage(BuildContext context) {
    return RouteDataScope(
      routeData: routeData,
      child: _child,
    );
  }

  /// Creates a PageRoute variant based on
  /// [routeData.type]
  Route<T> onCreateRoute(BuildContext context) {
    final type = routeData.type;
    final title = routeData.title(context);
    if (type is MaterialRouteType) {
      return _PageBasedMaterialPageRoute<T>(
        page: this,
        enablePredictiveBackGesture: type.enablePredictiveBackGesture,
        predictiveBackPageTransitionsBuilder: type.predictiveBackPageTransitionsBuilder,
      );
    } else if (type is CupertinoRouteType) {
      return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
    } else if (type is CustomRouteType) {
      final result = buildPage(context);
      if (type.customRouteBuilder != null) {
        return type.customRouteBuilder!.call<T>(context, result, this);
      }
      return _CustomPageBasedPageRouteBuilder<T>(
        page: this,
        routeType: type,
        enablePredictiveBackGesture: type.enablePredictiveBackGesture,
        predictiveBackPageTransitionsBuilder: type.predictiveBackPageTransitionsBuilder,
      );
    } else if (type is AdaptiveRouteType) {
      if (kIsWeb) {
        return _NoAnimationPageRouteBuilder(page: this);
      } else if ([TargetPlatform.macOS, TargetPlatform.iOS].contains(defaultTargetPlatform)) {
        return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
      } else {
        return _PageBasedMaterialPageRoute<T>(
          page: this,
          enablePredictiveBackGesture: type.enablePredictiveBackGesture,
          predictiveBackPageTransitionsBuilder: type.predictiveBackPageTransitionsBuilder,
        );
      }
    }
    return _PageBasedMaterialPageRoute<T>(page: this);
  }

  @override
  Route<T> createRoute(BuildContext context) {
    return onCreateRoute(context);
  }
}

class _PageBasedMaterialPageRoute<T> extends _PageRoute<T>
    with MaterialRouteTransitionMixin<T>, _CustomPredictiveBackGestureMixin<T> {
  _PageBasedMaterialPageRoute({
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

class _CustomPageBasedPageRouteBuilder<T> extends _PageRoute<T>
    with _CustomPageRouteTransitionMixin<T>, _CustomPredictiveBackGestureMixin<T> {
  _CustomPageBasedPageRouteBuilder({
    required super.page,
    required this.routeType,
    this.enablePredictiveBackGesture = false,
    this.predictiveBackPageTransitionsBuilder,
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
  Color? get barrierColor => routeType.barrierColor;

  @override
  String? get barrierLabel => routeType.barrierLabel;
}

class _NoAnimationPageRouteBuilder<T> extends _PageRoute<T> with _NoAnimationPageRouteTransitionMixin<T> {
  _NoAnimationPageRouteBuilder({required super.page});

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  Duration get transitionDuration => Duration.zero;
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
  Duration get transitionDuration => routeType.duration ?? const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => routeType.reverseDuration ?? const Duration(milliseconds: 300);

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
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final transitionsBuilder = routeType.transitionsBuilder ?? _defaultTransitionsBuilder;
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

class _PageBasedCupertinoPageRoute<T> extends _PageRoute<T>
    with CupertinoRouteTransitionMixin<T>, CupertinoRouteTransitionOverrideMixin<T> {
  _PageBasedCupertinoPageRoute({required super.page, this.title});

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  final String? title;
}

mixin _CustomPredictiveBackGestureMixin<T> on _PageRoute<T> implements PredictiveBackGestureMixin {
  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (!enablePredictiveBackGesture || Theme.of(context).platform != TargetPlatform.android) {
      return super.buildTransitions(context, animation, secondaryAnimation, child);
    }

    if (predictiveBackPageTransitionsBuilder == null) {
      return const PredictiveBackPageTransitionsBuilder().buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return _PredictiveBackGestureDetector(
      route: this,
      builder: (context) {
        if (popGestureInProgress) {
          return predictiveBackPageTransitionsBuilder!.call(context, animation, secondaryAnimation, child);
        } else {
          return super.buildTransitions(context, animation, secondaryAnimation, child);
        }
      },
    );
  }
}

abstract class _PageRoute<T> extends PageRoute<T> {
  _PageRoute({
    required AutoRoutePage page,
  }) : super(settings: page);

  AutoRoutePage get _page => settings as AutoRoutePage;

  @override
  bool get popGestureEnabled {
    /// This fixes the issue of nested navigators back-gesture
    /// It prevents back-gesture on parent navigator if sub-router
    /// can pop
    if (super.popGestureEnabled) {
      final router = _page.routeData.router;
      final topMostRouter = router.topMostRouter();
      return (router.isTopMost ||
          !topMostRouter.canPop(
            ignoreParentRoutes: true,
            ignorePagelessRoutes: true,
          ));
    }
    return false;
  }

  @override
  void install() {
    super.install();
    _page.routeData.setAnimation(animation);
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
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  bool canTransitionTo(TransitionRoute nextRoute) {
    return (nextRoute is _CustomPageBasedPageRouteBuilder && !nextRoute.fullscreenDialog ||
            nextRoute is MaterialRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is _NoAnimationPageRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog);
  }
}
