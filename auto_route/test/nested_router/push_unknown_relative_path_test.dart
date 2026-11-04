import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1648
  // In a nested router whose first page has the path '', pushPath of a path
  // no route has, without a leading '/', pushed that first page again
  // instead of failing.
  // Steps: BottomNavigationRoute '/' with tabs HomeTabRoute 'home' and
  // SecondTabRoute 'second', each a router with an initial page; from the
  // home page call pushPath('nowhere'), on the root router and on the nested one.
  // Should: onFailure gets a RouteNotFoundFailure, or without onFailure
  // pushPath throws, and the stacks stay as they were.
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'BottomNavigationRoute',
        path: '/',
        builder: (_, _) => const AutoTabsScaffold(routes: [NamedRoute('HomeTabRoute'), NamedRoute('SecondTabRoute')]),
        children: [
          NamedRouteDef.shell(
            name: 'HomeTabRoute',
            path: 'home',
            children: [NamedRouteDef(name: 'HomeRoute', initial: true, builder: (_, _) => _page('HomeRoute'))],
          ),
          NamedRouteDef.shell(
            name: 'SecondTabRoute',
            path: 'second',
            children: [NamedRouteDef(name: 'SecondRoute', initial: true, builder: (_, _) => _page('SecondRoute'))],
          ),
        ],
      ),
    ],
  );

  testWidgets('pushPath of an unknown relative path reports a failure instead of pushing the first page', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final home = tester.element(find.text('HomeRoute')).router;
    final failures = <NavigationFailure>[];

    unawaited(router.pushPath('nowhere', onFailure: failures.add));
    await tester.pumpAndSettle();
    unawaited(home.pushPath('nowhere', onFailure: failures.add));
    await tester.pumpAndSettle();

    expect(failures, hasLength(2));
    expect(failures, everyElement(isA<RouteNotFoundFailure>()));
    expect(home.stack.map((p) => p.name), ['HomeRoute']);
    expect(router.stack.map((p) => p.name), ['BottomNavigationRoute']);
  });

  testWidgets('pushPath of an unknown relative path throws without onFailure', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);

    expect(() => router.pushPath('nowhere'), throwsA(isA<FlutterError>()));
    await tester.pumpAndSettle();
    expect(tester.element(find.text('HomeRoute')).router.stack.map((p) => p.name), ['HomeRoute']);
  });

  testWidgets('a known relative path still opens its tab', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);

    unawaited(router.navigatePath('/second'));
    await tester.pumpAndSettle();
    expect(find.text('SecondRoute'), findsOneWidget);
  });
}

Widget _page(String name) => Scaffold(body: Text(name));
