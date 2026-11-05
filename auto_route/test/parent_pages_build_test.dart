import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late Map<String, int> created;
  late Map<String, int> built;
  late RootStackRouter router;

  PageInfo page(String name) => .new(
    name,
    builder: (_) {
      created[name] = (created[name] ?? 0) + 1;
      return Builder(
        builder: (_) {
          built[name] = (built[name] ?? 0) + 1;
          return Scaffold(body: Text(name));
        },
      );
    },
  );

  setUp(() {
    created = {};
    built = {};
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: page('Home'), path: '/', initial: true),
        AutoRoute(page: page('A'), path: '/a'),
        AutoRoute(page: page('B'), path: '/a/b'),
        AutoRoute(page: page('C'), path: '/a/b/c'),
      ],
    );
  });

  // flutter/flutter#147639: in go_router, going from '/a' to '/a/b' to
  // '/a/b/c' created and built the widget of every page under the new one
  // again, so a page that loads an ad or data did it on each step.
  for (final (label, open) in [
    ('pushPath', (String path) => router.pushPath(path)),
    (
      'navigatePath with prefix matches',
      (String path) => router.navigatePath(path, includePrefixMatches: true),
    ),
  ]) {
    // Steps: open '/a', then '/a/b', then '/a/b/c'.
    // Should: each page's widget is created and built once; the pages under
    // the one opened are not created or built again.
    testWidgets('$label to a deeper page creates and builds only that page', (
      tester,
    ) async {
      await pumpRouterApp(tester, router);
      for (final path in ['/a', '/a/b', '/a/b/c']) {
        unawaited(open(path));
        await tester.pumpAndSettle();
      }
      expect(router.stack.map((p) => p.name), ['Home', 'A', 'B', 'C']);
      expect(find.text('C'), findsOneWidget);
      const once = {'Home': 1, 'A': 1, 'B': 1, 'C': 1};
      expect(created, once);
      expect(built, once);
    });
  }

  // flutter/flutter#147639, going back up: navigatePath to '/a' from
  // '/a/b/c' pops to A without creating Home again.
  testWidgets(
    'navigatePath with prefix matches to a page under the top pops to it',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.navigatePath('/a/b/c', includePrefixMatches: true));
      await tester.pumpAndSettle();
      unawaited(router.navigatePath('/a', includePrefixMatches: true));
      await tester.pumpAndSettle();
      expect(router.stack.map((p) => p.name), ['Home', 'A']);
      expect(find.text('A'), findsOneWidget);
      expect(created['Home'], 1);
    },
  );
}
