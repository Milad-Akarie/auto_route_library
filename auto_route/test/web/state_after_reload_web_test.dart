@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' show window;

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // flutter/flutter#108697: on web, the app saves a state in a browser entry
  // (router.pushPathState); the user leaves for another site, then comes back
  // with the browser's back button, and the app starts again on that entry.
  // The engine starts the app with no state, so the state was lost, and the
  // app's first report then wrote null over it in the entry.
  // Steps: make the browser's entry hold '/p2' with the state the engine
  // keeps for the app, {serialCount: 0, state: 'saved'}, then start the app
  // there, as the browser does when it comes back.
  // Should: router.pathState is 'saved', and the entry keeps it.
  testWidgets(
    'An app started on a browser entry it saved a state in reads that state',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('P1', builder: (_) => const Text('P1')),
          ),
          AutoRoute(
            path: '/p2',
            page: PageInfo('P2', builder: (_) => const Text('P2')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      dispatcher.defaultRouteNameTestValue = '/p2';
      window.history.replaceState(
        {'serialCount': 0, 'state': 'saved'}.jsify(),
        '',
        '#/p2',
      );

      await pumpAsRunApp(
        tester,
        MaterialApp.router(routerConfig: router.config()),
      );

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['P2']);
      expect(router.pathState, 'saved');
      expect(window.history.state.dartify(), {
        'serialCount': 0,
        'state': 'saved',
      });
      await tester.pumpWidget(const SizedBox());
    },
  );
}
