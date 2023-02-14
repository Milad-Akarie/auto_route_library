import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/router/widgets/custom_cupertino_transitions_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AutoRoutePage<T> extends Page<T> {
  final RouteData routeData;
  final Widget _child;
  final bool fullscreenDialog;
  final bool maintainState;
  final bool opaque;

  final _popCompleter = Completer<T?>();

  Future<T?> get popped => _popCompleter.future;

  Widget get child => _child;

  AutoRoutePage({
    required this.routeData,
    required Widget child,
    this.fullscreenDialog = false,
    this.maintainState = true,
    this.opaque = true,
    LocalKey? key,
  })  : _child = child is AutoRouteWrapper ? WrappedRoute(child: child as AutoRouteWrapper) : child,
        super(
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
      routeData: routeData,
      child: _child,
    );
  }

  Route<T> onCreateRoute(BuildContext context) {
    final type = routeData.type;
    final title = routeData.title(context);
    if (type is MaterialRouteType) {
      return PageBasedMaterialPageRoute<T>(page: this);
    } else if (type is CupertinoRouteType) {
      return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
    } else if (type is CustomRouteType) {
      final result = buildPage(context);
      if (type.customRouteBuilder != null) {
        return type.customRouteBuilder!<T>(context, result, this);
      }
      return _CustomPageBasedPageRouteBuilder<T>(page: this, routeType: type);
    } else if (type is AdaptiveRouteType) {
      if (kIsWeb) {
        return _NoAnimationPageRouteBuilder(page: this);
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.linux:
        case TargetPlatform.windows:
        case TargetPlatform.fuchsia:
        case TargetPlatform.android:
          return PageBasedMaterialPageRoute<T>(page: this);
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
          return _PageBasedCupertinoPageRoute<T>(page: this, title: title);
      }
    }
    return PageBasedMaterialPageRoute<T>(page: this);
  }

  @override
  Route<T> createRoute(BuildContext context) {
    return onCreateRoute(context)
      ..popped.then(
        _popCompleter.complete,
      );
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
    required this.routeType,
  }) : super(settings: page);

  @override
  final CustomRouteType routeType;

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
  bool get opaque => _page.opaque;

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
  AutoRoutePage<T> get _page => settings as AutoRoutePage<T>;

  CustomRouteType get routeType;

  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => Duration(
        milliseconds: routeType.durationInMilliseconds ?? 300,
      );

  @override
  Duration get reverseTransitionDuration => Duration(
        milliseconds: routeType.reverseDurationInMilliseconds ?? 300,
      );

  @override
  bool get barrierDismissible => routeType.barrierDismissible;

  @override
  Color? get barrierColor => routeType.barrierColor == null ? null : Color(routeType.barrierColor!);

  @override
  String? get barrierLabel => routeType.barrierLabel;

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

class _PageBasedCupertinoPageRoute<T> extends PageRoute<T> with CustomCupertinoRouteTransitionMixin<T> {
  _PageBasedCupertinoPageRoute({
    required AutoRoutePage<T> page,
    this.title,
  }) : super(settings: page);

  AutoRoutePage<T> get _page => settings as AutoRoutePage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  final String? title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

typedef CustomRouteBuilder = Route<T> Function<T>(
  BuildContext context,
  Widget child,
  AutoRoutePage<T> page,
  CustomRouteType type,
);
