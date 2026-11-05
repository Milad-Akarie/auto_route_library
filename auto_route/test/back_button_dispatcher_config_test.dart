import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Guard for flutter/flutter#166733 (MaterialApp.router with routerConfig and
// no backButtonDispatcher loses Android back).
// Setup, as in the report: an app that gives MaterialApp.router the router's
// config as routerConfig only.
// Steps: push a second page and press the Android back key.
// Happened (in Flutter, with a RouterConfig made by hand): the key closed
// the app, because the config had no backButtonDispatcher.
// Should: the key pops the page. RootStackRouter.config() supplies a
// RootBackButtonDispatcher (lib/src/router/controller/root_stack_router.dart).
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'FirstRoute',
            builder: (_) => const Text('FirstRoute'),
          ),
          path: '/',
          initial: true,
        ),
        AutoRoute(
          page: PageInfo(
            'SecondRoute',
            builder: (_) => const Text('SecondRoute'),
          ),
          path: '/second',
        ),
      ],
    );
  });

  testWidgets(
    'the config has a back button dispatcher, and the back key pops the page '
    'on top',
    (tester) async {
      final config = router.config();
      expect(config.backButtonDispatcher, isA<RootBackButtonDispatcher>());

      await pumpRouterConfigApp(tester, config);
      unawaited(router.pushPath('/second'));
      await tester.pumpAndSettle();
      expectTopPage(router, 'SecondRoute');

      await systemBack(tester);
      expectTopPage(router, 'FirstRoute');
    },
  );
}
