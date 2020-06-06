import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';

class AutoRouter extends StatefulWidget {
  const AutoRouter({
    Key key,
    this.router,
    this.initialRoute,
  }) : super(key: key);

  static AutoRouterState of(
    BuildContext context, {
    bool root = false,
    bool nullOk = false,
  }) {
    final AutoRouterState router = root ? context.findRootAncestorStateOfType<AutoRouterState>() : context.findAncestorStateOfType<AutoRouterState>();
    assert(() {
      if (router == null && !nullOk) {
        throw FlutterError('AutoRouter operation requested with a context that does not include an AutoRouter.\n'
            'The context used to push or pop routes from the AutoRouter must be that of a '
            'widget that is a descendant of a AutoRouter widget.');
      }
      return true;
    }());
    return router;
  }

  final RouterBase router;
  final String initialRoute;

  AutoRouter call(_, __) => this;

  @override
  AutoRouterState createState() => AutoRouterState();
}

class AutoRouterState extends State<AutoRouter> {
  final _navigatorKey = GlobalKey<ExtendedNavigatorState>();
  RouterBase _router;
  String _initialRoute;

  ExtendedNavigatorState get _navigator => _navigatorKey.currentState;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _initialRoute = widget.initialRoute;
    if (widget.router != null) {
      _router = widget.router;
    } else {
      final parentData = ParentRouteData.of(context);
      if (parentData != null && parentData is ParentRouteData) {
        _router = parentData.router;
        if (parentData.initialRoute?.isNotEmpty == true) {
          _initialRoute = parentData.initialRoute;
        }
      } else {
        throw FlutterError('Router can not be null');
      }
    }

    return ExtendedNavigator(
      router: _router,
      initialRoute: _initialRoute,
      key: _navigatorKey,
    );
  }

  @optionalTypeArgs
  Future<T> push<T extends Object>(
    String routeName, {
    Object arguments,
    OnNavigationRejected onReject,
  }) async {
//    if (_isAbsolute(routeName)) {
//
//      _navigator.pushDeepLink(routeName);
//    } else {
//      return ;
//    }
    _navigator.pushRelativeRoute(routeName);
  }

  bool _isAbsolute(String routeName) {
    return routeName.startsWith('/');
  }
}
