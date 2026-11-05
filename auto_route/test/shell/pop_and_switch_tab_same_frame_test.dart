import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/194801
// Setup: tabs 0 and 1; tab 0 has its own stack of a home page and a details
// page with an id.
// Steps: push details 1 in tab 0; in the same frame pop it and switch to tab
// 1; switch back to tab 0; push details 2, then pop it.
// Should: tab 0 shows its home page each time; details 1 never comes
// back; each push future completes once, with no "Future already completed".
void main() {
  for (final (how, pop) in [
    (
      'Navigator.pop',
      (WidgetTester tester) =>
          Navigator.of(tester.element(find.text('Details 1'))).pop(),
    ),
    (
      "the tab's router pop()",
      (WidgetTester tester) =>
          tester.element(find.text('Details 1')).router.pop(),
    ),
    (
      'system back',
      (WidgetTester tester) => unawaited(tester.binding.handlePopRoute()),
    ),
  ]) {
    testWidgets(
      'Popping with $how and switching tabs in one frame keeps the page closed',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'ShellRoute',
                builder: (_) => const AutoTabsRouter(
                  routes: [_Route('Tab0'), _Route('Tab1')],
                ),
              ),
              children: [
                AutoRoute(
                  path: 'home',
                  page: const EmptyShellRoute('Tab0'),
                  children: [
                    AutoRoute(
                      path: '',
                      page: _page('HomeRoute', (_) => 'Home'),
                    ),
                    AutoRoute(
                      path: 'details/:id',
                      page: _page(
                        'DetailsRoute',
                        (data) => 'Details ${data.params.getString('id')}',
                      ),
                    ),
                  ],
                ),
                AutoRoute(path: 'other', page: _page('Tab1', (_) => 'Other')),
              ],
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        final tabs = router.innerRouterOf<TabsRouter>('ShellRoute')!;
        final stack = tabs.stackRouterOfIndex(0)!;

        var completions = 0;
        unawaited(stack.pushPath('details/1').then((_) => completions++));
        await tester.pumpAndSettle();
        expect(find.text('Details 1'), findsOneWidget);

        pop(tester);
        tabs.setActiveIndex(1);
        await tester.pumpAndSettle();
        expect(find.text('Other'), findsOneWidget);
        expect(completions, 1);

        tabs.setActiveIndex(0);
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(stack.stack.map((page) => page.name), ['HomeRoute']);

        unawaited(stack.pushPath('details/2').then((_) => completions++));
        await tester.pumpAndSettle();
        expect(find.text('Details 2'), findsOneWidget);
        stack.pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget, reason: 'after stack.pop()');
        expect(find.text('Details 1'), findsNothing);
        expect(completions, 2);
      },
    );
  }
}

PageInfo _page(String name, String Function(RouteData<Object?> data) text) =>
    .new(name, builder: (data) => Scaffold(body: Text(text(data))));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
