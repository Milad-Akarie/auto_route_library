import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AutoRoutePage extends Page<dynamic> {
  final StackEntryItem entry;
  final Widget child;
  final bool fullscreenDialog;
  final bool maintainState;

  bool get hasInnerRouter => entry is RoutingController;

  RouteData get routeData => entry?.routeData;

  const AutoRoutePage({
    @required this.entry,
    @required this.child,
    this.fullscreenDialog,
    this.maintainState,
  })  : assert(child != null),
        assert(entry != null),
        assert(fullscreenDialog != null),
        assert(maintainState != null),
        super();

  @override
  String get name => routeData?.name;

  @override
  Object get arguments => routeData?.route;

  @override
  bool canUpdate(Page other) {
    return other.runtimeType == runtimeType && (other as AutoRoutePage).entry.key == this.entry.key;
  }

  Widget wrappedChild(BuildContext context) {
    var childToBuild = child;
    if (child is AutoRouteWrapper) {
      childToBuild = (child as AutoRouteWrapper).wrappedRoute(context);
    }
    return StackEntryScope(child: childToBuild, entry: entry);
  }
}

class MaterialPageX extends AutoRoutePage {
  const MaterialPageX({
    @required StackEntryItem entry,
    @required Widget child,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          entry: entry,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Route createRoute(BuildContext context) {
    return _PageBasedMaterialPageRoute(page: this);
  }
}

class _PageBasedMaterialPageRoute extends PageRoute<dynamic> with MaterialRouteTransitionMixin {
  _PageBasedMaterialPageRoute({
    @required AutoRoutePage page,
  })  : assert(page != null),
        super(settings: page);

  AutoRoutePage get _page => settings as AutoRoutePage;

  @override
  Widget buildContent(BuildContext context) => _page.wrappedChild(context);

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

abstract class _TitledAutoRoutePage extends AutoRoutePage {
  final String title;

  const _TitledAutoRoutePage({
    @required StackEntryItem entry,
    @required Widget child,
    this.title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          entry: entry,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

class CupertinoPageX extends _TitledAutoRoutePage {
  const CupertinoPageX({
    @required StackEntryItem entry,
    @required Widget child,
    String title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  })  : assert(fullscreenDialog != null),
        assert(maintainState != null),
        super(
            entry: entry, child: child, maintainState: maintainState, fullscreenDialog: fullscreenDialog, title: title);

  @override
  Route createRoute(BuildContext context) {
    return _PageBasedCupertinoPageRoute(page: this);
  }
}

class _PageBasedCupertinoPageRoute extends PageRoute<dynamic> with CupertinoRouteTransitionMixin {
  _PageBasedCupertinoPageRoute({
    @required _TitledAutoRoutePage page,
  })  : assert(page != null),
        super(settings: page);

  _TitledAutoRoutePage get _page => settings as _TitledAutoRoutePage;

  @override
  Widget buildContent(BuildContext context) => _page.wrappedChild(context);

  @override
  String get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class AdaptivePage extends _TitledAutoRoutePage {
  const AdaptivePage({
    @required StackEntryItem entry,
    @required Widget child,
    String title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) : super(
          entry: entry,
          child: child,
          title: title,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Route createRoute(BuildContext context) {
    if (kIsWeb) {
      return PageRouteBuilder(
        pageBuilder: (_, __, ___) => wrappedChild(context),
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return _PageBasedCupertinoPageRoute(page: this);
    }
    return _PageBasedMaterialPageRoute(page: this);
  }
}

typedef CustomRouteBuilder = Route Function(BuildContext context, Widget child, CustomPage page);

class CustomPage extends AutoRoutePage {
  final bool opaque;
  final int durationInMilliseconds;
  final int reverseDurationInMilliseconds;
  final Color barrierColor;
  final bool barrierDismissible;
  final String barrierLabel;
  final RouteTransitionsBuilder transitionsBuilder;
  final CustomRouteBuilder customRouteBuilder;

  CustomPage({
    @required StackEntryItem entry,
    @required Widget child,
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
  })  : assert(opaque != null),
        assert(durationInMilliseconds != null),
        assert(barrierDismissible != null),
        super(
          entry: entry,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        ) {}

  @override
  Route createRoute(BuildContext context) {
    if (customRouteBuilder != null) {
      return customRouteBuilder(context, wrappedChild(context), this);
    }
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => wrappedChild(context),
      settings: this,
      opaque: opaque,
      transitionDuration: Duration(milliseconds: durationInMilliseconds),
      reverseTransitionDuration: Duration(milliseconds: reverseDurationInMilliseconds),
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      transitionsBuilder: transitionsBuilder ?? _defaultTransitionsBuilder,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    );
  }

  Widget _defaultTransitionsBuilder(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
