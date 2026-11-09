import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../hero_label_page.dart';
import '../router_test_utils.dart';

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}

RootStackRouter _buildRouter() => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('ARoute', builder: (_) => const HeroLabelPage('hero A')),
    ),
    AutoRoute(
      path: '/b',
      page: PageInfo('BRoute', builder: (_) => const HeroLabelPage('hero B')),
    ),
    // As in the reports: a page with no transition either way.
    CustomRoute(
      path: '/c',
      page: PageInfo(
        'CRoute',
        builder: (_) => const Scaffold(body: Text('CRoute')),
      ),
      duration: .zero,
      reverseDuration: .zero,
    ),
  ],
);

void main() {
  // https://github.com/flutter/flutter/issues/121910: a Hero stayed
  // invisible on the first page after the page its flight went to was
  // removed and a page with no reverse transition was popped back to it.
  // Steps: ARoute and BRoute share a Hero. Push BRoute, then
  // pushAndPopUntil(CRoute) down to ARoute, so BRoute is removed. Pop CRoute.
  // Should: ARoute's Hero shows. It does on Flutter 3.47.9: the Hero is
  // hidden for the first frame of the pop, then shown.
  testWidgets(
    'A Hero shows again after popping a page pushed over the removed page it '
    'flew to',
    (tester) async {
      final router = _buildRouter();
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _Route('BRoute')));
      await tester.pumpAndSettle();
      unawaited(
        router.pushAndPopUntil(
          const _Route('CRoute'),
          predicate: (route) => route.settings.name == 'ARoute',
        ),
      );
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), ['ARoute', 'CRoute']);

      router.pop();
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'ARoute');
      expect(
        find.text('hero A'),
        findsOneWidget,
        reason: 'the Hero is not offstage',
      );
    },
  );

  // https://github.com/flutter/flutter/issues/133324: the first page's
  // FloatingActionButton, whose Hero flies to the next page's, stayed hidden
  // after the next page was replaced by a page with no reverse transition and
  // that page was popped.
  // Steps: HomeRoute and SecondRoute each have a FloatingActionButton. Push
  // SecondRoute, replace it with NewRoute, which has none and no reverse
  // transition, then pop NewRoute.
  // Should: HomeRoute's FloatingActionButton shows. It does on Flutter 3.47.9.
  testWidgets(
    'A FloatingActionButton shows again after popping the page that replaced '
    "its Hero's page",
    (tester) async {
      Widget fabPage(String label) => Scaffold(
        body: Text(label),
        floatingActionButton: FloatingActionButton(
          onPressed: null,
          child: Text('$label fab'),
        ),
      );
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => fabPage('HomeRoute')),
          ),
          AutoRoute(
            path: '/second',
            page: PageInfo(
              'SecondRoute',
              builder: (_) => fabPage('SecondRoute'),
            ),
          ),
          CustomRoute(
            path: '/new',
            page: PageInfo(
              'NewRoute',
              builder: (_) => const Scaffold(body: Text('NewRoute')),
            ),
            reverseDuration: .zero,
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _Route('SecondRoute')));
      await tester.pumpAndSettle();
      unawaited(router.replace(const _Route('NewRoute')));
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), ['HomeRoute', 'NewRoute']);

      router.pop();
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');
      expect(
        find.text('HomeRoute fab'),
        findsOneWidget,
        reason: 'the FloatingActionButton is not offstage',
      );
    },
  );
}
