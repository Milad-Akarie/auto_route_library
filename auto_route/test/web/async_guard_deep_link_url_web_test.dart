@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/flutter/flutter/issues/112997
  // In go_router, opening a url behind an async redirect showed '/' in the
  // address bar until the redirect answered.
  // Steps: '/' redirects to '/parent/child'; ParentRoute hosts ChildRoute and
  // its guard answers only later. Open the app at '/parent/child', as typing
  // it in the address bar does, then let the guard answer.
  // Should: the address bar keeps '/parent/child' while the guard waits and
  // after, and ChildRoute shows.
  testWidgets(
    'On web, a url behind an async guard stays in the address bar while the guard waits (flutter/flutter#112997)',
    (tester) async {
      final guardAnswer = Completer<void>();
      final router = RootStackRouter.build(
        routes: [
          RedirectRoute(path: '/', redirectTo: '/parent/child'),
          NamedRouteDef(
            name: 'ParentRoute',
            path: '/parent',
            guards: [
              AutoRouteGuard.simple((resolver, _) async {
                await guardAnswer.future;
                resolver.next();
              }),
            ],
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'ChildRoute',
                path: 'child',
                builder: (_, _) => const Scaffold(body: Text('ChildRoute')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      openBrowserAt(tester, '/parent/child');

      await pumpAsRunApp(tester, MaterialApp.router(routerConfig: router.config()));
      expect(find.text('ChildRoute'), findsNothing);
      expect(browserPath, '/parent/child');

      guardAnswer.complete();
      await settleBrowser(tester);
      expect(find.text('ChildRoute'), findsOneWidget);
      expect(browserPath, '/parent/child');
    },
  );
}
