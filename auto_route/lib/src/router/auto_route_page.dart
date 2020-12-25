import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route/route_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AutoRoutePage extends Page {
  final StackEntryItem entry;
  final Widget child;
  final bool fullscreenDialog;
  final bool maintainState;

  bool get hasInnerRouter => entry is RoutingController;

  RouteData get routeData => entry?.routeData;
  AutoRoutePage({
    @required this.entry,
    @required this.child,
    this.fullscreenDialog,
    this.maintainState,
  })  : assert(child != null),
        assert(entry != null),
        assert(fullscreenDialog != null),
        assert(maintainState != null),
        super(
          // key: entry.key,
          arguments: entry,
        );

  @override
  bool canUpdate(Page other) {
    return other.runtimeType == runtimeType && (other as AutoRoutePage).entry.key == this.entry.key;
  }

  @protected
  @override
  Route createRoute(BuildContext context) {
    return onCreateRoute(context, wrappedChild(context));
  }

  Widget wrappedChild(BuildContext context) {
    var childToBuild = child;
    if (child is AutoRouteWrapper) {
      childToBuild = (child as AutoRouteWrapper).wrappedRoute(context);
    }
    return StackEntryScope(child: childToBuild, entry: entry);
  }

  Route onCreateRoute(BuildContext context, Widget child);
}

class MaterialPageX extends AutoRoutePage {
  MaterialPageX({
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
  Route onCreateRoute(BuildContext context, Widget child) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: this,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    );
  }
}

class CupertinoPageX extends AutoRoutePage {
  final String title;

  CupertinoPageX({
    @required StackEntryItem entry,
    @required Widget child,
    this.title,
    bool fullscreenDialog = false,
    bool maintainState = true,
  })  : assert(fullscreenDialog != null),
        assert(maintainState != null),
        super(
          entry: entry,
          child: child,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Route onCreateRoute(BuildContext context, Widget child) {
    return CupertinoPageRoute(
      builder: (_) => child,
      settings: this,
      title: title,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    );
  }
}

class AdaptivePage extends AutoRoutePage {
  // cupertino page title
  final String title;

  AdaptivePage({
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

  @override
  Route onCreateRoute(BuildContext context, Widget child) {
    if (kIsWeb) {
      return PageRouteBuilder(
        pageBuilder: (_, __, ___) => child,
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoPageRoute(
        builder: (_) => child,
        settings: this,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        title: title,
      );
    }
    return MaterialPageRoute(
      builder: (_) => child,
      settings: this,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

typedef CustomRouteBuilder = Route Function(BuildContext context, CustomPage page);

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
        );

  @override
  Route onCreateRoute(BuildContext context, Widget child) {
    if (customRouteBuilder != null) {
      return customRouteBuilder(context, this);
    }
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => child,
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
