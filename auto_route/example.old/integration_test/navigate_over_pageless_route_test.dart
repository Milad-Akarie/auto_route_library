import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// navigate or replaceAll to a page closes the routes pushed over it with
// Navigator.push.
// flutter/flutter#171962
// Headless test:
// auto_route/test/simple_router/navigate_over_pageless_route_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Page1'), path: '/', initial: true),
        AutoRoute(page: _page('Login'), path: '/login'),
        AutoRoute(page: _page('Password'), path: '/password'),
      ],
    );
  });

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  // Steps: on Page1, tap a button that pushes Page2 with Navigator.push; on
  // Page2, tap a button that calls navigate(Page1).
  // Should: Page1 shows and Page2 is gone.
  testWidgets(
    "The reporter's steps: navigate back to the page under a Navigator.push "
    'route',
    (tester) async {
      await pumpRouterApp(tester, router);

      await tester.tap(find.text('Navigator.push Page2'));
      await tester.pumpAndSettle();
      expect(find.text('Page2'), findsOneWidget);
      await tester.tap(find.text('Go to Page1'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Page2'), findsNothing);
      expect(names(), ['Page1']);
      expectCurrentPage(router, 'Page1');
    },
  );

  // Steps: push Page2 with Navigator.push over Page1, then Login and Password
  // with the router; call replaceAll([Page1]).
  // Should: Page1 shows alone.
  testWidgets(
    "The comment's steps: replaceAll from Password shows Page1 alone",
    (tester) async {
      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Navigator.push Page2'));
      await tester.pumpAndSettle();
      unawaited(router.push(const PageRouteInfo('Login')));
      await tester.pumpAndSettle();
      unawaited(router.push(const PageRouteInfo('Password')));
      await tester.pumpAndSettle();

      unawaited(router.replaceAll(const [PageRouteInfo('Page1')]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Page2'), findsNothing);
      expect(names(), ['Page1']);
      expectCurrentPage(router, 'Page1');
    },
  );
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    body: SafeArea(
      child: Builder(
        builder: (context) => Column(
          children: [
            Text(name),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: SafeArea(
                      child: Column(
                        children: [
                          const Text('Page2'),
                          TextButton(
                            onPressed: () => context.router.navigate(
                              const PageRouteInfo('Page1'),
                            ),
                            child: const Text('Go to Page1'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Navigator.push Page2'),
            ),
          ],
        ),
      ),
    ),
  ),
);
