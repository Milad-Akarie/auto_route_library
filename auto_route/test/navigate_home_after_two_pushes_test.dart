import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// #2155 (auto_route master, Feb 2025): navigating back to the first page
// from the third raised "setState() or markNeedsBuild() called during build"
// from onPopPage.
// Setup: a flat root with 'HomeRoute' (initial), 'Random1Route' and
// 'Random2Route'.
// Steps: open Random1 and then Random2 (with push, then with navigate), tap
// 'Go back home', which calls context.navigateTo(HomeRoute()).
// Should: no exception; only HomeRoute remains.
void main() {
  final opens = <String, Future<void> Function(StackRouter, String)>{
    'push': (router, name) => router.push(NamedRoute(name)),
    'navigate': (router, name) => router.navigate(NamedRoute(name)),
  };

  for (final MapEntry(key: how, value: open) in opens.entries) {
    testWidgets('navigateTo(HomeRoute) from the third page, opened with $how '
        'shows HomeRoute without an error', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/', initial: true, page: _page('HomeRoute')),
          AutoRoute(path: '/random1', page: _page('Random1Route')),
          AutoRoute(
            path: '/random2',
            page: PageInfo(
              'Random2Route',
              builder: (_) => Builder(
                builder: (context) => TextButton(
                  onPressed: () => unawaited(
                    context.navigateTo(const NamedRoute('HomeRoute')),
                  ),
                  child: const Text('Go back home'),
                ),
              ),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(open(router, 'Random1Route'));
      await tester.pumpAndSettle();
      unawaited(open(router, 'Random2Route'));
      await tester.pumpAndSettle();
      expect(find.text('Go back home'), findsOneWidget);

      await tester.tap(find.text('Go back home'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectTopPage(router, 'HomeRoute');
      expect(router.stack.map((page) => page.name), ['HomeRoute']);
    });
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
