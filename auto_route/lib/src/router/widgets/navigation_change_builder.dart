import 'package:flutter/material.dart';

import '../../../auto_route.dart';

typedef OnNavigationChangeBuilder = Widget Function(BuildContext context, RoutingController topMostRouter);
typedef BuildWhenCallBack = bool Function(RoutingController topMostRouter);

class NavigationChangeBuilder extends StatefulWidget {
  final OnNavigationChangeBuilder builder;
  final RoutingController? scope;
  final BuildWhenCallBack buildWhen;

  const NavigationChangeBuilder({
    Key? key,
    required this.builder,
    this.buildWhen = _defaultBuildWhenCallBack,
    this.scope,
  }) : super(key: key);

  static bool _defaultBuildWhenCallBack(_) => true;

  @override
  _NavigationListenerState createState() => _NavigationListenerState();
}

class _NavigationListenerState extends State<NavigationChangeBuilder> {
  RoutingController? _scope;

  @override
  Widget build(BuildContext context) {
    assert(_scope != null);
    return widget.builder(
      context,
      _scope!.topMost,
    );
  }

  void _listener() {
    assert(_scope != null);
    if (widget.buildWhen(_scope!.topMost)) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _scope?.removeListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scope == null) {
      _resetListener();
    }
  }

  void _resetListener() {
    _scope = widget.scope ?? AutoRouterDelegate.of(context).controller;
    _scope?.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant NavigationChangeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scope != oldWidget.scope) {
      _scope?.removeListener(_listener);
      _resetListener();
    }
  }
}
