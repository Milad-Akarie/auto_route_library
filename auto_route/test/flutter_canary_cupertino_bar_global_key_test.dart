import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/113409.
// Setup: a router whose pages are Cupertino routes. HomeRoute's
// CupertinoNavigationBar has a trailing widget with a GlobalKey; SecondRoute
// has a CupertinoNavigationBar too. Plain Flutter fails the same way.
// Steps: push SecondRoute.
// Today the bars' transition between routes builds a copy of HomeRoute's bar
// over both pages while the original stays in place, so the keyed widget is
// in the tree twice and Flutter throws "Multiple widgets used the same
// GlobalKey". Flutter documents this under
// CupertinoNavigationBar.transitionBetweenRoutes; an app sets it to false on
// a bar that holds a GlobalKey. auto_route only picks the route type.
// If this test fails after a Flutter upgrade, the transition no longer copies
// keyed widgets: drop this canary.
void main() {
  testWidgets('pushing past a Cupertino bar that holds a GlobalKey throws on the duplicate key', (tester) async {
    final settingsKey = GlobalKey();
    final router = RootStackRouter.build(
      defaultRouteType: const .cupertino(),
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: const Text('HomeRoute'),
                trailing: Icon(CupertinoIcons.settings, key: settingsKey),
              ),
              child: const SizedBox(),
            ),
          ),
        ),
        AutoRoute(
          path: '/second',
          page: PageInfo(
            'SecondRoute',
            builder: (_) => const CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text('SecondRoute')),
              child: SizedBox(),
            ),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final errors = <String>[];
    final onError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();
    FlutterError.onError = onError;

    expect(errors, isNotEmpty);
    expect(errors.first, startsWith('Multiple widgets used the same GlobalKey.'));
    expect(router.topRoute.name, 'SecondRoute');
  });
}
