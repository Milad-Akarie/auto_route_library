import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/custom_cupertino_transitions_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AutoRoutePage<T> extends Page<T> {
  final RouteData routeData;
  final Widget child;
  final bool fullscreenDialog;
  final bool maintainState;

  final _popCompleter = Completer<T?>();

  Future<T?> get popped => _popCompleter.future;

  AutoRoutePage({
    required this.routeData,
    required this.child,
    this.fullscreenDialog = false,
    this.maintainState = true,
    LocalKey? key,
  }) : super(
          restorationId: routeData.name,
          name: routeData.name,
          arguments: routeData.route.args,
        );

  @override
  bool canUpdate(Page<dynamic> other) {
    return other.runtimeType == runtimeType && (other as AutoRoutePage).routeKey == routeKey;
  }

  LocalKey get routeKey => routeData.key;

  Widget buildPage(BuildContext context) {
    return RouteDataScope(
      child: child,
      routeData: routeData,
    );
  }

  Route<T> onCreateRoute(BuildContext context);

  @override
  Route<T> createRoute(BuildContext context) {
    return onCreateRoute(context)
      ..popped.then(
        _popCompleter.complete,
      );
  }
}

class MaterialPageX<T> extends AutoRoutePage<T> {
  MaterialPageX({
    required RouteData routeData,
    required Widget child,
    bool fullscreenDialog = false,
    bool maintainState = true,
    LocalKey? key,
  }) : super(
          routeData: routeData,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          key: key,
        );

  @override
  Route<T> onCreateRoute(BuildContext context) {
    return PageBasedMaterialPageRoute<T>(page: this);
  }
}

class PageBasedMaterialPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  PageBasedMaterialPageRoute({
    required AutoRoutePage page,
  }) : super(settings: page);

  AutoRoutePage get _page => settings as AutoRoutePage;

  List<VoidCallback> scopes = [];

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class _CustomPageBasedPageRouteBuilder<T> extends PageRoute<T> with _CustomPageRouteTransitionMixin<T> {
  _CustomPageBasedPageRouteBuilder({
    required AutoRoutePage page,
  }) : super(settings: page);

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class _NoAnimationPageRouteBuilder<T> extends PageRoute<T> with _NoAnimationPageRouteTransitionMixin<T> {
  _NoAnimationPageRouteBuilder({
    required AutoRoutePage page,
  }) : super(settings: page);

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Duration get transitionDuration => Duration.zero;
}

mixin _NoAnimationPageRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  AutoRoutePage<T> get _page => settings as AutoRoutePage<T>;

  @protected
  Widget buildContent(BuildContext context);

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => true;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is _CustomPageBasedPageRouteBuilder && !nextRoute.fullscreenDialog ||
            nextRoute is MaterialRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is _NoAnimationPageRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog);
  }

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

mixin _CustomPageRouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  CustomPage<T> get _page => settings as CustomPage<T>;

  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => Duration(
        milliseconds: _page.durationInMilliseconds,
      );

  @override
  Duration get reverseTransitionDuration => Duration(
        milliseconds: _page.reverseDurationInMilliseconds,
      );

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color? get barrierColor => _page.barrierColor == null ? null : Color(_page.barrierColor!);

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  bool get opaque => _page.opaque;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is MaterialRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is _NoAnimationPageRouteTransitionMixin && !nextRoute.fullscreenDialog) ||
        (nextRoute is CupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog);
  }

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

  Widget _defaultTransitionsBuilder(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final transitionsBuilder = _page.transitionsBuilder ?? _defaultTransitionsBuilder;
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

abstract class _TitledAutoRoutePage<T> extends AutoRoutePage<T> {
  final String? title;

  _TitledAutoRoutePage({
    required RouteData routeData,
    required Widget child,
    this.title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          routeData: routeData,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

class CupertinoPageX<T> extends _TitledAutoRoutePage<T> {
  CupertinoPageX({
    required RouteData routeData,
    required Widget child,
    String? title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          routeData: routeData,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          title: title,
        );

  @override
  Route<T> onCreateRoute(BuildContext context) {
    return _PageBasedCupertinoPageRoute<T>(page: this);
  }
}

class _PageBasedCupertinoPageRoute<T> extends PageRoute<T> with CustomCupertinoRouteTransitionMixin<T> {
  _PageBasedCupertinoPageRoute({
    required _TitledAutoRoutePage page,
  }) : super(settings: page);

  _TitledAutoRoutePage get _page => settings as _TitledAutoRoutePage;

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  String? get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class AdaptivePage<T> extends _TitledAutoRoutePage<T> {
  AdaptivePage({
    required RouteData routeData,
    required Widget child,
    String? title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          routeData: routeData,
          child: child,
          title: title,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Route<T> onCreateRoute(BuildContext context) {
    if (kIsWeb) {
      return _NoAnimationPageRouteBuilder<T>(page: this);
    }

    return PageBasedMaterialPageRoute<T>(page: this);
  }
}

typedef CustomRouteBuilder = Route<T> Function<T>(BuildContext context, Widget child, CustomPage<T> page);

class CustomPage<T> extends AutoRoutePage<T> {
  final bool opaque;
  final int durationInMilliseconds;
  final int reverseDurationInMilliseconds;
  final int? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final RouteTransitionsBuilder? transitionsBuilder;
  final CustomRouteBuilder? customRouteBuilder;

  CustomPage({
    required RouteData routeData,
    required Widget child,
    bool fullscreenDialog = false,
    bool maintainState = true,
    this.opaque = true,
    this.durationInMilliseconds = 300,
    this.reverseDurationInMilliseconds = 300,
    this.barrierColor,
    this.barrierDismissible = false,
    this.barrierLabel,
    this.transitionsBuilder,
    this.customRouteBuilder,
    LocalKey? key,
  }) : super(
          routeData: routeData,
          key: key,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Route<T> onCreateRoute(BuildContext context) {
    final result = buildPage(context);
    if (customRouteBuilder != null) {
      return customRouteBuilder!<T>(context, result, this);
    }
    return _CustomPageBasedPageRouteBuilder<T>(page: this);
  }
}
