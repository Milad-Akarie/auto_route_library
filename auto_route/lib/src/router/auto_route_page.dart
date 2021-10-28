import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/route_data_scope.dart';
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
    LocalKey? key,
    required this.routeData,
    required this.child,
    this.fullscreenDialog = false,
    this.maintainState = true,
  }) : super(
          key: key,
          restorationId: 'simple_page',
          name: routeData.name,
          arguments: routeData.route.args,
        );

  @override
  bool canUpdate(Page<dynamic> other) {
    return other.runtimeType == runtimeType &&
        (other as AutoRoutePage).routeKey == routeKey;
  }

  LocalKey get routeKey => routeData.key;

  Widget buildPage(BuildContext context) {
    var childToBuild = child;
    if (childToBuild is AutoRouteWrapper) {
      childToBuild = (childToBuild as AutoRouteWrapper).wrappedRoute(context);
    }

    return RouteDataScope(
      stateHash: routeData.hashCode,
      routeData: routeData,
      child: childToBuild,
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
    return _PageBasedMaterialPageRoute<T>(page: this);
  }
}

class _PageBasedMaterialPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _PageBasedMaterialPageRoute({
    required AutoRoutePage page,
  }) : super(settings: page);

  AutoRoutePage get _page => settings as AutoRoutePage;

  @override
  Widget buildContent(BuildContext context) => _page.buildPage(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
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

class _PageBasedCupertinoPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
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
      return PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => buildPage(context),
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }

    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _PageBasedCupertinoPageRoute<T>(page: this);
    }
    return _PageBasedMaterialPageRoute<T>(page: this);
  }
}

typedef CustomRouteBuilder = Route<T> Function<T>(
  BuildContext context,
  Widget child,
  CustomPage<T> page,
);

class CustomPage<T> extends AutoRoutePage<T> {
  final bool opaque;
  final int durationInMilliseconds;
  final int reverseDurationInMilliseconds;
  final Color? barrierColor;
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
    if (customRouteBuilder != null) {
      return customRouteBuilder!<T>(context, buildPage(context), this);
    }
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => buildPage(context),
      settings: this,
      opaque: opaque,
      transitionDuration: Duration(milliseconds: durationInMilliseconds),
      reverseTransitionDuration:
          Duration(milliseconds: reverseDurationInMilliseconds),
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      transitionsBuilder: transitionsBuilder ?? _defaultTransitionsBuilder,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
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
}
