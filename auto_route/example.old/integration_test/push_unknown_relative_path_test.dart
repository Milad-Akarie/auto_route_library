import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pushPath of a relative path no route has reports a failure, even in a
// nested router whose first page has the path ''.
// https://github.com/Milad-Akarie/auto_route_library/issues/1648
// Headless test:
// auto_route/test/nested_router/push_unknown_relative_path_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: BottomNavigationRoute '/' with tabs HomeTabRoute 'home' and
  // SecondTabRoute 'second', each a router with an initial page; from the
  // home page call pushPath('nowhere') with onFailure.
  // Should: onFailure gets a RouteNotFoundFailure and the home stack stays.
  testWidgets(
    'pushPath of an unknown relative path reports a failure instead of pushing '
    'the first page',
    (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'BottomNavigationRoute',
            path: '/',
            builder: (_, _) => const AutoTabsScaffold(
              routes: [
                NamedRoute('HomeTabRoute'),
                NamedRoute('SecondTabRoute'),
              ],
            ),
            children: [
              NamedRouteDef.shell(
                name: 'HomeTabRoute',
                path: 'home',
                children: [
                  NamedRouteDef(
                    name: 'HomeRoute',
                    initial: true,
                    builder: (_, _) => _page('Home'),
                  ),
                ],
              ),
              NamedRouteDef.shell(
                name: 'SecondTabRoute',
                path: 'second',
                children: [
                  NamedRouteDef(
                    name: 'SecondRoute',
                    initial: true,
                    builder: (_, _) => _page('Second'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final home = tester.element(find.text('Home')).router;
      final failures = <NavigationFailure>[];

      unawaited(home.pushPath('nowhere', onFailure: failures.add));
      await tester.pumpAndSettle();

      expect(failures.single, isA<RouteNotFoundFailure>());
      expect(home.stack.map((p) => p.name), ['HomeRoute']);
      await expectBrowserUrl('/home');
    },
  );
}

Widget _page(String text) => Scaffold(body: SafeArea(child: Text(text)));
