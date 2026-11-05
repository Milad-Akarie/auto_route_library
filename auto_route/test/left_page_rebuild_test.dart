import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late List<String> builds;
  late RootStackRouter router;

  setUp(() {
    builds = [];
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'ARoute',
            builder: (_) => Builder(
              builder: (context) {
                // What a page reads from the router in build: its own route
                // data and the router's current route and url.
                builds.add(
                  '${context.routeData.name} ${context.router.current.name} '
                  '${context.router.urlState.url}',
                );
                return const Text('A');
              },
            ),
          ),
          path: '/',
          initial: true,
        ),
        AutoRoute(page: SecondRoute.page, path: '/b'),
      ],
    );
  });

  // flutter/flutter#170255: in go_router, a page that read the router's state
  // in build was built again once the app had gone to another page, with the
  // state it was opened with. A page that has left should not build again.
  for (final (label, leave) in [
    ('replace', () => router.replace(const SecondRoute())),
    ('navigate', () => router.navigate(const SecondRoute())),
    ('push', () => router.push(const SecondRoute())),
  ]) {
    // Steps: open A, whose build reads context.routeData and
    // context.router, then go to B with [label].
    // Should: A is not built again once B is shown.
    testWidgets(
      'A page reading the router in build is not built again after $label to '
      'another page',
      (tester) async {
        await pumpRouterApp(tester, router);
        expect(builds, ['ARoute ARoute /']);
        unawaited(leave());
        await tester.pumpAndSettle();
        expectTopPage(router, SecondRoute.name);
        expect(builds, ['ARoute ARoute /'], reason: 'after leave())');
      },
    );
  }
}
