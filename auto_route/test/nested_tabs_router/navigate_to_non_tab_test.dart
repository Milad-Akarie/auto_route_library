import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1371
  // A route among the children of a tabs host's route, but not one of its
  // AutoTabsRouter's tabs, did nothing when navigated to: no page, no error,
  // and onFailure was not called.
  // Steps: SectionRoute with children PagerPage1Route, PagerPage2Route and
  // OtherExternalPageRoute; its AutoTabsRouter shows the first two. From a
  // tab, navigate to OtherExternalPageRoute, with and without onFailure.
  // Should: onFailure gets a RouteNotFoundFailure, or navigate throws, and
  // the tabs stay as they were.
  RootStackRouter buildRouter() => .build(
    routes: [
      NamedRouteDef(
        name: 'SectionRoute',
        path: '/',
        builder: (_, _) => AutoTabsRouter(
          routes: const [NamedRoute('PagerPage1Route'), NamedRoute('PagerPage2Route')],
          builder: (_, child) => child,
        ),
        children: [
          NamedRouteDef(name: 'PagerPage1Route', path: 'page1', builder: (_, _) => _page('PagerPage1Route')),
          NamedRouteDef(name: 'PagerPage2Route', path: 'page2', builder: (_, _) => _page('PagerPage2Route')),
          NamedRouteDef(
            name: 'OtherExternalPageRoute',
            path: 'other',
            builder: (_, _) => _page('OtherExternalPageRoute'),
          ),
        ],
      ),
    ],
  );

  testWidgets('navigate to a child route that is not a tab reports a failure', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final tabs = tester.element(find.text('PagerPage1Route')).router;
    final failures = <NavigationFailure>[];

    unawaited(tabs.navigate(const NamedRoute('OtherExternalPageRoute'), onFailure: failures.add));
    await tester.pumpAndSettle();

    expect(failures.single, isA<RouteNotFoundFailure>());
    expect(find.text('PagerPage1Route'), findsOneWidget);
  });

  testWidgets('navigate to a child route that is not a tab throws without onFailure', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final tabs = tester.element(find.text('PagerPage1Route')).router;

    await expectLater(tabs.navigate(const NamedRoute('OtherExternalPageRoute')), throwsA(isA<FlutterError>()));
    await tester.pumpAndSettle();
    expect(find.text('PagerPage1Route'), findsOneWidget);
  });

  testWidgets('navigate to another tab still switches to it', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    final tabs = tester.element(find.text('PagerPage1Route')).router;

    unawaited(tabs.navigate(const NamedRoute('PagerPage2Route')));
    await tester.pumpAndSettle();
    expect(find.text('PagerPage2Route'), findsOneWidget);
  });
}

Widget _page(String name) => Scaffold(body: Text(name));
