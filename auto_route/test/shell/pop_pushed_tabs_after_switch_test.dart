import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/145401
// Setup: the app's first page pushes a menu page that holds tabs, each tab
// with its own stack.
// Steps: on the menu page, switch to the second tab, then go back: the
// tab page's own router pops, or the user presses system back.
// Should: back leaves the menu page and returns to the first page.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('MainRoute'), path: '/', initial: true),
        AutoRoute(
          page: _menuPage,
          path: '/menu',
          children: [
            for (final tab in ['Tab1', 'Tab2'])
              AutoRoute(
                page: EmptyShellRoute(tab),
                path: tab.toLowerCase(),
                children: [AutoRoute(page: _page('${tab}Route'), path: '')],
              ),
          ],
        ),
      ],
    );
  });

  for (final (how, back) in [
    (
      "the tab page's router maybePop()",
      (WidgetTester tester) async {
        await tester.element(find.text('Tab2Route')).router.maybePop();
        await tester.pumpAndSettle();
      },
    ),
    ('system back', systemBack),
  ]) {
    testWidgets('Back with $how after switching tabs on a pushed tabs page leaves it', (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _Route('MenuRoute')));
      await tester.pumpAndSettle();
      expect(find.text('Tab1Route'), findsOneWidget);

      router.innerRouterOf<TabsRouter>('MenuRoute')!.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('Tab2Route'), findsOneWidget);

      await back(tester);
      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['MainRoute']);
      expect(find.text('MainRoute'), findsOneWidget);
    });
  }
}

final _menuPage = PageInfo('MenuRoute', builder: (_) => const AutoTabsRouter(routes: [_Route('Tab1'), _Route('Tab2')]));

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
