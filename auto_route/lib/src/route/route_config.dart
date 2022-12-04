import 'package:auto_route/auto_route.dart';

import '../matcher/route_matcher.dart';

class AutoRouteConfig {
  final String name;
  final String path;
  final bool fullMatch;
  final RouteCollection? _children;
  final String? redirectTo;
  final List<AutoRouteGuard> guards;
  final bool usesPathAsKey;
  final Map<String, dynamic> meta;
  final RouteType? type;

  AutoRouteConfig(
    this.name, {
    required this.path,
    this.usesPathAsKey = false,
    this.guards = const [],
    this.fullMatch = false,
    this.redirectTo,
    this.type,
    this.meta = const {},
    List<AutoRouteConfig>? children,
  }) : _children = children != null ? RouteCollection.from(children) : null;

  bool get hasSubTree => _children != null;

  RouteCollection? get children => _children;

  bool get isRedirect => redirectTo != null;

  @override
  String toString() {
    return 'RouteConfig{name: $name}';
  }
}

class RedirectRoute extends AutoRouteConfig {
  RedirectRoute({
    required super.path,
    required String redirectTo,
  }) : super('Redirect#$path',fullMatch: true,redirectTo: redirectTo);
}

class AutoRoute extends AutoRouteConfig {
  final PageInfo page;
  final bool fullscreenDialog;
  final bool maintainState;

  AutoRoute({
    required this.page,
    super.usesPathAsKey = false,
    super.guards = const [],
    super.fullMatch = false,
    super.meta = const {},
    super.children,
    super.type,
    this.fullscreenDialog = false,
    this.maintainState = true,
  }) : super(
          page.name,
          path: page.path,
        );
}

class MaterialRoute extends AutoRoute {
  MaterialRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
  }) : super(type: const RouteType.material());
}

class CupertinoRoute extends AutoRoute {
  /// passed to the title property in [CupertinoPageRoute]
  final String? title;

  CupertinoRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    this.title,
  }) : super(type: const RouteType.cupertino());
}

class AdaptiveRoute extends AutoRoute {
  AdaptiveRoute({
    required super.page,
    super.fullscreenDialog,
    super.maintainState,
    super.fullMatch = false,
    super.guards,
    super.usesPathAsKey = false,
    super.children,
    super.meta = const {},
    String? cupertinoPageTitle,
    bool opaque = true,
  }) : super(
          type: RouteType.adaptive(
            cupertinoPageTitle: cupertinoPageTitle,
            opaque: opaque,
          ),
        );
}

class CustomRoute extends AutoRoute {
  CustomRoute({
    required super.page,
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
  }) : super(
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
