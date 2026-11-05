import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  RootStackRouter buildRouter({required bool withWildcard}) => .build(
    routes: [
      AutoRoute(page: FirstRoute.page, path: '/', initial: true),
      AutoRoute(
        page: PageInfo('ShellRoute', builder: (_) => const AutoRouter()),
        path: '/shell',
        children: [
          AutoRoute(page: SecondRoute.page, path: '', initial: true),
          if (withWildcard)
            AutoRoute(
              page: PageInfo('ShellNotFoundRoute', builder: (_) => const Text('Shell not found')),
              path: '*',
            ),
        ],
      ),
      if (withWildcard)
        AutoRoute(
          page: PageInfo('NotFoundRoute', builder: (_) => const Text('Not found')),
          path: '*',
        ),
    ],
  );

  final ways = <String, Future<void> Function(StackRouter router, String path, OnNavigationFailure? onFailure)>{
    'navigatePath': (router, path, onFailure) => router.navigatePath(path, onFailure: onFailure),
    'pushPath': (router, path, onFailure) => router.pushPath(path, onFailure: onFailure),
    'replacePath': (router, path, onFailure) => router.replacePath(path, onFailure: onFailure),
  };

  // flutter/flutter#117449: in go_router, goNamed() to a route that didn't
  // exist skipped the errorBuilder that go() showed. In auto_route every way
  // of opening a path goes through the same matcher.
  for (final MapEntry(key: name, value: open) in ways.entries) {
    // Steps: with a '*' route, open '/nope' with [name].
    // Should: the '*' page shows.
    testWidgets('$name to an unknown path shows the "*" page', (tester) async {
      final router = buildRouter(withWildcard: true);
      await pumpRouterApp(tester, router);
      unawaited(open(router, '/nope', null));
      await tester.pumpAndSettle();
      expect(find.text('Not found'), findsOneWidget);
    });

    // Steps: without a '*' route, open '/nope' with [name], with onFailure
    // and without.
    // Should: onFailure gets RouteNotFoundFailure('/nope'); without it, the
    // call throws an error naming the path. The page stays.
    testWidgets('$name to an unknown path without "*" reports it', (tester) async {
      final router = buildRouter(withWildcard: false);
      await pumpRouterApp(tester, router);
      final failures = <NavigationFailure>[];
      unawaited(open(router, '/nope', failures.add));
      await tester.pumpAndSettle();
      expect(failures.singleOrNull, isA<RouteNotFoundFailure>().having((f) => f.path, 'path', '/nope'));

      Object? error;
      try {
        await open(router, '/nope', null);
        // The router reports an unknown path with this error.
        // ignore: avoid_catching_errors
      } on FlutterError catch (e) {
        error = e;
      }
      expect(error, isA<FlutterError>().having((e) => e.message, 'message', startsWith('Can not navigate to /nope')));
      expectCurrentPage(router, FirstRoute.name);
    });

    // Steps: from inside a nested router, open the relative path 'nope'
    // with [name].
    // Should: the nested router's '*' page shows.
    testWidgets('$name to an unknown relative path in a nested router shows its "*" page', (tester) async {
      final router = buildRouter(withWildcard: true);
      await pumpRouterApp(tester, router, initialLink: '/shell');
      final nested = router.innerRouterOf<StackRouter>('ShellRoute')!;
      unawaited(open(nested, 'nope', null));
      await tester.pumpAndSettle();
      expect(find.text('Shell not found'), findsOneWidget);
    });
  }
}
