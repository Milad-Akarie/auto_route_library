import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/utils.dart';
import 'package:flutter/cupertino.dart';

import '../matcher/route_matcher.dart';

@immutable
class AutoRoute {
  final String name;
  final String _path;
  final bool fullMatch;
  final RouteCollection? _children;
  final String? redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesPathAsKey;
  final Map<String, dynamic> meta;
  final RouteType? type;
  final bool fullscreenDialog;
  final bool maintainState;

  AutoRoute._({
    required this.name,
    String? path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.type,
    this.meta = const {},
    this.maintainState = true,
    this.fullscreenDialog = false,
    List<AutoRoute>? children,
  })  : _path = path ?? toKababCase(name),
        _children = children != null ? RouteCollection.from(children) : null;

  factory AutoRoute({
    required Type name,
    String? path,
    bool usesPathAsKey = false,
    List<AutoRouteGuard> guards = const [],
    bool fullMatch = false,
    String? redirectTo,
    RouteType? type,
    Map<String, dynamic> meta = const {},
    bool maintainState = true,
    bool fullscreenDialog = false,
    List<AutoRoute>? children,
  }) {
    return AutoRoute._(
      name: name.toString(),
      path: path,
      fullMatch: fullMatch,
      maintainState: maintainState,
      fullscreenDialog: fullMatch,
      meta: meta,
      type: type,
      usesPathAsKey: usesPathAsKey,
      guards: guards,
      redirectTo: redirectTo,
    );
  }

  String get path => _path;

  bool get hasSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }
}

@immutable
class RedirectRoute extends AutoRoute {
  RedirectRoute({
    required super.path,
    required String redirectTo,
  }) : super._(
          name: 'Redirect#$path',
          fullMatch: true,
          redirectTo: redirectTo,
        );
}

@immutable
class MaterialRoute extends AutoRoute {
  MaterialRoute({
    required Type name,
    super.path,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
  }) : super._(
          name: name.toString(),
          type: const RouteType.material(),
        );
}

@immutable
class CupertinoRoute extends AutoRoute {
  /// passed to the title property in [CupertinoPageRoute]
  final String? title;

  CupertinoRoute({
    required Type name,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    this.title,
  }) : super._(name: name.toString(), type: const RouteType.cupertino());
}

@immutable
class AdaptiveRoute extends AutoRoute {
  AdaptiveRoute({
    required Type name,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    String? cupertinoPageTitle,
    bool opaque = true,
  }) : super._(
          name: name.toString(),
          type: RouteType.adaptive(
            cupertinoPageTitle: cupertinoPageTitle,
            opaque: opaque,
          ),
        );
}

@immutable
class CustomRoute extends AutoRoute {
  CustomRoute({
    required Type name,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    Function? transitionsBuilder,
    Function? customRouteBuilder,
    int? durationInMilliseconds,
    int? reverseDurationInMilliseconds,
    bool opaque = true,
    bool barrierDismissible = true,
    String? barrierLabel,
    int? barrierColor,
  }) : super._(
          name: name.toString(),
          type: RouteType.custom(
            transitionsBuilder: transitionsBuilder,
            customRouteBuilder: customRouteBuilder,
            durationInMilliseconds: durationInMilliseconds,
            reverseDurationInMilliseconds: reverseDurationInMilliseconds,
            opaque: opaque,
            barrierDismissible: barrierDismissible,
            barrierLabel: barrierLabel,
            barrierColor: barrierColor,
          ),
        );
}
