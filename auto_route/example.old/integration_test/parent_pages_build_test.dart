import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Opening a deeper page by its path creates and builds only that page, not
// the pages under it.
// https://github.com/flutter/flutter/issues/147639
// Headless test: auto_route/test/parent_pages_build_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('parent pages build', () {
    // Steps: navigatePath with prefix matches to '/a', then '/a/b', then
    // '/a/b/c', as go_router's go does.
    // Should: the stack is Home, A, B, C, and each page's widget was created
    // and built once.
    testWidgets(
      'navigatePath to a deeper page creates and builds only that page',
      (tester) async {
        final created = <String, int>{};
        final built = <String, int>{};
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
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(page: page('Home'), path: '/'),
            AutoRoute(page: page('A'), path: '/a'),
            AutoRoute(page: page('B'), path: '/a/b'),
            AutoRoute(page: page('C'), path: '/a/b/c'),
          ],
        );
        await pumpRouterApp(tester, router);
        for (final path in ['/a', '/a/b', '/a/b/c']) {
          unawaited(router.navigatePath(path, includePrefixMatches: true));
          await tester.pumpAndSettle();
        }

        expect(router.stack.map((p) => p.name), ['Home', 'A', 'B', 'C']);
        expect(find.text('C'), findsOneWidget);
        const once = {'Home': 1, 'A': 1, 'B': 1, 'C': 1};
        expect(created, once);
        expect(built, once);
      },
    );
  });
}
