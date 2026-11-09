import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1931
// Steps: Home at '/'. DetailWrapper at '/detail' is a shell whose children are
// Detail (initial; it holds tabs FirstTab and SecondTab) and InsideDetail at
// 'insideDetail'. Push DetailWrapper from Home, then go back.
// Reported (8.0.0, still on 8.1.1): the screen went blank instead of Home.
// Should: Home is shown again.
void main() {
  testWidgets('going back from a wrapper whose child holds tabs shows the '
      'page below it', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        ),
        AutoRoute(
          path: '/detail',
          page: PageInfo(
            'DetailWrapperRoute',
            builder: (_) => const AutoRouter(),
          ),
          children: [
            AutoRoute(
              path: '',
              initial: true,
              page: PageInfo(
                'DetailRoute',
                builder: (_) => AutoTabsRouter(
                  routes: const [
                    PageRouteInfo('FirstTabRoute'),
                    PageRouteInfo('SecondTabRoute'),
                  ],
                  builder: (_, child) => Scaffold(body: child),
                ),
              ),
              children: [
                AutoRoute(
                  path: 'first',
                  page: PageInfo(
                    'FirstTabRoute',
                    builder: (_) => const Text('First'),
                  ),
                ),
                AutoRoute(
                  path: 'second',
                  page: PageInfo(
                    'SecondTabRoute',
                    builder: (_) => const Text('Second'),
                  ),
                ),
              ],
            ),
            AutoRoute(
              path: 'insideDetail',
              page: PageInfo(
                'InsideDetailRoute',
                builder: (_) => const Text('Inside'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('DetailWrapperRoute')));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);

    await router.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });
}
