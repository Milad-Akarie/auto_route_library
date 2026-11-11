import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/140586
  // In go_router, A > push B > push C, where B and C sit in a shell, then
  // pushReplacement A and push B again, threw "!keyReservation.contains(key)":
  // two routes with one key in a Navigator.
  // Steps: open A, push B, which opens ShellRoute with B in it, push C in the
  // shell, replace the shell with A, then push B again.
  // Should: no exception; the stack is A, A, then the shell with B.
  testWidgets(
    'Pushing a shell page again after replacing the shell throws nothing (flutter/flutter#140586)',
    (tester) async {
      PageInfo page(String name) =>
          .new(name, builder: (_) => Scaffold(body: Text(name)));
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: page('A'), path: '/'),
          AutoRoute(
            page: const PageInfo.emptyShell('ShellRoute'),
            path: '/shell',
            children: [
              AutoRoute(page: page('B'), path: 'b'),
              AutoRoute(page: page('C'), path: 'c'),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      unawaited(
        router.push(
          const NamedRoute('ShellRoute', children: [NamedRoute('B')]),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        router
            .innerRouterOf<StackRouter>('ShellRoute')!
            .push(const NamedRoute('C')),
      );
      await tester.pumpAndSettle();
      expect(router.urlState.url, '/shell/c');

      unawaited(router.replace(const NamedRoute('A')));
      await tester.pumpAndSettle();
      expectTopPage(router, 'A');

      unawaited(
        router.push(
          const NamedRoute('ShellRoute', children: [NamedRoute('B')]),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['A', 'A', 'ShellRoute']);
      expect(find.text('B'), findsOneWidget);
      expect(router.urlState.url, '/shell/b');
    },
  );
}
