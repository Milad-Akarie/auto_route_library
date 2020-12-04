import 'package:auto_route/src/route/route_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract class ExtendedPage extends Page {
  final RouteData data;
  final Widget child;

  ExtendedPage({
    @required this.data,
    this.child,
  })  :
        // assert(builder != null),
        assert(data != null),
        super(
          // key: ValueKey(data.key),
          arguments: data.args,
          name: data.path,
        );

  @override
  bool canUpdate(Page other) {
    var canUpdate = other.runtimeType == runtimeType && (other as ExtendedPage).data == this.data;
    print("${data.key} can update : $canUpdate");
    return canUpdate;
  }

  @protected
  @override
  Route createRoute(BuildContext context) {
    return onCreateRoute(context, child);
  }

  Route onCreateRoute(BuildContext context, Widget child);
}

class XMaterialPage extends ExtendedPage {
  final bool fullscreenDialog;
  final bool maintainState;

  XMaterialPage({
    @required RouteData data,
    @required Widget child,
    this.fullscreenDialog = false,
    this.maintainState = true,
  })  : assert(fullscreenDialog != null),
        assert(maintainState != null),
        super(
          data: data,
          child: child,
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

class XCupertinoPage<T> extends ExtendedPage {
  final bool fullscreenDialog;
  final bool maintainState;
  final String title;

  XCupertinoPage({
    @required RouteData data,
    @required Widget child,
    this.title,
    this.fullscreenDialog = false,
    this.maintainState = true,
  })  : assert(fullscreenDialog != null),
        assert(maintainState != null),
        super(
          data: data,
          // child: builder,
        );

  @override
  Route<T> onCreateRoute(BuildContext context, Widget child) {
    return CupertinoPageRoute(
      builder: (_) => child,
      settings: this,
      title: title,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    );
  }
}
