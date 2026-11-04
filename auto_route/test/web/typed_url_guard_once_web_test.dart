@TestOn('browser')
library;

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/flutter/flutter/issues/158259
  // In go_router, a redirect ran twice when the url was typed in the
  // address bar.
  // Steps: open the app at /login, as typing it in the address bar does;
  // LoginRoute's guard counts its calls and lets the user through.
  // Should: the guard runs once, LoginRoute shows and the url stays /login.
  testWidgets('On web, opening a guarded url runs its guard once (flutter/flutter#158259)', (tester) async {
    var guardCalls = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'LoginRoute',
          path: '/login',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              guardCalls++;
              resolver.next();
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('LoginRoute')),
        ),
      ],
    );
    addTearDown(router.dispose);
    openBrowserAt(tester, '/login');

    await pumpAsRunApp(tester, MaterialApp.router(routerConfig: router.config()));

    expect(guardCalls, 1);
    expect(find.text('LoginRoute'), findsOneWidget);
    expect(browserPath, '/login');
  });
}
