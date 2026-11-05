import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/185011
// Setup: a root page, page A inside shell A and page B inside shell B; each
// shell only wraps its child.
// Steps: push A, then B, then A again.
// Should: the stack is root, A, B, A with no duplicate key error, and back
// walks it down again.
void main() {
  for (final (how, push) in [
    ('routes', (StackRouter router, String name) => router.push(_Route('${name}Route'))),
    ('paths', (StackRouter router, String name) => router.pushPath('/${name.toLowerCase()}')),
  ]) {
    testWidgets('Pushing shell children A, B, A by $how stacks them all', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/', page: _page('RootRoute')),
          for (final name in ['A', 'B'])
            AutoRoute(
              path: '/${name.toLowerCase()}',
              page: EmptyShellRoute('${name}ShellRoute'),
              children: [AutoRoute(path: '', page: _page('${name}Route'))],
            ),
        ],
      );
      await pumpRouterApp(tester, router);
      for (final name in ['A', 'B', 'A']) {
        unawaited(push(router, name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('${name}Route'), findsOneWidget);
      }
      expect(router.stack.map((page) => page.name), ['RootRoute', 'AShellRoute', 'BShellRoute', 'AShellRoute']);

      for (final name in ['BRoute', 'ARoute', 'RootRoute']) {
        await router.maybePopTop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(name), findsOneWidget);
      }
    });
  }
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
