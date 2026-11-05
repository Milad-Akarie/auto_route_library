import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';

// https://github.com/flutter/flutter/issues/155839
// Setup: the first page holds tabs; a second page at the root is a shell
// with its own nested stack.
// Steps: from a tab, push the shell page; then pop from the page inside it.
// Should: back returns to the tabs page, with no exception.
void main() {
  for (final (how, back) in [
    (
      "the inner page's router maybePop()",
      (WidgetTester tester) async {
        await tester.element(find.text('InnerRoute')).router.maybePop();
        await tester.pumpAndSettle();
      },
    ),
    (
      'router.maybePopTop()',
      (WidgetTester tester) async {
        await tester.element(find.text('InnerRoute')).router.root.maybePopTop();
        await tester.pumpAndSettle();
      },
    ),
    ('system back', systemBack),
    ('the iOS edge swipe', swipeBack),
  ]) {
    testWidgets(
      'Popping a shell page pushed from a tab with $how returns to the tabs',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'TabsRoute',
                builder: (_) => const AutoTabsRouter(
                  routes: [_Route('ATab'), _Route('BTab')],
                ),
              ),
              children: [
                AutoRoute(path: 'a', page: _page('ATab')),
                AutoRoute(path: 'b', page: _page('BTab')),
              ],
            ),
            AutoRoute(
              path: '/shell',
              page: const EmptyShellRoute('ShellRoute'),
              children: [AutoRoute(path: '', page: _page('InnerRoute'))],
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp.router(theme: iosTheme, routerConfig: router.config()),
        );
        addTearDown(router.dispose);
        await tester.pumpAndSettle();
        router.innerRouterOf<TabsRouter>('TabsRoute')!.setActiveIndex(1);
        await tester.pumpAndSettle();

        unawaited(
          tester
              .element(find.text('BTab'))
              .router
              .root
              .push(const _Route('ShellRoute')),
        );
        await tester.pumpAndSettle();
        expect(find.text('InnerRoute'), findsOneWidget);

        await back(tester);
        expect(tester.takeException(), isNull);
        expect(router.stack.map((page) => page.name), ['TabsRoute']);
        expect(find.text('BTab'), findsOneWidget);
        expect(router.urlState.url, '/b');
      },
    );
  }
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
