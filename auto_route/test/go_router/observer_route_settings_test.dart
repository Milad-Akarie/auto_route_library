import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// A NavigatorObserver sees the route name in route.settings for every route
// type, a custom transition included.
// The same scenario as flutter/flutter#112185 in go_router, where routes
// built from a pageBuilder had null settings.
void main() {
  // Steps: an observer records route.settings.name on didPush; push a
  // material route, a custom route with no transition and a custom route
  // built by customRouteBuilder. Should: every name is recorded, none null.
  testWidgets('NavigatorObserver.didPush gets the route name for every route type', (tester) async {
    final observer = _NameRecorder();
    Widget page(RouteData<dynamic> _) => const Text('page');
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: page),
        ),
        AutoRoute(
          path: '/material',
          page: PageInfo('MaterialRoute', builder: page),
        ),
        CustomRoute(
          path: '/custom',
          page: PageInfo('CustomRoute', builder: page),
          transitionsBuilder: TransitionsBuilders.noTransition,
        ),
        CustomRoute(
          path: '/built',
          page: PageInfo('BuiltRoute', builder: page),
          customRouteBuilder: <T>(context, child, page) =>
              PageRouteBuilder<T>(settings: page, pageBuilder: (_, _, _) => child),
        ),
      ],
    );
    await pumpRouterApp(tester, router, observers: () => [observer]);
    for (final path in ['/material', '/custom', '/built']) {
      unawaited(router.pushPath(path));
      await tester.pumpAndSettle();
    }
    expect(observer.pushed, ['HomeRoute', 'MaterialRoute', 'CustomRoute', 'BuiltRoute']);
  });
}

class _NameRecorder extends NavigatorObserver {
  final pushed = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushed.add(route.settings.name);
}
