import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/188295
  // In go_router, with a page pushed before a stateful shell, the AppBar of
  // the first branch showed a back button and the second branch's didn't.
  // Steps: Home pushes TabsHost, whose AutoTabsRouter shows SectionA and
  // SectionB, each a Scaffold with an AppBar; switch to SectionB, which has
  // not been shown before, then back to SectionA.
  // Should: both sections show a back button, and it goes back to Home.
  for (final (label, leading) in [('the AppBar default', null), ('AutoLeadingButton', const AutoLeadingButton())]) {
    testWidgets('Every tab of a pushed tabs page shows a back button, with $label (flutter/flutter#188295)', (
      tester,
    ) async {
      PageInfo section(String name) => .new(
        name,
        builder: (_) => Scaffold(
          appBar: AppBar(leading: leading, title: Text(name)),
        ),
      );
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: PageInfo('Home', builder: (_) => const Scaffold(body: Text('Home'))),
            path: '/',
          ),
          AutoRoute(
            page: PageInfo(
              'TabsHost',
              builder: (_) => const AutoTabsRouter(routes: [_Route('SectionA'), _Route('SectionB')]),
            ),
            path: '/tabs',
            children: [
              AutoRoute(page: section('SectionA'), path: 'a'),
              AutoRoute(page: section('SectionB'), path: 'b'),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.push(const _Route('TabsHost')));
      await tester.pumpAndSettle();
      final tabs = router.innerRouterOf<TabsRouter>('TabsHost')!;
      expect(find.byType(BackButton), findsOneWidget);

      tabs.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('SectionB'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      tabs.setActiveIndex(0);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expectTopPage(router, 'Home');
    });
  }
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
